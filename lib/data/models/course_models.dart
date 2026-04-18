import '../../core/localization/app_translations.dart';

/// Kurs durumu
enum CourseStatus {
  draft,
  active,
  completed,
  archived;

  /// Localized label - pass localeCode from LocaleProvider.effectiveLocale.languageCode
  String label(String localeCode) {
    final key = 'courseStatus${name[0].toUpperCase()}${name.substring(1)}';
    return AppTranslations.tr(localeCode, key);
  }
}

/// Kazanım / hedef
class CourseOutcome {
  final String id;
  final String text;
  final String type; // general, lesson, academic, behavioral, measurable

  const CourseOutcome({
    required this.id,
    required this.text,
    this.type = 'general',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'type': type,
      };

  factory CourseOutcome.fromJson(Map<String, dynamic> j) => CourseOutcome(
        id: j['id'] as String,
        text: j['text'] as String,
        type: j['type'] as String? ?? 'general',
      );
}

/// Yapı öğesi (Ünite veya Konu)
/// Ünite: children = Konular, description = Açıklama, estimatedMinutes = Tahmini Süre
/// Konu: lessonPlanPath = Ders Planı PDF, contents = Dokümanlar
class CourseStructureItem {
  final String id;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final int orderIndex;
  final int orderNo; // Ünite No / Konu No (görüntüleme için)
  final List<CourseStructureItem> children;
  final String? lessonPlanPath;
  final String? lessonPlanTitle;
  final List<LessonContentItem> contents;

  const CourseStructureItem({
    required this.id,
    required this.title,
    this.description,
    this.estimatedMinutes = 0,
    this.orderIndex = 0,
    this.orderNo = 1,
    this.children = const [],
    this.lessonPlanPath,
    this.lessonPlanTitle,
    this.contents = const [],
  });

  bool get isUnit => children.isNotEmpty || (lessonPlanPath == null && contents.isEmpty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'estimatedMinutes': estimatedMinutes,
        'orderIndex': orderIndex,
        'orderNo': orderNo,
        'children': children.map((e) => e.toJson()).toList(),
        'lessonPlanPath': lessonPlanPath,
        'lessonPlanTitle': lessonPlanTitle,
        'contents': contents.map((e) => e.toJson()).toList(),
      };

  factory CourseStructureItem.fromJson(Map<String, dynamic> j) =>
      CourseStructureItem(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        estimatedMinutes: j['estimatedMinutes'] as int? ?? 0,
        orderIndex: j['orderIndex'] as int? ?? 0,
        orderNo: j['orderNo'] as int? ?? 1,
        children: (j['children'] as List<dynamic>?)
                ?.map((e) => CourseStructureItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lessonPlanPath: j['lessonPlanPath'] as String?,
        lessonPlanTitle: j['lessonPlanTitle'] as String?,
        contents: (j['contents'] as List<dynamic>?)
                ?.map((e) => LessonContentItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  CourseStructureItem copyWith({
    String? id,
    String? title,
    String? description,
    int? estimatedMinutes,
    int? orderIndex,
    int? orderNo,
    List<CourseStructureItem>? children,
    String? lessonPlanPath,
    String? lessonPlanTitle,
    List<LessonContentItem>? contents,
  }) =>
      CourseStructureItem(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        orderIndex: orderIndex ?? this.orderIndex,
        orderNo: orderNo ?? this.orderNo,
        children: children ?? this.children,
        lessonPlanPath: lessonPlanPath ?? this.lessonPlanPath,
        lessonPlanTitle: lessonPlanTitle ?? this.lessonPlanTitle,
        contents: contents ?? this.contents,
      );
}

/// Ders akışı (Giriş, Gelişme, Pekiştirme, Değerlendirme)
class LessonFlowSection {
  final String phase;
  final String content;

  const LessonFlowSection({required this.phase, required this.content});

  Map<String, dynamic> toJson() => {'phase': phase, 'content': content};

  factory LessonFlowSection.fromJson(Map<String, dynamic> j) =>
      LessonFlowSection(
        phase: j['phase'] as String? ?? '',
        content: j['content'] as String? ?? '',
      );
}

/// Ders içerik türü
enum ContentType {
  text,
  image,
  audio,
  video,
  pdf,
  word,
  ppt,
  link,
  question,
  activity;

  /// Localized label - pass localeCode from LocaleProvider.effectiveLocale.languageCode
  String label(String localeCode) {
    final key = 'contentType${name[0].toUpperCase()}${name.substring(1)}';
    return AppTranslations.tr(localeCode, key);
  }
}

/// Ders içerik öğesi
class LessonContentItem {
  final String id;
  final String type;
  final String title;
  final String? description;
  final int orderIndex;
  final String? data; // URL, path, or inline content

  const LessonContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.orderIndex = 0,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'description': description,
        'orderIndex': orderIndex,
        'data': data,
      };

  factory LessonContentItem.fromJson(Map<String, dynamic> j) =>
      LessonContentItem(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'text',
        title: j['title'] as String,
        description: j['description'] as String?,
        orderIndex: j['orderIndex'] as int? ?? 0,
        data: j['data'] as String?,
      );
}

/// Planlanmış ders (tarihli)
class CourseScheduledLesson {
  final String id;
  final String courseId;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final List<String> targetOutcomeIds;
  final List<LessonFlowSection> flow;
  final List<LessonContentItem> contents;

  const CourseScheduledLesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.date,
    this.durationMinutes = 45,
    this.targetOutcomeIds = const [],
    this.flow = const [],
    this.contents = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'title': title,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'targetOutcomeIds': targetOutcomeIds,
        'flow': flow.map((e) => e.toJson()).toList(),
        'contents': contents.map((e) => e.toJson()).toList(),
      };

  factory CourseScheduledLesson.fromJson(Map<String, dynamic> j) =>
      CourseScheduledLesson(
        id: j['id'] as String,
        courseId: j['courseId'] as String,
        title: j['title'] as String,
        date: DateTime.parse(j['date'] as String),
        durationMinutes: j['durationMinutes'] as int? ?? 45,
        targetOutcomeIds:
            (j['targetOutcomeIds'] as List<dynamic>?)?.cast<String>() ?? [],
        flow: (j['flow'] as List<dynamic>?)
                ?.map((e) => LessonFlowSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        contents: (j['contents'] as List<dynamic>?)
                ?.map((e) => LessonContentItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
