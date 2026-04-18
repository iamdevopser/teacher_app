enum NotDefterimPointKind {
  daily,
  homework,
  exam,
}

class NotDefterimPointType {
  final String id;
  final String name;
  final NotDefterimPointKind kind;
  /// True ise bu puan türü final notuna etki eder.
  /// Bu türler icin UI'da 1–10 arasi dogrudan not girilir.
  final bool affectsFinal;
  final DateTime createdAt;

  const NotDefterimPointType({
    required this.id,
    required this.name,
    required this.kind,
    this.affectsFinal = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'affectsFinal': affectsFinal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotDefterimPointType.fromJson(Map<String, dynamic> json) =>
      NotDefterimPointType(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: NotDefterimPointKind.values.firstWhere(
          (e) => e.name == (json['kind'] as String? ?? 'daily'),
          orElse: () => NotDefterimPointKind.daily,
        ),
        affectsFinal: json['affectsFinal'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NotDefterimClass {
  final String id;
  final String name;
  final DateTime createdAt;

  const NotDefterimClass({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotDefterimClass.fromJson(Map<String, dynamic> json) =>
      NotDefterimClass(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NotDefterimStudent {
  final String id;
  final String classId;
  final String name;
  final DateTime createdAt;

  const NotDefterimStudent({
    required this.id,
    required this.classId,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NotDefterimStudent.fromJson(Map<String, dynamic> json) =>
      NotDefterimStudent(
        id: json['id'] as String,
        classId: json['classId'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class NotDefterimDailyEntry {
  final String id;
  final String classId;
  /// YYYY-MM-DD formatinda tutulur (Hive icinde stabil hash icin).
  final String dateStr;
  final String studentId;

  /// pointTypeId -> value
  final Map<String, double> values;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotDefterimDailyEntry({
    required this.id,
    required this.classId,
    required this.dateStr,
    required this.studentId,
    required this.values,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'dateStr': dateStr,
        'studentId': studentId,
        'values': values,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NotDefterimDailyEntry.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as Map<String, dynamic>? ?? {};
    return NotDefterimDailyEntry(
      id: json['id'] as String,
      classId: json['classId'] as String,
      dateStr: json['dateStr'] as String,
      studentId: json['studentId'] as String,
      values: rawValues.map((k, v) => MapEntry(k, (v as num).toDouble())),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class NotDefterimPeriodSummary {
  final NotDefterimClass classItem;
  final NotDefterimStudent student;
  final String periodKey;
  final double dailyAverage;
  final double homeworkAverage;
  final double examAverage;
  final int finalGrade1to10;
  /// Ödev ve sınav türleri hariç her puan türü için bu dönem içi (ilgili günlerde) toplam puan.
  final Map<String, double> periodSumByPointTypeId;

  const NotDefterimPeriodSummary({
    required this.classItem,
    required this.student,
    required this.periodKey,
    required this.dailyAverage,
    required this.homeworkAverage,
    required this.examAverage,
    required this.finalGrade1to10,
    required this.periodSumByPointTypeId,
  });
}

