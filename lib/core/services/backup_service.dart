import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_constants.dart';
import '../../data/services/sync_metadata_service.dart';

/// ADDITIVE: Backup and restore app data (Hive box).
class BackupService {
  static Future<String> exportToJson() async {
    final box = Hive.box<String>(AppConstants.hiveBoxName);
    final map = <String, String>{};
    for (final key in box.keys) {
      final v = box.get(key);
      final keyStr = key.toString();
      if (v != null && !SyncMetadataService.isInternalKey(keyStr)) {
        map[keyStr] = v;
      }
    }
    return jsonEncode(map);
  }

  static Future<String?> exportToFileAndShare() async {
    try {
      final json = await exportToJson();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/teacher_planner_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      );
      await file.writeAsString(json);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Teacher Planner Backup');
      return file.path;
    } catch (e) {
      debugPrint('BackupService.exportToFileAndShare: $e');
      return null;
    }
  }

  static Future<bool> importFromJson(String jsonStr) async {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final box = Hive.box<String>(AppConstants.hiveBoxName);
      for (final e in map.entries) {
        await box.put(e.key, e.value.toString());
        await SyncMetadataService.touchKey(e.key);
      }
      return true;
    } catch (e) {
      debugPrint('BackupService.importFromJson: $e');
      return false;
    }
  }
}
