import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import 'sync_metadata_service.dart';

/// ADDITIVE: Backup and restore app data (Hive box contents).
class BackupService {
  /// Export all Hive data to a JSON string.
  static Future<String> exportToJson() async {
    final box = Hive.box<String>(AppConstants.hiveBoxName);
    final map = <String, String>{};
    for (final key in box.keys) {
      final val = box.get(key);
      final keyStr = key.toString();
      if (val != null && !SyncMetadataService.isInternalKey(keyStr)) {
        map[keyStr] = val;
      }
    }
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': map,
    });
  }

  /// Import from JSON string. Returns true if successful.
  static Future<bool> importFromJson(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      final box = Hive.box<String>(AppConstants.hiveBoxName);
      for (final e in data.entries) {
        final v = e.value;
        if (v is String) {
          await box.put(e.key, v);
          await SyncMetadataService.touchKey(e.key);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear all app data (for data reset).
  static Future<void> clearAllData() async {
    final box = Hive.box<String>(AppConstants.hiveBoxName);
    await box.clear();
  }
}
