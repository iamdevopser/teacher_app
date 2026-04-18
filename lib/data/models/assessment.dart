import 'dart:convert';

/// Exam or assignment assessment
class Assessment {
  final String id;
  final String studentId;
  final String classId;
  final String subject;
  final String title;
  final double score;
  final String comments;
  final DateTime date;
  final DateTime createdAt;

  const Assessment({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subject,
    required this.title,
    required this.score,
    required this.comments,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'classId': classId,
        'subject': subject,
        'title': title,
        'score': score,
        'comments': comments,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        classId: json['classId'] as String,
        subject: json['subject'] as String,
        title: json['title'] as String,
        score: (json['score'] as num).toDouble(),
        comments: json['comments'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
