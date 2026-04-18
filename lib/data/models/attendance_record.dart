import 'dart:convert';

/// Attendance status
enum AttendanceStatus { present, absent, late }

/// Daily attendance record per student
class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'classId': classId,
        'date': date.toIso8601String(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        classId: json['classId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => AttendanceStatus.present,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
