/// Haftalık ders programı hücresi (gün x saat)
class WeeklyScheduleCell {
  final int dayIndex; // 0-6 veya 1-7
  final int hourIndex; // 0-7 (8 saat)
  final String? classId; // Örn: 11A

  const WeeklyScheduleCell({
    required this.dayIndex,
    required this.hourIndex,
    this.classId,
  });

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'hourIndex': hourIndex,
        'classId': classId,
      };

  factory WeeklyScheduleCell.fromJson(Map<String, dynamic> j) =>
      WeeklyScheduleCell(
        dayIndex: j['dayIndex'] as int,
        hourIndex: j['hourIndex'] as int,
        classId: j['classId'] as String?,
      );
}

/// Yıllık plan satırı
class AnnualPlanRow {
  final String id;
  final int rowNo;
  final int weekNo;
  final int lessonNo;
  final DateTime date;
  final String classId;
  final String topic;
  final String outcome;
  final String homework;

  const AnnualPlanRow({
    required this.id,
    required this.rowNo,
    required this.weekNo,
    required this.lessonNo,
    required this.date,
    required this.classId,
    required this.topic,
    required this.outcome,
    required this.homework,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'rowNo': rowNo,
        'weekNo': weekNo,
        'lessonNo': lessonNo,
        'date': date.toIso8601String(),
        'classId': classId,
        'topic': topic,
        'outcome': outcome,
        'homework': homework,
      };

  factory AnnualPlanRow.fromJson(Map<String, dynamic> j) => AnnualPlanRow(
        id: j['id'] as String,
        rowNo: j['rowNo'] as int? ?? 1,
        weekNo: j['weekNo'] as int? ?? 0,
        lessonNo: j['lessonNo'] as int? ?? 0,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        classId: j['classId'] as String? ?? '',
        topic: j['topic'] as String? ?? '',
        outcome: j['outcome'] as String? ?? '',
        homework: j['homework'] as String? ?? '',
      );
}

/// Yıllık plan üst bilgileri (tablo üstünde gösterilir)
class AnnualPlanMetadata {
  final String institutionName;
  final String academicCalendar;
  final String courseName;
  final String teacherName;
  final String classes;
  final String annualHours;
  final String weeklyHours;
  final String totalWeeks;
  final String examCount;
  final String books;
  final String courseTeacherNameSignature;
  final String departmentHeadNameSignature;

  const AnnualPlanMetadata({
    this.institutionName = '',
    this.academicCalendar = '',
    this.courseName = '',
    this.teacherName = '',
    this.classes = '',
    this.annualHours = '',
    this.weeklyHours = '',
    this.totalWeeks = '',
    this.examCount = '',
    this.books = '',
    this.courseTeacherNameSignature = '',
    this.departmentHeadNameSignature = '',
  });

  Map<String, dynamic> toJson() => {
        'institutionName': institutionName,
        'academicCalendar': academicCalendar,
        'courseName': courseName,
        'teacherName': teacherName,
        'classes': classes,
        'annualHours': annualHours,
        'weeklyHours': weeklyHours,
        'totalWeeks': totalWeeks,
        'examCount': examCount,
        'books': books,
        'courseTeacherNameSignature': courseTeacherNameSignature,
        'departmentHeadNameSignature': departmentHeadNameSignature,
      };

  factory AnnualPlanMetadata.fromJson(Map<String, dynamic> j) => AnnualPlanMetadata(
        institutionName: j['institutionName'] as String? ?? '',
        academicCalendar: j['academicCalendar'] as String? ?? '',
        courseName: j['courseName'] as String? ?? '',
        teacherName: j['teacherName'] as String? ?? '',
        classes: j['classes'] as String? ?? '',
        annualHours: j['annualHours'] as String? ?? '',
        weeklyHours: j['weeklyHours'] as String? ?? '',
        totalWeeks: j['totalWeeks'] as String? ?? '',
        examCount: j['examCount'] as String? ?? '',
        books: j['books'] as String? ?? '',
        courseTeacherNameSignature: j['courseTeacherNameSignature'] as String? ?? '',
        departmentHeadNameSignature: j['departmentHeadNameSignature'] as String? ?? '',
      );
}

/// Günlük ders planı
class DailyLessonPlan {
  final String id;
  final String subjectName;
  final String classId;
  final String teacherName;
  final DateTime date;
  final int weekNo;
  final int lessonNo;
  final String lessonHour;
  final String topic;
  final String outcome;
  final String intro;
  final String development;
  final String evaluation;
  final String method;
  final String material;
  final String lessonNote;
  final bool completed;
  final bool needsMakeup;
  final bool isPlanned;
  final DateTime createdAt;
  final String? filePath;
  /// extra.md: Ders türü – yüz yüze / online / hibrit
  final String? lessonType;
  /// extra.md: Online seçildiyse ders linki (Zoom/Meet/Teams)
  final String? lessonLink;
  /// extra.md: Online ders süresi (dakika)
  final int? lessonDurationMinutes;
  /// extra.md: Opsiyonel bağlı grup id
  final String? linkedGroupId;

