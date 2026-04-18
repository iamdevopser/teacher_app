import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../data/services/sync_metadata_service.dart';

/// extra.md: Modül aç/kapa durumu. Tüm modüller varsayılan kapalı.
/// Ayarlar > Modüller ekranı bu notifier ile günceller.
class ModuleFlagsNotifier extends ChangeNotifier {
  Map<String, bool> _flags = {};

  void load() {
    try {
      final box = Hive.box<String>(AppConstants.hiveBoxName);
      final json = box.get(AppConstants.moduleFlagsKey);
      if (json != null && json.isNotEmpty) {
        final decoded = jsonDecode(json) as Map<String, dynamic>?;
        if (decoded != null) {
          _flags = decoded.map((k, v) => MapEntry(k, v == true));
        }
      }
    } catch (_) {
      _flags = {};
    }
    for (final id in AppConstants.moduleIds) {
      _flags.putIfAbsent(id, () => false);
    }
    notifyListeners();
  }

  bool isEnabled(String moduleId) => _flags[moduleId] ?? false;

  Future<void> setEnabled(String moduleId, bool value) async {
    if (!AppConstants.moduleIds.contains(moduleId)) return;
    _flags[moduleId] = value;
    try {
      final box = Hive.box<String>(AppConstants.hiveBoxName);
      await box.put(AppConstants.moduleFlagsKey, jsonEncode(_flags));
      await SyncMetadataService.touchKey(AppConstants.moduleFlagsKey);
    } catch (_) {}
    notifyListeners();
  }

  List<String> get moduleIds => List.from(AppConstants.moduleIds);
}
