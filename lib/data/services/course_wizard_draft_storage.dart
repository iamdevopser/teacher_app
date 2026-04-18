import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/course.dart';

/// Yerel dosya — ağ veya harici servis yok.
class CourseWizardDraftStorage {
  CourseWizardDraftStorage._();

  static const int _version = 1;

  static Future<File> _file(String draftKey) async {
    final dir = await getApplicationSupportDirectory();
    final safe = draftKey.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('${dir.path}/course_wizard_draft_$safe.json');
  }

  static Future<void> save({
    required String draftKey,
    required bool isEditing,
    required int step,
    required Course course,
  }) async {
    final payload = <String, dynamic>{
      'version': _version,
      'isEditing': isEditing,
      'courseId': course.id,
      'step': step,
      'course': course.toJson(),
    };
    try {
      final f = await _file(draftKey);
      await f.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Taslak kaydı başarısız — sessiz; form çalışmaya devam eder
    }
  }

  static Future<CourseWizardDraftSnapshot?> load(String draftKey) async {
    try {
      final f = await _file(draftKey);
      if (!await f.exists()) return null;
      final text = await f.readAsString();
      if (text.isEmpty) return null;
      final data = jsonDecode(text) as Map<String, dynamic>;
      if ((data['version'] as int?) != _version) return null;
      final isEditing = data['isEditing'] as bool? ?? false;
      final step = (data['step'] as num?)?.toInt() ?? 0;
      final courseMap = data['course'] as Map<String, dynamic>?;
      if (courseMap == null) return null;
      final course = Course.fromJson(courseMap);
      return CourseWizardDraftSnapshot(
        isEditing: isEditing,
        step: step.clamp(0, 2),
        course: course,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear(String draftKey) async {
    try {
      final f = await _file(draftKey);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

class CourseWizardDraftSnapshot {
  const CourseWizardDraftSnapshot({
    required this.isEditing,
    required this.step,
    required this.course,
  });

  final bool isEditing;
  final int step;
  final Course course;
}