  const DailyLessonPlan({
    required this.id,
    required this.subjectName,
    required this.classId,
    required this.teacherName,
    required this.date,
    this.weekNo = 0,
    this.lessonNo = 0,
    required this.lessonHour,
    required this.topic,
    required this.outcome,
    required this.intro,
    required this.development,
    required this.evaluation,
    required this.method,
    required this.material,
    required this.lessonNote,
    required this.completed,
    required this.needsMakeup,
    this.isPlanned = true,
    required this.createdAt,
    this.filePath,
    this.lessonType,
    this.lessonLink,
    this.lessonDurationMinutes,
    this.linkedGroupId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectName': subjectName,
        'classId': classId,
        'teacherName': teacherName,
        'date': date.toIso8601String(),
        'weekNo': weekNo,
        'lessonNo': lessonNo,
        'lessonHour': lessonHour,
        'topic': topic,
        'outcome': outcome,
        'intro': intro,
        'development': development,
        'evaluation': evaluation,
        'method': method,
        'material': material,
        'lessonNote': lessonNote,
        'completed': completed,
        'needsMakeup': needsMakeup,
        'isPlanned': isPlanned,
        'createdAt': createdAt.toIso8601String(),
        'filePath': filePath,
        if (lessonType != null) 'lessonType': lessonType,
        if (lessonLink != null) 'lessonLink': lessonLink,
        if (lessonDurationMinutes != null) 'lessonDurationMinutes': lessonDurationMinutes,
        if (linkedGroupId != null) 'linkedGroupId': linkedGroupId,
      };

  factory DailyLessonPlan.fromJson(Map<String, dynamic> j) => DailyLessonPlan(
        id: j['id'] as String,
        subjectName: j['subjectName'] as String? ?? '',
        classId: j['classId'] as String? ?? '',
        teacherName: j['teacherName'] as String? ?? '',
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        weekNo: j['weekNo'] as int? ?? 0,
        lessonNo: j['lessonNo'] as int? ?? 0,
        lessonHour: j['lessonHour'] as String? ?? '',
        topic: j['topic'] as String? ?? '',
        outcome: j['outcome'] as String? ?? '',
        intro: j['intro'] as String? ?? '',
        development: j['development'] as String? ?? '',
        evaluation: j['evaluation'] as String? ?? '',
        method: j['method'] as String? ?? '',
        material: j['material'] as String? ?? '',
        lessonNote: j['lessonNote'] as String? ?? '',
        completed: j['completed'] as bool? ?? false,
        needsMakeup: j['needsMakeup'] as bool? ?? false,
        isPlanned: j['isPlanned'] as bool? ?? true,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        filePath: j['filePath'] as String?,
        lessonType: j['lessonType'] as String?,
        lessonLink: j['lessonLink'] as String?,
        lessonDurationMinutes: j['lessonDurationMinutes'] as int?,
        linkedGroupId: j['linkedGroupId'] as String?,
      );
}

/// Ders/Sınav dökümanı
class LessonDocument {
  final String id;
  final String classId;
  final String name;
  final String format; // PDF, Word, Excel, PPT, Audio, Video, Link
  final String? pathOrUrl;

  const LessonDocument({
    required this.id,
    required this.classId,
    required this.name,
    required this.format,
    this.pathOrUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'classId': classId,
        'name': name,
        'format': format,
        'pathOrUrl': pathOrUrl,
      };

  factory LessonDocument.fromJson(Map<String, dynamic> j) => LessonDocument(
        id: j['id'] as String,
        classId: j['classId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        format: j['format'] as String? ?? 'PDF',
        pathOrUrl: j['pathOrUrl'] as String?,
      );
}
