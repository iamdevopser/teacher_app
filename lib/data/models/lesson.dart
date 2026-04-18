import 'dart:convert';

/// Daily lesson record
class Lesson {
  final String id;
  final String classId;
  final String subject;
  final String topic;
  final String notes;
  final DateTime date;
  final bool completed;
  final DateTime createdAt;

  const Lesson({
    required this.id,
    required this.classId,
    required this.subject,
    required this.topic,
    required this.notes,
    required this.date,
    required this.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'subject': subject,
        'topic': topic,
        'notes': notes,
        'date': date.toIso8601String(),
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        classId: json['classId'] as String,
        subject: json['subject'] as String,
        topic: json['topic'] as String,
        notes: json['notes'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        completed: json['completed'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Lesson copyWith({
    String? id,
    String? classId,
    String? subject,
    String? topic,
    String? notes,
    DateTime? date,
    bool? completed,
    DateTime? createdAt,
  }) =>
      Lesson(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        subject: subject ?? this.subject,
        topic: topic ?? this.topic,
        notes: notes ?? this.notes,
        date: date ?? this.date,
        completed: completed ?? this.completed,
        createdAt: createdAt ?? this.createdAt,
      );
}
