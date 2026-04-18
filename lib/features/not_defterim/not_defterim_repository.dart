import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

import 'not_defterim_models.dart';

/// Tüm Not Defterim verisi [AppConstants.hiveBoxName] (ör. `teacher_planner`) kutusunda tutulur.
/// [getDailyEntries] / [upsertDailyEntry] → `nd_daily_entries` anahtarı (JSON).
class NotDefterimRepository {
  NotDefterimRepository();

  Box<String> get _box => Hive.box<String>(AppConstants.hiveBoxName);

  // Hive keys (single box, JSON payload)
  String get _classesKey => 'nd_classes';
  String get _studentsKey => 'nd_students';
  String get _pointTypesKey => 'nd_point_types';
  String get _dailyEntriesKey => 'nd_daily_entries';

  List<NotDefterimClass> getClasses() {
    final raw = _box.get(_classesKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map((e) => NotDefterimClass.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveClasses(List<NotDefterimClass> items) async {
    await _box.put(_classesKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  List<NotDefterimStudent> getStudents() {
    final raw = _box.get(_studentsKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map((e) => NotDefterimStudent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveStudents(List<NotDefterimStudent> items) async {
    await _box.put(_studentsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  List<NotDefterimPointType> getPointTypes() {
    final raw = _box.get(_pointTypesKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map((e) => NotDefterimPointType.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> savePointTypes(List<NotDefterimPointType> items) async {
    await _box.put(_pointTypesKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  List<NotDefterimDailyEntry> getDailyEntries() {
    final raw = _box.get(_dailyEntriesKey);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map((e) => NotDefterimDailyEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveDailyEntries(List<NotDefterimDailyEntry> items) async {
    await _box.put(_dailyEntriesKey, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  List<NotDefterimStudent> getStudentsByClass(String classId) {
    return getStudents().where((s) => s.classId == classId).toList();
  }

  NotDefterimDailyEntry? getDailyEntry({
    required String classId,
    required String dateStr,
    required String studentId,
  }) {
    final items = getDailyEntries();
    for (final e in items) {
      if (e.classId == classId && e.dateStr == dateStr && e.studentId == studentId) {
        return e;
      }
    }
    return null;
  }

  Future<void> upsertDailyEntry({
    required String classId,
    required String dateStr,
    required String studentId,
    required Map<String, double> newValues,
  }) async {
    // getDailyEntries() bosken `const []` donebilir; add/[]= icin mutasyon yapilir kopya gerekir.
    final items = List<NotDefterimDailyEntry>.from(getDailyEntries());
    final idx = items.indexWhere(
      (e) => e.classId == classId && e.dateStr == dateStr && e.studentId == studentId,
    );
    if (idx >= 0) {
      final current = items[idx];
      final merged = Map<String, double>.from(current.values);
      // Upsert behaviour: merge/replace point types
      for (final entry in newValues.entries) {
        merged[entry.key] = entry.value;
      }
      items[idx] = NotDefterimDailyEntry(
        id: current.id,
        classId: current.classId,
        dateStr: current.dateStr,
        studentId: current.studentId,
        values: merged,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    } else {
      items.add(
        NotDefterimDailyEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          classId: classId,
          dateStr: dateStr,
          studentId: studentId,
          values: Map<String, double>.from(newValues),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    await saveDailyEntries(items);
  }

  Future<void> deleteDailyEntry({
    required String classId,
    required String dateStr,
    required String studentId,
  }) async {
    final items = List<NotDefterimDailyEntry>.from(getDailyEntries());
    items.removeWhere((e) => e.classId == classId && e.dateStr == dateStr && e.studentId == studentId);
    await saveDailyEntries(items);
  }
}

