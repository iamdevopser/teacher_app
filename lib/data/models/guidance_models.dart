import '../../core/localization/app_translations.dart';

/// Öğrenci problemi türü
enum StudentProblemType {
  attendance,   // Devamsızlık
  failure,     // Ders başarısızlığı
  discipline,  // Disiplin sorunu
  other,
}

/// Öğrenci problemi kaydı
class StudentProblem {
  final String id;
  final String studentId;
  final String studentName;
  final StudentProblemType type;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  /// ADDITIVE: low, medium, high
  final String? severity;
  /// ADDITIVE: open, in_progress, resolved
  final String? resolutionStatus;
  /// ADDITIVE: linked meeting id for parent meeting
  final String? parentMeetingId;

  const StudentProblem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    this.description = '',
    required this.date,
    required this.createdAt,
    this.severity,
    this.resolutionStatus,
    this.parentMeetingId,
  });

  /// Localized type label - pass localeCode from LocaleProvider.effectiveLocale.languageCode
  String typeLabel(String localeCode) {
    final key = 'problemType${type.name[0].toUpperCase()}${type.name.substring(1)}';
    return AppTranslations.tr(localeCode, key);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'type': type.name,
    'description': description,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    if (severity != null) 'severity': severity,
    if (resolutionStatus != null) 'resolutionStatus': resolutionStatus,
    if (parentMeetingId != null) 'parentMeetingId': parentMeetingId,
  };

  factory StudentProblem.fromJson(Map<String, dynamic> json) => StudentProblem(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String? ?? '',
    type: StudentProblemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => StudentProblemType.other,
    ),
    description: json['description'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    severity: json['severity'] as String?,
    resolutionStatus: json['resolutionStatus'] as String?,
    parentMeetingId: json['parentMeetingId'] as String?,
  );
}

/// Rehberlik aktivitesi
class GuidanceActivity {
  final String id;
  final String activityName;
  final List<String> participantIds;
  final int participantCount;
  final String evaluationNote;
  final DateTime date;
  final DateTime createdAt;
  final bool isInSchool;

  const GuidanceActivity({
    required this.id,
    required this.activityName,
    required this.participantIds,
    required this.participantCount,
    this.evaluationNote = '',
    required this.date,
    required this.createdAt,
    this.isInSchool = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityName': activityName,
    'participantIds': participantIds,
    'participantCount': participantCount,
    'evaluationNote': evaluationNote,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isInSchool': isInSchool,
  };

  factory GuidanceActivity.fromJson(Map<String, dynamic> json) => GuidanceActivity(
    id: json['id'] as String,
    activityName: json['activityName'] as String? ?? '',
    participantIds: (json['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    evaluationNote: json['evaluationNote'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isInSchool: json['isInSchool'] as bool? ?? true,
  );
}

/// Rehberlik görüşmesi
class GuidanceMeeting {
  final String id;
  final String meetingTitle;
  final List<String> participantIds;
  final int participantCount;
  final String evaluationNote;
  final DateTime date;
  final DateTime createdAt;
  final bool isIndividual;

  const GuidanceMeeting({
    required this.id,
    this.meetingTitle = '',
    required this.participantIds,
    required this.participantCount,
    this.evaluationNote = '',
    required this.date,
    required this.createdAt,
    this.isIndividual = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'meetingTitle': meetingTitle,
    'participantIds': participantIds,
    'participantCount': participantCount,
    'evaluationNote': evaluationNote,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isIndividual': isIndividual,
  };

  factory GuidanceMeeting.fromJson(Map<String, dynamic> json) => GuidanceMeeting(
    id: json['id'] as String,
    meetingTitle: json['meetingTitle'] as String? ?? '',
    participantIds: (json['participantIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
    evaluationNote: json['evaluationNote'] as String? ?? '',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    isIndividual: json['isIndividual'] as bool? ?? true,
  );
}
