/// App-wide constants
class AppConstants {
  static const String hiveBoxName = 'teacher_planner';
  static const String setupCompleteKey = 'setup_complete';
  static const String localeKey = 'locale';
  static const String themeModeKey = 'theme_mode';
  static const String teacherProfileKey = 'teacher_profile';
  static const String guidanceStudentsKey = 'guidance_students';
  static const String studentsKey = 'students';
  static const String remindersKey = 'reminders';
  static const String assessmentsKey = 'assessments';
  static const String attendanceKey = 'attendance';
  static const String lessonsKey = 'lessons';
  static const String coursesKey = 'courses';
  static const String weeklyScheduleKey = 'weekly_schedule';
  static const String annualPlanKey = 'annual_plan';
  static const String annualPlanMetadataKey = 'annual_plan_metadata';
  static const String dailyLessonPlansKey = 'daily_lesson_plans';
  static const String lessonDocumentsKey = 'lesson_documents';
  static const String studentProblemsKey = 'student_problems';
  static const String guidanceActivitiesKey = 'guidance_activities';
  static const String guidanceMeetingsKey = 'guidance_meetings';
  static const String projectsKey = 'projects';
  static const String zumreDefinitionsKey = 'zumre_definitions';
  static const String zumreMeetingsKey = 'zumre_meetings';
  static const String zumreTasksKey = 'zumre_tasks';
  static const String zumreContributionsKey = 'zumre_contributions';
  static const String zumreDecisionsKey = 'zumre_decisions';
  static const String zumreNotesKey = 'zumre_notes';

  // ADDITIVE CHANGE: Keys for new features (thelastupdates.md)
  static const String lastSelectedCourseIdKey = 'last_selected_course_id';
  static const String lastOpenedDocumentKey = 'last_opened_document';
  static const String dailyTasksKey = 'daily_tasks';
  static const String homeSectionsCollapsedKey = 'home_sections_collapsed';
  static const String dailyLessonNotesKey = 'daily_lesson_notes';
  static const String courseMetadataKey = 'course_metadata';
  static const String teachProgressKey = 'teach_progress';
  static const String teachTopicNotesKey = 'teach_topic_notes';
  static const String weeklyScheduleWeekPrefix = 'weekly_schedule_week_';
  static const String dailyReflectionPrefix = 'daily_reflection_';
  /// extra.md: Ders Anlat – online ders oturum notları (courseId_date -> JSON)
  static const String teachOnlineSessionNotesKey = 'teach_online_session_notes';
  /// extra.md: Rehberlik – öğrenci gelişim notları (pozitif, problem değil)
  static const String guidanceDevelopmentNotesKey = 'guidance_development_notes';

  /// extra.md: Menü/Modül ve senkronizasyon ayarları
  static const String settingsOnlineLessonFeaturesKey = 'settings_online_lesson_features';
  static const String settingsSyncWifiOnlyKey = 'settings_sync_wifi_only';

  /// extra.md: Yeni modüllerin aç/kapa durumu (varsayılan hep kapalı).
  static const String moduleFlagsKey = 'module_flags';
  static const List<String> moduleIds = [
    'student_portfolio',
    'parent_summary',
    'private_lesson',
    'content_creator',
    'teacher_insights',
    'group_connections',
    'online_lesson_tracking',
  ];

  static const List<int> grades = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  static const List<String> branches = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

  /// Tüm sınıflar (1A, 1B, ..., 12I)
  static List<String> get allClasses {
    final list = <String>[];
    for (final g in grades) {
      for (final b in branches) {
        list.add('$g$b');
      }
    }
    return list;
  }
  static const List<String> documentFormats = ['PDF', 'Word', 'Excel', 'PPT', 'Audio', 'Video', 'Link'];

  static const List<String> weekDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  /// Ders saatleri (1. Ders - 7. Ders): (başlangıç saat, bitiş saat)
  static const List<({int startH, int startM, int endH, int endM})> lessonTimes = [
    (startH: 8, startM: 30, endH: 9, endM: 15),   // 1. Ders
    (startH: 9, startM: 25, endH: 10, endM: 10),  // 2. Ders
    (startH: 10, startM: 25, endH: 11, endM: 10), // 3. Ders
    (startH: 11, startM: 20, endH: 12, endM: 5),  // 4. Ders
    (startH: 12, startM: 30, endH: 13, endM: 15), // 5. Ders
    (startH: 13, startM: 40, endH: 14, endM: 25), // 6. Ders
    (startH: 14, startM: 30, endH: 15, endM: 15), // 7. Ders
  ];

  static const int lessonCount = 7;

  /// Şu anki saate göre hangi dersin sırası geldiğini döndürür (1-indexed). 0 = ders yok.
  static int getCurrentLessonIndex() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    for (int i = 0; i < lessonTimes.length; i++) {
      final t = lessonTimes[i];
      final start = t.startH * 60 + t.startM;
      final end = t.endH * 60 + t.endM;
      if (currentMinutes >= start && currentMinutes <= end) return i + 1;
    }
    return 0;
  }

  /// Ders saati formatı: "8:30 - 9:15"
  static String formatLessonTime(int hourIndex) {
    if (hourIndex < 0 || hourIndex >= lessonTimes.length) return '';
    final t = lessonTimes[hourIndex];
    return '${t.startH.toString().padLeft(2, '0')}:${t.startM.toString().padLeft(2, '0')} - '
        '${t.endH.toString().padLeft(2, '0')}:${t.endM.toString().padLeft(2, '0')}';
  }

  static const String fallbackLocale = 'en';
}
