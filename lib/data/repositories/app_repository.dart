import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../models/teacher_profile.dart';
import '../models/student.dart';
import '../models/guidance_student.dart';
import '../models/reminder.dart';
import '../models/assessment.dart';
import '../models/attendance_record.dart';
import '../models/lesson.dart';
import '../models/course.dart';
import '../models/course_models.dart';
import '../models/lesson_planner_models.dart';
import '../models/guidance_models.dart';
import '../models/project_model.dart';
import '../models/zumre_models.dart';
import '../services/sync_metadata_service.dart';

class AppRepository {
  static const _uuid = Uuid();

  static String generateId() => _uuid.v4();

  Box<String> get _box => Hive.box<String>(AppConstants.hiveBoxName);

  // Teacher profile
  TeacherProfile? getTeacherProfile() {
    final json = _box.get(AppConstants.teacherProfileKey);
    if (json == null) return null;
    return TeacherProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveTeacherProfile(TeacherProfile p) async {
    await _putString(AppConstants.teacherProfileKey, jsonEncode(p.toJson()));
  }

  // Students
  List<Student> getStudentsByClass(String classId) {
    final list = _getList<Student>(
      AppConstants.studentsKey,
      (j) => Student.fromJson(j as Map<String, dynamic>),
    );
    return list.where((s) => s.classId == classId).toList();
  }

  Future<void> addStudent(Student s) async {
    final list = _getList<Student>(
      AppConstants.studentsKey,
      (j) => Student.fromJson(j as Map<String, dynamic>),
    );
    list.add(s);
    await _saveList(AppConstants.studentsKey, list, (e) => e.toJson());
  }

  // Guidance students
  List<GuidanceStudent> getGuidanceStudents() {
    return _getList<GuidanceStudent>(
      AppConstants.guidanceStudentsKey,
      (j) => GuidanceStudent.fromJson(j as Map<String, dynamic>),
    );
  }

  /// Tüm öğrenciler: Rehberlik sınıfı + ders verilen sınıflar (proje katılımcısı seçimi için)
  List<({String id, String name, String classId})>
  getAllStudentsForProjectSelection() {
    final seen = <String>{};
    final result = <({String id, String name, String classId})>[];
    for (final s in getGuidanceStudents()) {
      final key = '${s.fullName}|${s.classId}';
      if (!seen.contains(key)) {
        seen.add(key);
        result.add((id: s.id, name: s.fullName, classId: s.classId));
      }
    }
    final profile = getTeacherProfile();
    for (final classId in profile?.classesTaught ?? []) {
      for (final s in getStudentsByClass(classId)) {
        final key = '${s.name}|${s.classId}';
        if (!seen.contains(key)) {
          seen.add(key);
          result.add((id: s.id, name: s.name, classId: s.classId));
        }
      }
    }
    result.sort((a, b) {
      final c = a.classId.compareTo(b.classId);
      return c != 0 ? c : a.name.compareTo(b.name);
    });
    return result;
  }

  Future<void> addGuidanceStudent(GuidanceStudent s) async {
    final list = _getList<GuidanceStudent>(
      AppConstants.guidanceStudentsKey,
      (j) => GuidanceStudent.fromJson(j as Map<String, dynamic>),
    );
    list.add(s);
    await _saveList(AppConstants.guidanceStudentsKey, list, (e) => e.toJson());
  }

  Future<void> addGuidanceStudents(List<GuidanceStudent> students) async {
    final list = _getList<GuidanceStudent>(
      AppConstants.guidanceStudentsKey,
      (j) => GuidanceStudent.fromJson(j as Map<String, dynamic>),
    );
    list.addAll(students);
    await _saveList(AppConstants.guidanceStudentsKey, list, (e) => e.toJson());
  }

  Future<void> updateGuidanceStudent(GuidanceStudent s) async {
    final list = _getList<GuidanceStudent>(
      AppConstants.guidanceStudentsKey,
      (j) => GuidanceStudent.fromJson(j as Map<String, dynamic>),
    );
    final i = list.indexWhere((e) => e.id == s.id);
    if (i >= 0) {
      list[i] = s;
      await _saveList(
        AppConstants.guidanceStudentsKey,
        list,
        (e) => e.toJson(),
      );
    }
  }

  Future<void> deleteGuidanceStudent(String id) async {
    final list = _getList<GuidanceStudent>(
      AppConstants.guidanceStudentsKey,
      (j) => GuidanceStudent.fromJson(j as Map<String, dynamic>),
    );
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.guidanceStudentsKey,
      id,
    );
    await _saveList(AppConstants.guidanceStudentsKey, list, (e) => e.toJson());
  }

