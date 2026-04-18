import 'dart:convert';

class SyncMergeResult {
  const SyncMergeResult({required this.payload, required this.deletedEntities});

  final String? payload;
  final Map<String, DateTime> deletedEntities;
}

class SyncMergeService {
  static SyncMergeResult merge({
    required String? localPayload,
    required String? remotePayload,
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
    Map<String, DateTime> localDeletedEntities = const {},
    Map<String, DateTime> remoteDeletedEntities = const {},
    bool localIsDeleted = false,
    bool remoteIsDeleted = false,
  }) {
    final mergedDeleted = <String, DateTime>{}
      ..addAll(remoteDeletedEntities)
      ..addAll(localDeletedEntities);

    if (localIsDeleted || remoteIsDeleted) {
      if (localUpdatedAt != null &&
          remoteUpdatedAt != null &&
          localUpdatedAt.isAtSameMomentAs(remoteUpdatedAt)) {
        return SyncMergeResult(payload: null, deletedEntities: mergedDeleted);
      }
      final localWins = _isLocalPreferred(localUpdatedAt, remoteUpdatedAt);
      if ((localWins && localIsDeleted) || (!localWins && remoteIsDeleted)) {
        return SyncMergeResult(payload: null, deletedEntities: mergedDeleted);
      }
    }

    if (localPayload == null || localPayload.isEmpty) {
      return SyncMergeResult(
        payload: _applyDeletedEntities(remotePayload, mergedDeleted),
        deletedEntities: mergedDeleted,
      );
    }
    if (remotePayload == null || remotePayload.isEmpty) {
      return SyncMergeResult(
        payload: _applyDeletedEntities(localPayload, mergedDeleted),
        deletedEntities: mergedDeleted,
      );
    }

    final localDecoded = _tryDecode(localPayload);
    final remoteDecoded = _tryDecode(remotePayload);

    if (localDecoded is List && remoteDecoded is List) {
      return SyncMergeResult(
        payload: jsonEncode(
          _mergeLists(
            localDecoded,
            remoteDecoded,
            localUpdatedAt: localUpdatedAt,
            remoteUpdatedAt: remoteUpdatedAt,
            deletedEntities: mergedDeleted,
          ),
        ),
        deletedEntities: mergedDeleted,
      );
    }

    if (localDecoded is Map && remoteDecoded is Map) {
      return SyncMergeResult(
        payload: jsonEncode(
          _mergeMaps(
            Map<String, dynamic>.from(localDecoded),
            Map<String, dynamic>.from(remoteDecoded),
            preferLocal: _isLocalPreferred(localUpdatedAt, remoteUpdatedAt),
          ),
        ),
        deletedEntities: mergedDeleted,
      );
    }

    return SyncMergeResult(
      payload: _isLocalPreferred(localUpdatedAt, remoteUpdatedAt)
          ? localPayload
          : remotePayload,
      deletedEntities: mergedDeleted,
    );
  }

