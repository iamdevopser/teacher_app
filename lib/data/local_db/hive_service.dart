import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

/// Hive veritabanı başlatma
class HiveService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    String joinPath(String a, String b) {
      final sep = Platform.pathSeparator;
      if (a.endsWith(sep)) return '$a$b';
      return '$a$sep$b';
    }

    Future<void> ensureDir(Directory dir) async {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    // Windows'ta "Documents" yolu çoğu zaman OneDrive altına yönlenir ve
    // dosya kilidi (lock) sorunları daha sık görülür. Bu yüzden Hive'ı
    // Application Support (AppData) altına taşıyoruz.
    final supportDir = await getApplicationSupportDirectory();
    final hiveDir = Directory(joinPath(supportDir.path, 'teacher_planner'));
    await ensureDir(hiveDir);

    // Tek seferlik hafif migrasyon:
    // Eski konum (Documents) altında veri varsa ve yeni konum boşsa, kopyala.
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final oldHiveFile = File(joinPath(docsDir.path, '${AppConstants.hiveBoxName}.hive'));
      final newHiveFile = File(joinPath(hiveDir.path, '${AppConstants.hiveBoxName}.hive'));
      if (await oldHiveFile.exists() && !await newHiveFile.exists()) {
        await oldHiveFile.copy(newHiveFile.path);
      }
    } catch (_) {
      // Migrasyon başarısız olsa da uygulama yeni dizinde çalışmaya devam eder.
    }

    Hive.init(hiveDir.path);

    // Lock hataları bazen kısa süreli olur (eski süreç kapanırken).
    // Birkaç kez yeniden dene.
    const attempts = 3;
    for (var i = 0; i < attempts; i++) {
      try {
        await Hive.openBox<String>(AppConstants.hiveBoxName);
        _initialized = true;
        return;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isLock =
            msg.contains('lock failed') ||
            msg.contains('used by another process') ||
            msg.contains('errno = 33') ||
            msg.contains('errno=33');
        if (isLock && i < attempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          continue;
        }
        rethrow;
      }
    }
  }
}
