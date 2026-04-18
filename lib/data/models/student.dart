import 'dart:convert';

/// Student profile with academic and behavioral notes
class Student {
  final String id;
  final String classId;
  final String name;
  final String academicNotes;
  final String behavioralNotes;
  final List<String> tags;
  final DateTime createdAt;

  const Student({
    required this.id,
    required this.classId,
    required this.name,
    required this.academicNotes,
    required this.behavioralNotes,
    required this.tags,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'name': name,
        'academicNotes': academicNotes,
        'behavioralNotes': behavioralNotes,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        classId: json['classId'] as String,
        name: json['name'] as String,
        academicNotes: json['academicNotes'] as String? ?? '',
        behavioralNotes: json['behavioralNotes'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Student copyWith({
    String? id,
    String? classId,
    String? name,
    String? academicNotes,
    String? behavioralNotes,
    List<String>? tags,
    DateTime? createdAt,
  }) =>
      Student(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        name: name ?? this.name,
        academicNotes: academicNotes ?? this.academicNotes,
        behavioralNotes: behavioralNotes ?? this.behavioralNotes,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
      );
}