  static dynamic _tryDecode(String payload) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      return payload;
    }
  }

  static bool _isLocalPreferred(DateTime? local, DateTime? remote) {
    if (local == null && remote == null) return true;
    if (local == null) return false;
    if (remote == null) return true;
    return !local.isBefore(remote);
  }

  static dynamic _mergeMaps(
    Map<String, dynamic> local,
    Map<String, dynamic> remote, {
    required bool preferLocal,
  }) {
    final merged = <String, dynamic>{};
    final keys = <String>{...local.keys, ...remote.keys};
    for (final key in keys) {
      final localValue = local[key];
      final remoteValue = remote[key];
      if (localValue is Map && remoteValue is Map) {
        merged[key] = _mergeMaps(
          Map<String, dynamic>.from(localValue),
          Map<String, dynamic>.from(remoteValue),
          preferLocal: preferLocal,
        );
        continue;
      }
      if (localValue == null) {
        merged[key] = remoteValue;
        continue;
      }
      if (remoteValue == null) {
        merged[key] = localValue;
        continue;
      }
      merged[key] = preferLocal ? localValue : remoteValue;
    }
    return merged;
  }

  static List<dynamic> _mergeLists(
    List<dynamic> local,
    List<dynamic> remote, {
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
    required Map<String, DateTime> deletedEntities,
  }) {
    final preferLocal = _isLocalPreferred(localUpdatedAt, remoteUpdatedAt);
    final base = preferLocal ? local : remote;
    final other = preferLocal ? remote : local;
    final merged = <dynamic>[];
    final seen = <String>{};

    void absorbItem(dynamic item, {required bool baseItem}) {
      final identity = _itemIdentity(item);
      if (identity == null) {
        if (baseItem || !merged.contains(item)) {
          merged.add(item);
        }
        return;
      }
      if (seen.contains(identity)) return;

      final otherItem = other.cast<dynamic>().firstWhere(
        (candidate) => _itemIdentity(candidate) == identity,
        orElse: () => null,
      );
      final chosen = _pickItem(
        localItem: preferLocal ? item : otherItem,
        remoteItem: preferLocal ? otherItem : item,
        localUpdatedAt: localUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      );

      final deletedAt = deletedEntities[identity];
      if (deletedAt != null) {
        final itemUpdatedAt =
            _itemTimestamp(chosen) ??
            (preferLocal ? localUpdatedAt : remoteUpdatedAt);
        if (itemUpdatedAt == null || !itemUpdatedAt.isAfter(deletedAt)) {
          seen.add(identity);
          return;
        }
      }

      seen.add(identity);
      merged.add(chosen);
    }

    for (final item in base) {
      absorbItem(item, baseItem: true);
    }
    for (final item in other) {
      absorbItem(item, baseItem: false);
    }
    return merged;
  }

  static dynamic _pickItem({
    required dynamic localItem,
    required dynamic remoteItem,
    required DateTime? localUpdatedAt,
    required DateTime? remoteUpdatedAt,
  }) {
    if (localItem == null) return remoteItem;
    if (remoteItem == null) return localItem;

    final localItemAt = _itemTimestamp(localItem) ?? localUpdatedAt;
    final remoteItemAt = _itemTimestamp(remoteItem) ?? remoteUpdatedAt;
    return _isLocalPreferred(localItemAt, remoteItemAt)
        ? localItem
        : remoteItem;
  }

  static DateTime? _itemTimestamp(dynamic item) {
    if (item is! Map) return null;
    final updatedAt = DateTime.tryParse(item['updatedAt']?.toString() ?? '');
    if (updatedAt != null) return updatedAt.toUtc();
    final createdAt = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    if (createdAt != null) return createdAt.toUtc();
    final date = DateTime.tryParse(item['date']?.toString() ?? '');
    return date?.toUtc();
  }

  static String? _itemIdentity(dynamic item) {
    if (item is! Map) return null;
    final id = item['id']?.toString();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final studentId = item['studentId']?.toString();
    final classId = item['classId']?.toString();
    final date = item['date']?.toString();
    if (_allPresent([studentId, classId, date])) {
      return '${studentId}_${classId}_$date';
    }
    final courseId = item['courseId']?.toString();
    if (_allPresent([courseId, date])) {
      return '${courseId}_$date';
    }
    return null;
  }

  static bool _allPresent(List<String?> values) =>
      values.every((value) => value != null && value.isNotEmpty);

  static String? _applyDeletedEntities(
    String? payload,
    Map<String, DateTime> deletedEntities,
  ) {
    if (payload == null || payload.isEmpty || deletedEntities.isEmpty) {
      return payload;
    }
    final decoded = _tryDecode(payload);
    if (decoded is! List) return payload;
    final filtered = decoded.where((item) {
      final identity = _itemIdentity(item);
      if (identity == null) return true;
      final deletedAt = deletedEntities[identity];
      if (deletedAt == null) return true;
      final itemUpdatedAt = _itemTimestamp(item);
      return itemUpdatedAt != null && itemUpdatedAt.isAfter(deletedAt);
    }).toList();
    return jsonEncode(filtered);
  }
}
