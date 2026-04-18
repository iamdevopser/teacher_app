import 'course_models.dart';

/// Öğretmen odaklı kurs - kapsamlı tanım
class Course {
  final String id;
  final String name;
  final String subject;
  final String classId;
  final String? teacherName;
  final String? purpose;
  final int weeklyHours;
  final int totalWeeks;
  final String? targetAudience;
  final CourseStatus status;
  final List<CourseOutcome> outcomes;
  final List<CourseStructureItem> structure;
  final List<Map<String, dynamic>> postLessonActivities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Course({
    required this.id,
    required this.name,
    required this.subject,
    required this.classId,
    this.teacherName,
    this.purpose,
    this.weeklyHours = 0,
    this.totalWeeks = 0,
    this.targetAudience,
    this.status = CourseStatus.draft,
    this.outcomes = const [],
    this.structure = const [],
    this.postLessonActivities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => name.isNotEmpty ? name : '$classId - $subject';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subject': subject,
        'classId': classId,
        'teacherName': teacherName,
        'purpose': purpose,
        'weeklyHours': weeklyHours,
        'totalWeeks': totalWeeks,
        'targetAudience': targetAudience,
        'status': status.name,
        'outcomes': outcomes.map((e) => e.toJson()).toList(),
        'structure': structure.map((e) => e.toJson()).toList(),
        'postLessonActivities': postLessonActivities,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Course.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    CourseStatus status = CourseStatus.draft;
    if (statusStr != null) {
      status = CourseStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => CourseStatus.draft,
      );
    }

    return Course(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      teacherName: json['teacherName'] as String?,
      purpose: json['purpose'] as String?,
      weeklyHours: json['weeklyHours'] as int? ?? 0,
      totalWeeks: json['totalWeeks'] as int? ?? 0,
      targetAudience: json['targetAudience'] as String?,
      status: status,
      outcomes: (json['outcomes'] as List<dynamic>?)
              ?.map((e) => CourseOutcome.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      structure: (json['structure'] as List<dynamic>?)
              ?.map((e) =>
                  CourseStructureItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      postLessonActivities: (json['postLessonActivities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Course copyWith({
    String? id,
    String? name,
    String? subject,
    String? classId,
    String? teacherName,
    String? purpose,
    int? weeklyHours,
    int? totalWeeks,
    String? targetAudience,
    CourseStatus? status,
    List<CourseOutcome>? outcomes,
    List<CourseStructureItem>? structure,
    List<Map<String, dynamic>>? postLessonActivities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Course(
        id: id ?? this.id,
        name: name ?? this.name,
        subject: subject ?? this.subject,
        classId: classId ?? this.classId,
        teacherName: teacherName ?? this.teacherName,
        purpose: purpose ?? this.purpose,
        weeklyHours: weeklyHours ?? this.weeklyHours,
        totalWeeks: totalWeeks ?? this.totalWeeks,
        targetAudience: targetAudience ?? this.targetAudience,
        status: status ?? this.status,
        outcomes: outcomes ?? this.outcomes,
        structure: structure ?? this.structure,
        postLessonActivities: postLessonActivities ?? this.postLessonActivities,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
