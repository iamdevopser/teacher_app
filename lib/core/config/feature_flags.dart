/// Feature flags for additive, optional enhancements.
/// All new features are OFF by default; enable in settings if needed.
/// ADDITIVE: Does not affect existing behavior when disabled.
class FeatureFlags {
  // Home Screen
  static const bool homeDailySummary = true;
  static const bool homeQuickActions = true;
  static const bool homeRecentItems = true;
  static const bool homeDailyTasks = true;
  static const bool homeDailyLessonNotes = true;
  static const bool homeCollapsibleSections = true;

  // Courses
  static const bool courseSearchFilter = true;
  static const bool courseColorIcon = true;
  static const bool courseArchive = true;
  static const bool courseDuplication = true;
  static const bool courseSharing = true;

  // Teach
  static const bool teachPersistLastCourse = true;
  static const bool teachProgressTracking = true;
  static const bool teachTopicNotes = true;
  static const bool teachPdfBookmarks = true;
  static const bool teachAutoSaveDrawings = true;
  static const bool teachEndOfLessonLog = true;

  // Lesson Planner - Weekly
  static const bool weeklyCopyWeek = true;
  static const bool weeklyConflictDetection = true;
  static const bool weeklyColorLabels = true;
  static const bool weeklyPrintablePdf = true;

  // Lesson Planner - Yearly
  static const bool yearlyDragDrop = true;
  static const bool yearlyStatusTracking = true;
  static const bool yearlySummaryExport = true;

  // Lesson Planner - Daily
  static const bool dailyAutoImport = true;
  static const bool dailyCompletionStatus = true;
  static const bool dailyReflectionNote = true;
  static const bool dailyTemplates = true;

  // Documents
  static const bool documentsFolders = true;
  static const bool documentsTagging = true;
  static const bool documentsOfflineCache = true;
  static const bool documentsLinkToLessons = true;

  // Projects
  static const bool projectsTimelineView = true;
  static const bool projectsStatusTracking = true;
  static const bool projectsFeedbackNotes = true;
  static const bool projectsReportExport = true;

  // Class Hour - Students
  static const bool studentsProfilePhotos = true;
  static const bool studentsSearch = true;
  static const bool studentsStatusLabels = true;
  static const bool studentsAggregatedStats = true;

  // Class Hour - Problems
  static const bool problemsSeverityLevels = true;
  static const bool problemsResolutionStatus = true;
  static const bool problemsDateFilter = true;
  static const bool problemsParentMeetingLink = true;

  // Class Hour - Activity Notes
  static const bool activityMeetingType = true;
  static const bool activityOutcomeField = true;
  static const bool activityReminderScheduling = true;
  static const bool activityExportablePdf = true;

  // Committee (Zümre)
  static const bool zumreCalendarIntegration = true;
  static const bool zumreDecisionTaskLink = true;
  static const bool zumreAutoReports = true;
  static const bool zumreDocumentArchive = true;
  static const bool zumreAnnualSummary = true;

  // Reports
  static const bool reportsProgressCharts = true;
  static const bool reportsDateRangeFilter = true;
  static const bool reportsWordExport = true;
  static const bool reportsTeacherComment = true;
  static const bool reportsAutoMetadata = true;

  // Reminders
  static const bool remindersRecurring = true;
  static const bool remindersPriority = true;
  static const bool remindersCustomSound = true;
  static const bool remindersLinkToEntity = true;

  // Settings
  /// extra.md: Yeni modüller (student_portfolio, parent_summary, ...) Ayarlar > Modüller üzerinden açılır/kapatılır; ModuleFlagsNotifier kullanın.
  static const bool settingsBackupRestore = true;
  static const bool settingsDefaultTemplates = true;
  static const bool settingsNotificationPrefs = true;
  static const bool settingsDataReset = true;
  static const bool settingsVersionInfo = true;
}
