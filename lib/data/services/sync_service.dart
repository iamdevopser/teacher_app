import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import 'sync_merge_service.dart';
import 'sync_metadata_service.dart';

class SyncSummary {
  const SyncSummary({this.uploaded = 0, this.downloaded = 0, this.merged = 0});

  final int uploaded;
  final int downloaded;
  final int merged;
}

class RemoteSyncDocument {
  const RemoteSyncDocument({
    required this.docKey,
    required this.updatedAt,
    required this.deletedEntities,
    this.payload,
    this.isDeleted = false,
  });

  final String docKey;
  final String? payload;
  final DateTime updatedAt;
  final bool isDeleted;
  final Map<String, DateTime> deletedEntities;

  factory RemoteSyncDocument.fromJson(Map<String, dynamic> json) {
    final deletedRaw = json['deleted_entities'];
    final deletedEntities = <String, DateTime>{};
    if (deletedRaw is Map) {
      for (final entry in deletedRaw.entries) {
        final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
        if (parsed != null) {
          deletedEntities[entry.key.toString()] = parsed.toUtc();
        }
      }
    }
    return RemoteSyncDocument(
      docKey: json['doc_key'] as String? ?? '',
      payload: json['payload'] as String?,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      isDeleted: json['is_deleted'] == true,
      deletedEntities: deletedEntities,
    );
  }
}

class SyncService {
  static const String tableName = 'app_sync_documents';

  Box<String> get _box => Hive.box<String>(AppConstants.hiveBoxName);
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<SyncSummary> synchronize() async {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('No authenticated sync user found.');
    }

    await SyncMetadataService.primeExistingDataForFirstSync();
    await SyncMetadataService.pruneOldDeletedEntities();

    final deviceId = await SyncMetadataService.ensureDeviceId();
    final remoteDocs = await _fetchRemoteDocuments();
    final trackedKeys = <String>{
      ...SyncMetadataService.listTrackedDocumentKeys(),
      ...remoteDocs.keys,
    };

    var uploaded = 0;
    var downloaded = 0;
    var merged = 0;

    for (final docKey in trackedKeys) {
      if (!SyncMetadataService.isSyncableKey(docKey)) continue;
      final state = SyncMetadataService.getState(docKey);
      final remote = remoteDocs[docKey];
      final localPayload = _box.get(docKey);

      if (remote == null) {
        if (localPayload == null && !state.isDeleted) {
          continue;
        }
        await _upsertRemoteDocument(
          docKey: docKey,
          payload: localPayload,
          updatedAt: state.updatedAt ?? DateTime.now().toUtc(),
          isDeleted: state.isDeleted,
          deletedEntities: state.deletedEntities,
          deviceId: deviceId,
        );
        await SyncMetadataService.markSynced(
          docKey,
          syncedAt: DateTime.now().toUtc(),
          updatedAt: state.updatedAt ?? DateTime.now().toUtc(),
          deletedEntities: state.deletedEntities,
          isDeleted: state.isDeleted,
        );
        uploaded++;
        continue;
      }

      if (!state.dirty &&
          localPayload == remote.payload &&
          state.isDeleted == remote.isDeleted) {
        await SyncMetadataService.markSynced(
          docKey,
          syncedAt: DateTime.now().toUtc(),
          updatedAt: remote.updatedAt,
          deletedEntities: remote.deletedEntities,
          isDeleted: remote.isDeleted,
        );
        continue;
      }

      final merge = SyncMergeService.merge(
        localPayload: localPayload,
        remotePayload: remote.payload,
        localUpdatedAt: state.updatedAt,
        remoteUpdatedAt: remote.updatedAt,
        localDeletedEntities: state.deletedEntities,
        remoteDeletedEntities: remote.deletedEntities,
        localIsDeleted: state.isDeleted,
        remoteIsDeleted: remote.isDeleted,
      );

      final mergedPayload = merge.payload;
      final mergedUpdatedAt =
          _latest(state.updatedAt, remote.updatedAt) ?? DateTime.now().toUtc();
      final mergedIsDeleted = mergedPayload == null;

      final localChanged =
          localPayload != mergedPayload || state.isDeleted != mergedIsDeleted;
      final remoteChanged =
          remote.payload != mergedPayload ||
          remote.isDeleted != mergedIsDeleted ||
          !_sameDeletedEntities(remote.deletedEntities, merge.deletedEntities);

      if (localChanged) {
        if (mergedIsDeleted) {
          await _box.delete(docKey);
        } else {
          await _box.put(docKey, mergedPayload);
        }
        downloaded++;
      }

      if (remoteChanged || state.dirty) {
        await _upsertRemoteDocument(
          docKey: docKey,
          payload: mergedPayload,
          updatedAt: mergedUpdatedAt,
          isDeleted: mergedIsDeleted,
          deletedEntities: merge.deletedEntities,
          deviceId: deviceId,
        );
        uploaded++;
      }

      if (localChanged && remoteChanged) {
        merged++;
      }

      await SyncMetadataService.markSynced(
        docKey,
        syncedAt: DateTime.now().toUtc(),
        updatedAt: mergedUpdatedAt,
        deletedEntities: merge.deletedEntities,
        isDeleted: mergedIsDeleted,
      );
    }

    await SyncMetadataService.setLastSyncAt(DateTime.now().toUtc());
    return SyncSummary(
      uploaded: uploaded,
      downloaded: downloaded,
      merged: merged,
    );
  }

  Future<Map<String, RemoteSyncDocument>> _fetchRemoteDocuments() async {
    final response = await _client
        .from(tableName)
        .select('doc_key,payload,updated_at,is_deleted,deleted_entities');

    final docs = <String, RemoteSyncDocument>{};
    for (final row in response) {
      final map = Map<String, dynamic>.from(row as Map);
      final doc = RemoteSyncDocument.fromJson(map);
      docs[doc.docKey] = doc;
    }
    return docs;
  }

  Future<void> _upsertRemoteDocument({
    required String docKey,
    required String? payload,
    required DateTime updatedAt,
    required bool isDeleted,
    required Map<String, DateTime> deletedEntities,
    required String deviceId,
  }) {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('No authenticated sync user found.');
    }
    return _client.from(tableName).upsert({
      'user_id': user.id,
      'doc_key': docKey,
      'payload': payload,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_entities': deletedEntities.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'device_id': deviceId,
    }, onConflict: 'user_id,doc_key');
  }

  bool _sameDeletedEntities(Map<String, DateTime> a, Map<String, DateTime> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key]?.toUtc() != entry.value.toUtc()) {
        return false;
      }
    }
    return true;
  }

  DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b?.toUtc();
    if (b == null) return a.toUtc();
    return a.isAfter(b) ? a.toUtc() : b.toUtc();
  }
}
