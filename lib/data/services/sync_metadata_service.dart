import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';

class SyncDocumentState {
  const SyncDocumentState({
    required this.docKey,
    this.updatedAt,
    this.lastSyncedAt,
    this.dirty = false,
    this.isDeleted = false,
    this.deletedEntities = const {},
  });

  final String docKey;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  final bool dirty;
  final bool isDeleted;
  final Map<String, DateTime> deletedEntities;

  Map<String, dynamic> toJson() => {
    'docKey': docKey,
    'updatedAt': updatedAt?.toIso8601String(),
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'dirty': dirty,
    'isDeleted': isDeleted,
    'deletedEntities': deletedEntities.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    ),
  };

  factory SyncDocumentState.fromJson(Map<String, dynamic> json) {
    final deletedRaw = json['deletedEntities'];
    final deleted = <String, DateTime>{};
    if (deletedRaw is Map) {
      for (final entry in deletedRaw.entries) {
        final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
        if (parsed != null) {
          deleted[entry.key.toString()] = parsed.toUtc();
        }
      }
    }
    return SyncDocumentState(
      docKey: json['docKey'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc(),
      lastSyncedAt: DateTime.tryParse(
        json['lastSyncedAt'] as String? ?? '',
      )?.toUtc(),
      dirty: json['dirty'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedEntities: deleted,
    );
  }

  SyncDocumentState copyWith({
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    bool? dirty,
    bool? isDeleted,
    Map<String, DateTime>? deletedEntities,
  }) {
    return SyncDocumentState(
      docKey: docKey,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      dirty: dirty ?? this.dirty,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedEntities: deletedEntities ?? this.deletedEntities,
    );
  }
}

class SyncMetadataService {
  static const String _metaPrefix = '__sync_meta__';
  static const String _deviceIdKey = '__sync_device_id__';
  static const String _lastSyncAtKey = '__sync_last_sync_at__';
  static Box<String> get _box => Hive.box<String>(AppConstants.hiveBoxName);

  static bool isInternalKey(String key) =>
      key.startsWith(_metaPrefix) ||
      key == _deviceIdKey ||
      key == _lastSyncAtKey;

  static bool isSyncableKey(String key) {
    if (isInternalKey(key)) return false;
    const nonSyncable = <String>{
      AppConstants.lastSelectedCourseIdKey,
      AppConstants.lastOpenedDocumentKey,
      AppConstants.homeSectionsCollapsedKey,
      AppConstants.settingsSyncWifiOnlyKey,
    };
    return !nonSyncable.contains(key);
  }

  static String metaKey(String docKey) => '$_metaPrefix$docKey';

  static Iterable<String> listMetadataKeys() =>
      _box.keys.whereType<String>().where((key) => key.startsWith(_metaPrefix));

  static Iterable<String> listTrackedDocumentKeys() {
    final keys = <String>{};
    for (final key in _box.keys.whereType<String>()) {
      if (isSyncableKey(key)) {
        keys.add(key);
      }
    }
    for (final key in listMetadataKeys()) {
      keys.add(key.substring(_metaPrefix.length));
    }
    return keys;
  }

  static SyncDocumentState getState(String docKey) {
    final raw = _box.get(metaKey(docKey));
    if (raw == null || raw.isEmpty) {
      return SyncDocumentState(docKey: docKey);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SyncDocumentState.fromJson(decoded);
      }
      if (decoded is Map) {
        return SyncDocumentState.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {}
    return SyncDocumentState(docKey: docKey);
  }

  static Future<void> _saveState(SyncDocumentState state) async {
    await _box.put(metaKey(state.docKey), jsonEncode(state.toJson()));
  }

  static Future<String> ensureDeviceId() async {
    final existing = _box.get(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = const Uuid().v4();
    await _box.put(_deviceIdKey, generated);
    return generated;
  }

  static DateTime? getLastSyncAt() {
    final raw = _box.get(_lastSyncAtKey);
    return DateTime.tryParse(raw ?? '')?.toUtc();
  }

  static Future<void> setLastSyncAt(DateTime dateTime) async {
    await _box.put(_lastSyncAtKey, dateTime.toUtc().toIso8601String());
  }

  static Future<void> touchKey(String docKey, {DateTime? at}) async {
    if (!isSyncableKey(docKey)) return;
    final now = (at ?? DateTime.now()).toUtc();
    final state = getState(docKey);
    await _saveState(
      state.copyWith(updatedAt: now, dirty: true, isDeleted: false),
    );
  }

  static Future<void> markKeyDeleted(String docKey, {DateTime? at}) async {
    if (!isSyncableKey(docKey)) return;
    final now = (at ?? DateTime.now()).toUtc();
    final state = getState(docKey);
    await _saveState(
      state.copyWith(updatedAt: now, dirty: true, isDeleted: true),
    );
  }

  static Future<void> markEntityDeleted(
    String docKey,
    String entityId, {
    DateTime? at,
  }) async {
    if (!isSyncableKey(docKey) || entityId.isEmpty) return;
    final now = (at ?? DateTime.now()).toUtc();
    final state = getState(docKey);
    final deletedEntities = Map<String, DateTime>.from(state.deletedEntities)
      ..[entityId] = now;
    await _saveState(
      state.copyWith(
        updatedAt: now,
        dirty: true,
        isDeleted: false,
        deletedEntities: deletedEntities,
      ),
    );
  }

  static Future<void> markSynced(
    String docKey, {
    required DateTime syncedAt,
    DateTime? updatedAt,
    Map<String, DateTime>? deletedEntities,
    bool isDeleted = false,
  }) async {
    if (!isSyncableKey(docKey)) return;
    final state = getState(docKey);
    await _saveState(
      state.copyWith(
        updatedAt: updatedAt?.toUtc() ?? state.updatedAt,
        lastSyncedAt: syncedAt.toUtc(),
        dirty: false,
        isDeleted: isDeleted,
        deletedEntities: deletedEntities ?? state.deletedEntities,
      ),
    );
  }

  static Future<void> primeExistingDataForFirstSync() async {
    for (final key in _box.keys.whereType<String>()) {
      if (!isSyncableKey(key)) continue;
      final state = getState(key);
      if (state.updatedAt == null && !state.dirty) {
        await touchKey(key);
      }
    }
  }

  static Future<void> pruneOldDeletedEntities({
    Duration maxAge = const Duration(days: 90),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(maxAge);
    for (final key in listMetadataKeys()) {
      final docKey = key.substring(_metaPrefix.length);
      final state = getState(docKey);
      final filtered = <String, DateTime>{};
      for (final entry in state.deletedEntities.entries) {
        if (entry.value.isAfter(cutoff)) {
          filtered[entry.key] = entry.value;
        }
      }
      if (filtered.length != state.deletedEntities.length) {
        await _saveState(state.copyWith(deletedEntities: filtered));
      }
    }
  }
}