  // Reminders
  List<Reminder> getReminders() => _getList<Reminder>(
    AppConstants.remindersKey,
    (j) => Reminder.fromJson(j as Map<String, dynamic>),
  );

  List<Reminder> getUpcomingReminders({int limit = 10}) {
    final now = DateTime.now();
    final list = getReminders().where((r) => r.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list.take(limit).toList();
  }

  Future<void> addReminder(Reminder r) async {
    final list = getReminders();
    list.add(r);
    await _saveList(AppConstants.remindersKey, list, (e) => e.toJson());
  }

  Future<void> updateReminder(Reminder r) async {
    final list = getReminders();
    final i = list.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      list[i] = r;
      await _saveList(AppConstants.remindersKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteReminder(String id) async {
    final list = getReminders();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.remindersKey, id);
    await _saveList(AppConstants.remindersKey, list, (e) => e.toJson());
  }

  // Assessments
  List<Assessment> getAssessmentsByClass(String classId) {
    final list = _getList<Assessment>(
      AppConstants.assessmentsKey,
      (j) => Assessment.fromJson(j as Map<String, dynamic>),
    );
    return list.where((a) => a.classId == classId).toList();
  }

  Future<void> addAssessment(Assessment a) async {
    final list = _getList<Assessment>(
      AppConstants.assessmentsKey,
      (j) => Assessment.fromJson(j as Map<String, dynamic>),
    );
    list.add(a);
    await _saveList(AppConstants.assessmentsKey, list, (e) => e.toJson());
  }

  // Attendance
  List<AttendanceRecord> getAttendanceByStudentId(String studentId) {
    final list = _getList<AttendanceRecord>(
      AppConstants.attendanceKey,
      (j) => AttendanceRecord.fromJson(j as Map<String, dynamic>),
    );
    return list.where((r) => r.studentId == studentId).toList();
  }

  List<AttendanceRecord> getAttendanceByDateAndClass(
    DateTime date,
    String classId,
  ) {
    final list = _getList<AttendanceRecord>(
      AppConstants.attendanceKey,
      (j) => AttendanceRecord.fromJson(j as Map<String, dynamic>),
    );
    return list
        .where(
          (r) =>
              r.classId == classId &&
              r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day,
        )
        .toList();
  }

  Future<void> saveAttendance(AttendanceRecord r) async {
    final list = _getList<AttendanceRecord>(
      AppConstants.attendanceKey,
      (j) => AttendanceRecord.fromJson(j as Map<String, dynamic>),
    );
    final i = list.indexWhere(
      (e) =>
          e.studentId == r.studentId &&
          e.classId == r.classId &&
          e.date.year == r.date.year &&
          e.date.month == r.date.month &&
          e.date.day == r.date.day,
    );
    if (i >= 0) {
      list[i] = r;
    } else {
      list.add(r);
    }
    await _saveList(AppConstants.attendanceKey, list, (e) => e.toJson());
  }

  // Courses
  List<Course> getCourses() => _getList<Course>(
    AppConstants.coursesKey,
    (j) => Course.fromJson(j as Map<String, dynamic>),
  );

  List<Course> getCoursesByClass(String classId) =>
      getCourses().where((c) => c.classId == classId).toList();

  Future<void> addCourse(Course c) async {
    final list = getCourses();
    list.add(c);
    await _saveList(AppConstants.coursesKey, list, (e) => e.toJson());
  }

  Future<void> updateCourse(Course c) async {
    final list = getCourses();
    final i = list.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      list[i] = c;
      await _saveList(AppConstants.coursesKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteCourse(String id) async {
    final list = getCourses();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.coursesKey, id);
    await _saveList(AppConstants.coursesKey, list, (e) => e.toJson());
  }

  // ADDITIVE: Course metadata (color, icon) - stored separately
  Map<String, Map<String, dynamic>> getCourseMetadata() {
    final json = _box.get(AppConstants.courseMetadataKey);
    if (json == null) return {};
    final decoded = jsonDecode(json);
    if (decoded is! Map) return {};
    return decoded.map(
      (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
    );
  }

  Future<void> setCourseMetadata(
    String courseId,
    Map<String, dynamic> meta,
  ) async {
    final map = getCourseMetadata();
    map[courseId] = meta;
    await _putString(AppConstants.courseMetadataKey, jsonEncode(map));
  }

  // ADDITIVE: Duplicate course (template-based)
  Future<Course> duplicateCourse(
    Course source, {
    String nameSuffix = ' (Copy)',
  }) async {
    final newId = generateId();
    final now = DateTime.now();
    final copy = source.copyWith(
      id: newId,
      name: '${source.displayName}$nameSuffix',
      status: CourseStatus.draft,
      createdAt: now,
      updatedAt: now,
    );
    await addCourse(copy);
    return copy;
  }

  // Lessons
  List<Lesson> getLessonsByDate(DateTime date) {
    final list = _getList<Lesson>(
      AppConstants.lessonsKey,
      (j) => Lesson.fromJson(j as Map<String, dynamic>),
    );
    return list
        .where(
          (l) =>
              l.date.year == date.year &&
              l.date.month == date.month &&
              l.date.day == date.day,
        )
        .toList();
  }

  Future<void> addLesson(Lesson l) async {
    final list = _getList<Lesson>(
      AppConstants.lessonsKey,
      (j) => Lesson.fromJson(j as Map<String, dynamic>),
    );
    list.add(l);
    await _saveList(AppConstants.lessonsKey, list, (e) => e.toJson());
  }

  // Weekly schedule (8x8: 7 days + header, 8 hours)
  Map<String, String> getWeeklySchedule() {
    final json = _box.get(AppConstants.weeklyScheduleKey);
    if (json == null) return {};
    final decoded = jsonDecode(json);
    if (decoded is! Map) return {};
    return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Future<void> saveWeeklyScheduleCell(
    int day,
    int hour,
    String? classId,
  ) async {
    final map = getWeeklySchedule();
    final key = '${day}_$hour';
    if (classId == null || classId.isEmpty) {
      map.remove(key);
    } else {
      map[key] = classId;
    }
    await _putString(AppConstants.weeklyScheduleKey, jsonEncode(map));
  }

  /// ADDITIVE: Week-specific schedule key (year_weekNo).
  static String _weekScheduleKey(DateTime weekStart) {
    final jan1 = DateTime(weekStart.year, 1, 1);
    final days = weekStart.difference(jan1).inDays;
    final weekNo = (days / 7).floor() + 1;
    return '${AppConstants.weeklyScheduleWeekPrefix}${weekStart.year}_$weekNo';
  }

  /// ADDITIVE: Get schedule for a specific week (or default if none).
  Map<String, String> getWeeklyScheduleForWeek(DateTime weekStart) {
    final key = _weekScheduleKey(weekStart);
    final json = _box.get(key);
    if (json != null) {
      final decoded = jsonDecode(json);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    }
    return getWeeklySchedule();
  }

  /// ADDITIVE: Save schedule for a specific week.
  Future<void> saveWeeklyScheduleForWeek(
    DateTime weekStart,
    Map<String, String> map,
  ) async {
    await _putString(_weekScheduleKey(weekStart), jsonEncode(map));
  }

  /// ADDITIVE: Copy schedule from one week to another.
  Future<void> copyWeeklySchedule(
    DateTime fromWeekStart,
    DateTime toWeekStart,
  ) async {
    final map = getWeeklyScheduleForWeek(fromWeekStart);
    await saveWeeklyScheduleForWeek(toWeekStart, Map.from(map));
  }

  /// ADDITIVE: Save one cell for a specific week.
  Future<void> saveWeeklyScheduleCellForWeek(
    int day,
    int hour,
    String? classId,
    DateTime weekStart,
  ) async {
    final map = getWeeklyScheduleForWeek(weekStart);
    final key = '${day}_$hour';
    if (classId == null || classId.isEmpty) {
      map.remove(key);
    } else {
      map[key] = classId;
    }
    await saveWeeklyScheduleForWeek(weekStart, map);
  }

  /// Bugünün haftalık programını döndürür (gün isimleri anlık tarihle eşleşir).
  /// dayIndex: 0=Pzt, 1=Sal, ..., 6=Paz (DateTime.weekday: 1=Pzt, 7=Paz)
  List<({int hour, String classId})> getTodaysScheduleFromWeekly() {
    final schedule = getWeeklySchedule();
    final now = DateTime.now();
    final dayIndex = now.weekday - 1; // 1=Pzt -> 0, 2=Sal -> 1, ...
    final result = <({int hour, String classId})>[];
    for (int h = 0; h < AppConstants.lessonCount; h++) {
      final key = '${dayIndex}_$h';
      final raw = schedule[key];
      if (raw != null && raw.isNotEmpty) {
        final classId = raw.contains('|online')
            ? raw.replaceAll('|online', '')
            : raw;
        if (classId.isNotEmpty) {
          result.add((hour: h + 1, classId: classId));
        }
      }
    }
    return result;
  }

  // Annual plan
  List<AnnualPlanRow> getAnnualPlan() => _getList<AnnualPlanRow>(
    AppConstants.annualPlanKey,
    (j) => AnnualPlanRow.fromJson(j as Map<String, dynamic>),
  );

  AnnualPlanMetadata getAnnualPlanMetadata() {
    final json = _box.get(AppConstants.annualPlanMetadataKey);
    if (json == null) return const AnnualPlanMetadata();
    try {
      return AnnualPlanMetadata.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return const AnnualPlanMetadata();
    }
  }

  Future<void> saveAnnualPlanMetadata(AnnualPlanMetadata m) async {
    await _putString(
      AppConstants.annualPlanMetadataKey,
      jsonEncode(m.toJson()),
    );
  }

  Future<void> addAnnualPlanRow(AnnualPlanRow r) async {
    final list = getAnnualPlan();
    list.add(r);
    await _saveList(AppConstants.annualPlanKey, list, (e) => e.toJson());
  }

  Future<void> updateAnnualPlanRow(AnnualPlanRow r) async {
    final list = getAnnualPlan();
    final i = list.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      list[i] = r;
      await _saveList(AppConstants.annualPlanKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteAnnualPlanRow(String id) async {
    final list = getAnnualPlan();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.annualPlanKey, id);
    await _saveList(AppConstants.annualPlanKey, list, (e) => e.toJson());
  }

  // Daily lesson plans
  List<DailyLessonPlan> getDailyLessonPlans() => _getList<DailyLessonPlan>(
    AppConstants.dailyLessonPlansKey,
    (j) => DailyLessonPlan.fromJson(j as Map<String, dynamic>),
  );

  List<DailyLessonPlan> getDailyLessonPlansByDate(DateTime date) =>
      getDailyLessonPlans()
          .where(
            (p) =>
                p.date.year == date.year &&
                p.date.month == date.month &&
                p.date.day == date.day,
          )
          .toList();

  Future<void> addDailyLessonPlan(DailyLessonPlan p) async {
    final list = getDailyLessonPlans();
    list.add(p);
    await _saveList(AppConstants.dailyLessonPlansKey, list, (e) => e.toJson());
  }

  Future<void> updateDailyLessonPlan(DailyLessonPlan p) async {
    final list = getDailyLessonPlans();
    final i = list.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      // Plan bulunamadıysa (örn. veri kaybı) yeni ekle
      list.add(p);
    }
    await _saveList(AppConstants.dailyLessonPlansKey, list, (e) => e.toJson());
  }

  Future<void> deleteDailyLessonPlan(String id) async {
    final list = getDailyLessonPlans();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.dailyLessonPlansKey,
      id,
    );
    await _saveList(AppConstants.dailyLessonPlansKey, list, (e) => e.toJson());
  }

  /// ADDITIVE: Daily reflection note (per date).
  static String _dailyReflectionKey(DateTime date) =>
      '${AppConstants.dailyReflectionPrefix}${date.year}_${date.month}_${date.day}';

  String getDailyReflection(DateTime date) {
    return _box.get(_dailyReflectionKey(date)) ?? '';
  }

  Future<void> setDailyReflection(DateTime date, String text) async {
    await _putString(_dailyReflectionKey(date), text);
  }

  // Lesson documents
  List<LessonDocument> getLessonDocuments() => _getList<LessonDocument>(
    AppConstants.lessonDocumentsKey,
    (j) => LessonDocument.fromJson(j as Map<String, dynamic>),
  );

  List<LessonDocument> getLessonDocumentsByClass(String classId) =>
      getLessonDocuments().where((d) => d.classId == classId).toList();

  Future<void> addLessonDocument(LessonDocument d) async {
    final list = getLessonDocuments();
    list.add(d);
    await _saveList(AppConstants.lessonDocumentsKey, list, (e) => e.toJson());
  }

  Future<void> deleteLessonDocument(String id) async {
    final list = getLessonDocuments();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.lessonDocumentsKey,
      id,
    );
    await _saveList(AppConstants.lessonDocumentsKey, list, (e) => e.toJson());
  }

  // Student problems (Öğrenci Problemleri)
  List<StudentProblem> getStudentProblems() => _getList<StudentProblem>(
    AppConstants.studentProblemsKey,
    (j) => StudentProblem.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addStudentProblem(StudentProblem p) async {
    final list = getStudentProblems();
    list.add(p);
    await _saveList(AppConstants.studentProblemsKey, list, (e) => e.toJson());
  }

  Future<void> updateStudentProblem(StudentProblem p) async {
    final list = getStudentProblems();
    final i = list.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      list[i] = p;
      await _saveList(AppConstants.studentProblemsKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteStudentProblem(String id) async {
    final list = getStudentProblems();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.studentProblemsKey,
      id,
    );
    await _saveList(AppConstants.studentProblemsKey, list, (e) => e.toJson());
  }

  // Guidance activities (Rehberlik aktiviteleri)
  List<GuidanceActivity> getGuidanceActivities() => _getList<GuidanceActivity>(
    AppConstants.guidanceActivitiesKey,
    (j) => GuidanceActivity.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addGuidanceActivity(GuidanceActivity a) async {
    final list = getGuidanceActivities();
    list.add(a);
    await _saveList(
      AppConstants.guidanceActivitiesKey,
      list,
      (e) => e.toJson(),
    );
  }

  Future<void> updateGuidanceActivity(GuidanceActivity a) async {
    final list = getGuidanceActivities();
    final i = list.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      list[i] = a;
      await _saveList(
        AppConstants.guidanceActivitiesKey,
        list,
        (e) => e.toJson(),
      );
    }
  }

  Future<void> deleteGuidanceActivity(String id) async {
    final list = getGuidanceActivities();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.guidanceActivitiesKey,
      id,
    );
    await _saveList(
      AppConstants.guidanceActivitiesKey,
      list,
      (e) => e.toJson(),
    );
  }

  // Guidance meetings (Rehberlik görüşmeleri)
  List<GuidanceMeeting> getGuidanceMeetings() => _getList<GuidanceMeeting>(
    AppConstants.guidanceMeetingsKey,
    (j) => GuidanceMeeting.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addGuidanceMeeting(GuidanceMeeting m) async {
    final list = getGuidanceMeetings();
    list.add(m);
    await _saveList(AppConstants.guidanceMeetingsKey, list, (e) => e.toJson());
  }

  Future<void> updateGuidanceMeeting(GuidanceMeeting m) async {
    final list = getGuidanceMeetings();
    final i = list.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      list[i] = m;
      await _saveList(
        AppConstants.guidanceMeetingsKey,
        list,
        (e) => e.toJson(),
      );
    }
  }

  Future<void> deleteGuidanceMeeting(String id) async {
    final list = getGuidanceMeetings();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.guidanceMeetingsKey,
      id,
    );
    await _saveList(AppConstants.guidanceMeetingsKey, list, (e) => e.toJson());
  }

  /// extra.md: Öğrenci gelişim notları (akademik, sosyal/duygusal, öz değerlendirme)
  List<Map<String, dynamic>> getGuidanceDevelopmentNotes() {
    final json = _box.get(AppConstants.guidanceDevelopmentNotesKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>?;
      return list?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> addGuidanceDevelopmentNote(Map<String, dynamic> note) async {
    final list = getGuidanceDevelopmentNotes();
    list.add(note);
    await _putString(
      AppConstants.guidanceDevelopmentNotesKey,
      jsonEncode(list),
    );
  }

  Future<void> updateGuidanceDevelopmentNote(
    String id,
    Map<String, dynamic> updated,
  ) async {
    final list = getGuidanceDevelopmentNotes();
    final i = list.indexWhere((e) => e['id'] == id);
    if (i >= 0) {
      list[i] = updated;
      await _putString(
        AppConstants.guidanceDevelopmentNotesKey,
        jsonEncode(list),
      );
    }
  }

  Future<void> deleteGuidanceDevelopmentNote(String id) async {
    final list = getGuidanceDevelopmentNotes();
    list.removeWhere((e) => e['id'] == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.guidanceDevelopmentNotesKey,
      id,
    );
    await _putString(
      AppConstants.guidanceDevelopmentNotesKey,
      jsonEncode(list),
    );
  }

  // Projects (Projeler)
  List<ProjectModel> getProjects() => _getList<ProjectModel>(
    AppConstants.projectsKey,
    (j) => ProjectModel.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addProject(ProjectModel p) async {
    final list = getProjects();
    list.add(p);
    await _saveList(AppConstants.projectsKey, list, (e) => e.toJson());
  }

  Future<void> updateProject(ProjectModel p) async {
    final list = getProjects();
    final i = list.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      list[i] = p;
      await _saveList(AppConstants.projectsKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteProject(String id) async {
    final list = getProjects();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.projectsKey, id);
    await _saveList(AppConstants.projectsKey, list, (e) => e.toJson());
  }

  // Zümre Çalışmalarım
  List<ZumreDefinition> getZumreDefinitions() => _getList<ZumreDefinition>(
    AppConstants.zumreDefinitionsKey,
    (j) => ZumreDefinition.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addZumreDefinition(ZumreDefinition z) async {
    final list = getZumreDefinitions();
    list.add(z);
    await _saveList(AppConstants.zumreDefinitionsKey, list, (e) => e.toJson());
  }

  Future<void> updateZumreDefinition(ZumreDefinition z) async {
    final list = getZumreDefinitions();
    final i = list.indexWhere((e) => e.id == z.id);
    if (i >= 0) {
      list[i] = z;
      await _saveList(
        AppConstants.zumreDefinitionsKey,
        list,
        (e) => e.toJson(),
      );
    }
  }

  Future<void> deleteZumreDefinition(String id) async {
    final list = getZumreDefinitions();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.zumreDefinitionsKey,
      id,
    );
    await _saveList(AppConstants.zumreDefinitionsKey, list, (e) => e.toJson());
  }

  List<ZumreMeeting> getZumreMeetings() => _getList<ZumreMeeting>(
    AppConstants.zumreMeetingsKey,
    (j) => ZumreMeeting.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addZumreMeeting(ZumreMeeting m) async {
    final list = getZumreMeetings();
    list.add(m);
    await _saveList(AppConstants.zumreMeetingsKey, list, (e) => e.toJson());
  }

  Future<void> updateZumreMeeting(ZumreMeeting m) async {
    final list = getZumreMeetings();
    final i = list.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      list[i] = m;
      await _saveList(AppConstants.zumreMeetingsKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteZumreMeeting(String id) async {
    final list = getZumreMeetings();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.zumreMeetingsKey,
      id,
    );
    await _saveList(AppConstants.zumreMeetingsKey, list, (e) => e.toJson());
  }

  List<ZumreTask> getZumreTasks() => _getList<ZumreTask>(
    AppConstants.zumreTasksKey,
    (j) => ZumreTask.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addZumreTask(ZumreTask t) async {
    final list = getZumreTasks();
    list.add(t);
    await _saveList(AppConstants.zumreTasksKey, list, (e) => e.toJson());
  }

  Future<void> updateZumreTask(ZumreTask t) async {
    final list = getZumreTasks();
    final i = list.indexWhere((e) => e.id == t.id);
    if (i >= 0) {
      list[i] = t;
      await _saveList(AppConstants.zumreTasksKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteZumreTask(String id) async {
    final list = getZumreTasks();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.zumreTasksKey, id);
    await _saveList(AppConstants.zumreTasksKey, list, (e) => e.toJson());
  }

  List<ZumreContribution> getZumreContributions() =>
      _getList<ZumreContribution>(
        AppConstants.zumreContributionsKey,
        (j) => ZumreContribution.fromJson(j as Map<String, dynamic>),
      );

  Future<void> addZumreContribution(ZumreContribution c) async {
    final list = getZumreContributions();
    list.add(c);
    await _saveList(
      AppConstants.zumreContributionsKey,
      list,
      (e) => e.toJson(),
    );
  }

  Future<void> updateZumreContribution(ZumreContribution c) async {
    final list = getZumreContributions();
    final i = list.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      list[i] = c;
      await _saveList(
        AppConstants.zumreContributionsKey,
        list,
        (e) => e.toJson(),
      );
    }
  }

  Future<void> deleteZumreContribution(String id) async {
    final list = getZumreContributions();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.zumreContributionsKey,
      id,
    );
    await _saveList(
      AppConstants.zumreContributionsKey,
      list,
      (e) => e.toJson(),
    );
  }

  List<ZumreDecision> getZumreDecisions() => _getList<ZumreDecision>(
    AppConstants.zumreDecisionsKey,
    (j) => ZumreDecision.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addZumreDecision(ZumreDecision d) async {
    final list = getZumreDecisions();
    list.add(d);
    await _saveList(AppConstants.zumreDecisionsKey, list, (e) => e.toJson());
  }

  Future<void> updateZumreDecision(ZumreDecision d) async {
    final list = getZumreDecisions();
    final i = list.indexWhere((e) => e.id == d.id);
    if (i >= 0) {
      list[i] = d;
      await _saveList(AppConstants.zumreDecisionsKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteZumreDecision(String id) async {
    final list = getZumreDecisions();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.zumreDecisionsKey,
      id,
    );
    await _saveList(AppConstants.zumreDecisionsKey, list, (e) => e.toJson());
  }

  List<ZumreNote> getZumreNotes() => _getList<ZumreNote>(
    AppConstants.zumreNotesKey,
    (j) => ZumreNote.fromJson(j as Map<String, dynamic>),
  );

  Future<void> addZumreNote(ZumreNote n) async {
    final list = getZumreNotes();
    list.add(n);
    await _saveList(AppConstants.zumreNotesKey, list, (e) => e.toJson());
  }

  Future<void> updateZumreNote(ZumreNote n) async {
    final list = getZumreNotes();
    final i = list.indexWhere((e) => e.id == n.id);
    if (i >= 0) {
      list[i] = n;
      await _saveList(AppConstants.zumreNotesKey, list, (e) => e.toJson());
    }
  }

  Future<void> deleteZumreNote(String id) async {
    final list = getZumreNotes();
    list.removeWhere((e) => e.id == id);
    await SyncMetadataService.markEntityDeleted(AppConstants.zumreNotesKey, id);
    await _saveList(AppConstants.zumreNotesKey, list, (e) => e.toJson());
  }

  List<T> _getList<T>(String key, T Function(dynamic) fromJson) {
    final json = _box.get(key);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded.map((e) => fromJson(e)).toList();
  }

  Future<void> _saveList<T>(
    String key,
    List<T> list,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await _putString(key, jsonEncode(list.map((e) => toJson(e)).toList()));
  }

  // ADDITIVE CHANGE: Preferences for new features (thelastupdates.md)
  String? getLastSelectedCourseId() =>
      _box.get(AppConstants.lastSelectedCourseIdKey);
  Future<void> setLastSelectedCourseId(String? id) async {
    if (id == null) {
      await _deleteString(AppConstants.lastSelectedCourseIdKey);
    } else {
      await _putString(AppConstants.lastSelectedCourseIdKey, id);
    }
  }

  String? getLastOpenedDocument() =>
      _box.get(AppConstants.lastOpenedDocumentKey);
  Future<void> setLastOpenedDocument(String? path) async {
    if (path == null) {
      await _deleteString(AppConstants.lastOpenedDocumentKey);
    } else {
      await _putString(AppConstants.lastOpenedDocumentKey, path);
    }
  }

  List<Map<String, dynamic>> getDailyTasks() {
    final json = _box.get(AppConstants.dailyTasksKey);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> saveDailyTasks(List<Map<String, dynamic>> tasks) async {
    await _putString(AppConstants.dailyTasksKey, jsonEncode(tasks));
  }

  /// Gün içi ders notları: id, text, date (YYYY-MM-DD), createdAt (iso), classId?, subject?
  List<Map<String, dynamic>> getDailyLessonNotes() {
    final json = _box.get(AppConstants.dailyLessonNotesKey);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    if (decoded is! List) return [];
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> getDailyLessonNotesByDate(DateTime date) {
    final dayStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return getDailyLessonNotes()
        .where((n) => (n['date'] as String? ?? '').startsWith(dayStr))
        .toList();
  }

  Future<void> saveDailyLessonNotes(List<Map<String, dynamic>> notes) async {
    await _putString(AppConstants.dailyLessonNotesKey, jsonEncode(notes));
  }

  Future<void> addDailyLessonNote(Map<String, dynamic> note) async {
    final list = getDailyLessonNotes();
    list.add(note);
    await saveDailyLessonNotes(list);
  }

  Future<void> updateDailyLessonNote(
    String id,
    Map<String, dynamic> updated,
  ) async {
    final list = getDailyLessonNotes();
    final i = list.indexWhere((n) => (n['id'] as String? ?? '') == id);
    if (i >= 0) {
      list[i] = updated;
      await saveDailyLessonNotes(list);
    }
  }

  Future<void> deleteDailyLessonNote(String id) async {
    final list = getDailyLessonNotes();
    list.removeWhere((n) => (n['id'] as String? ?? '') == id);
    await SyncMetadataService.markEntityDeleted(
      AppConstants.dailyLessonNotesKey,
      id,
    );
    await saveDailyLessonNotes(list);
  }

  Set<String> getHomeSectionsCollapsed() {
    final json = _box.get(AppConstants.homeSectionsCollapsedKey);
    if (json == null) return {};
    final decoded = jsonDecode(json);
    if (decoded is! List) return {};
    return decoded.map((e) => e.toString()).toSet();
  }

  Future<void> setHomeSectionCollapsed(String sectionId, bool collapsed) async {
    final set = getHomeSectionsCollapsed();
    if (collapsed) {
      set.add(sectionId);
    } else {
      set.remove(sectionId);
    }
    await _putString(
      AppConstants.homeSectionsCollapsedKey,
      jsonEncode(set.toList()),
    );
  }

  // ADDITIVE: Teach progress (courseId -> unitId_topicId -> 0-100)
  Map<String, Map<String, int>> getTeachProgress() {
    final json = _box.get(AppConstants.teachProgressKey);
    if (json == null) return {};
    final decoded = jsonDecode(json);
    if (decoded is! Map) return {};
    final result = <String, Map<String, int>>{};
    for (final e in decoded.entries) {
      final inner = e.value;
      if (inner is Map) {
        result[e.key.toString()] = inner.map(
          (k, v) => MapEntry(k.toString(), (v is int) ? v : 0),
        );
      }
    }
    return result;
  }

  Future<void> setTeachProgress(
    String courseId,
    String unitTopicKey,
    int percent,
  ) async {
    final map = getTeachProgress();
    map.putIfAbsent(courseId, () => {})[unitTopicKey] = percent.clamp(0, 100);
    await _putString(AppConstants.teachProgressKey, jsonEncode(map));
  }

  // ADDITIVE: Teach topic notes (courseId -> unitId_topicId -> note)
  Map<String, Map<String, String>> getTeachTopicNotes() {
    final json = _box.get(AppConstants.teachTopicNotesKey);
    if (json == null) return {};
    final decoded = jsonDecode(json);
    if (decoded is! Map) return {};
    final result = <String, Map<String, String>>{};
    for (final e in decoded.entries) {
      final inner = e.value;
      if (inner is Map) {
        result[e.key.toString()] = inner.map(
          (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
        );
      }
    }
    return result;
  }

  Future<void> setTeachTopicNote(
    String courseId,
    String unitTopicKey,
    String note,
  ) async {
    final map = getTeachTopicNotes();
    map.putIfAbsent(courseId, () => {})[unitTopicKey] = note;
    await _putString(AppConstants.teachTopicNotesKey, jsonEncode(map));
  }

  /// extra.md: Online ders oturum notu (courseId + date)
  static String _teachOnlineNoteKey(String courseId, DateTime date) {
    final d = date.toIso8601String();
    final day = d.length >= 10 ? d.substring(0, 10) : d;
    return '${AppConstants.teachOnlineSessionNotesKey}_${courseId}_$day';
  }

  Map<String, String> getTeachOnlineSessionNote(
    String courseId,
    DateTime date,
  ) {
    final json = _box.get(AppRepository._teachOnlineNoteKey(courseId, date));
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>?;
      if (decoded == null) return {};
      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  Future<void> setTeachOnlineSessionNote(
    String courseId,
    DateTime date,
    Map<String, String> data,
  ) async {
    await _putString(
      AppRepository._teachOnlineNoteKey(courseId, date),
      jsonEncode(data),
    );
  }

  /// extra.md: Raporlar – tüm online ders oturum notlarını listele (Online Katılım Özeti için)
  List<Map<String, dynamic>> getAllTeachOnlineSessionNotes() {
    const prefix = '${AppConstants.teachOnlineSessionNotesKey}_';
    final result = <Map<String, dynamic>>[];
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final rest = key.substring(prefix.length);
      final lastUnderscore = rest.lastIndexOf('_');
      if (lastUnderscore <= 0) continue;
      final courseId = rest.substring(0, lastUnderscore);
      final dateStr = rest.substring(lastUnderscore + 1);
      final json = _box.get(key);
      if (json == null) continue;
      try {
        final decoded = jsonDecode(json) as Map<String, dynamic>?;
        if (decoded != null) {
          result.add({'courseId': courseId, 'date': dateStr, ...decoded});
        }
      } catch (_) {}
    }
    result.sort(
      (a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''),
    );
    return result;
  }

  /// extra.md: Online ders özellikleri açık (varsayılan true)
  bool getSettingsOnlineLessonFeatures() =>
      _box.get(AppConstants.settingsOnlineLessonFeaturesKey) != 'false';

  Future<void> setSettingsOnlineLessonFeatures(bool value) async {
    await _putString(
      AppConstants.settingsOnlineLessonFeaturesKey,
      value ? 'true' : 'false',
    );
  }

  /// extra.md: Sadece Wi-Fi ile senkronize et (varsayılan false)
  bool getSettingsSyncWifiOnly() =>
      _box.get(AppConstants.settingsSyncWifiOnlyKey) == 'true';

  Future<void> setSettingsSyncWifiOnly(bool value) async {
    await _putString(
      AppConstants.settingsSyncWifiOnlyKey,
      value ? 'true' : 'false',
    );
  }

  Future<void> _putString(String key, String value) async {
    await _box.put(key, value);
    await SyncMetadataService.touchKey(key);
  }

  Future<void> _deleteString(String key) async {
    await _box.delete(key);
    await SyncMetadataService.markKeyDeleted(key);
  }
}
