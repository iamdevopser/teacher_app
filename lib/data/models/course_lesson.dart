import 'dart:convert';

/// Course lesson (step) - part of a course
class CourseLesson {
  final String id;
  final String courseId;
  final String title;
  final String? objective;
  final List<String> blockIds;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseLesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.objective,
    required this.blockIds,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'objective': objective,
        'blockIds': blockIds,
        'orderIndex': orderIndex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CourseLesson.fromJson(Map<String, dynamic> json) => CourseLesson(
        id: json['id'] as String,
        courseId: json['courseId'] as String,
        title: json['title'] as String,
        objective: json['objective'] as String?,
        blockIds: (json['blockIds'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        orderIndex: json['orderIndex'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  CourseLesson copyWith({
    String? id,
    String? courseId,
    String? title,
    String? objective,
    List<String>? blockIds,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      CourseLesson(
        id: id ?? this.id,
        courseId: courseId ?? this.courseId,
        title: title ?? this.title,
        objective: objective ?? this.objective,
        blockIds: blockIds ?? this.blockIds,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
