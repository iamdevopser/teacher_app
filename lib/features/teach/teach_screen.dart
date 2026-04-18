import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/course.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/models/course_models.dart';

/// Ders Anlat ekranı - sidebar'da kurs listesi, içerik alanında kurs yayını
class TeachScreen extends StatefulWidget {
  const TeachScreen({super.key});

  @override
  State<TeachScreen> createState() => _TeachScreenState();
}

class _TeachScreenState extends State<TeachScreen> {
  Course? _selectedCourse;
  int _pageIndex = 0;
  String? _inlineDocumentUrl; // Aynı sayfada açılan döküman (path veya url)
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    if (FeatureFlags.teachPersistLastCourse) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreLastCourse());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final w = MediaQuery.sizeOf(context).width;
      if (w < 600) setState(() => _sidebarExpanded = false);
    });
  }

  void _restoreLastCourse() {
    if (!mounted) return;
    final repo = context.read<AppProvider>().repo;
    final lastId = repo.getLastSelectedCourseId();
    if (lastId != null) {
      final courses = repo.getCourses();
      try {
        final c = courses.firstWhere((x) => x.id == lastId);
        setState(() => _selectedCourse = c);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppProvider>().repo;
    final courses = repo.getCourses();

    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.shortestSide < 600;
    final compactSidebarWidth = (screenSize.width * 0.82).clamp(220.0, 280.0);
    if (isNarrow) {
      return Scaffold(
        body: Column(
          children: [
            _buildMobileTeachHeader(context, courses),
            Expanded(
              child: _inlineDocumentUrl != null
                  ? _buildDocumentViewer(context)
                  : _selectedCourse == null
                  ? _buildNoCourseSelected(context)
                  : _buildCourseContent(context),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          // Sidebar - Açılıp kapanabilir (mobilde yer kaplamasın diye)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _sidebarExpanded
                ? (isNarrow ? compactSidebarWidth : 260.0)
                : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              border: Border(
                right: BorderSide(
                  color: _sidebarExpanded
                      ? Theme.of(context).dividerColor
                      : Colors.transparent,
                ),
              ),
            ),
            child: _sidebarExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('myLessons'),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isNarrow ? Icons.close : Icons.chevron_left,
                              ),
                              tooltip: context.tr('close'),
                              onPressed: () =>
                                  setState(() => _sidebarExpanded = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: courses.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    context.tr('noCoursesYet'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                children: [
                                  ...courses.map((c) {
                                    final isSelected =
                                        _selectedCourse?.id == c.id;
                                    return ListTile(
                                      dense: isNarrow,
                                      leading: const Icon(Icons.menu_book),
                                      title: Text(
                                        c.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      selected: isSelected,
                                      onTap: () {
                                        if (FeatureFlags
                                            .teachPersistLastCourse) {
                                          context
                                              .read<AppProvider>()
                                              .repo
                                              .setLastSelectedCourseId(c.id);
                                        }
                                        setState(() {
                                          _selectedCourse = c;
                                          _pageIndex = 0;
                                          _inlineDocumentUrl = null;
                                        });
                                      },
                                    );
                                  }),
                                  if (_selectedCourse != null) ...[
                                    const Divider(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        context.tr('coursePages'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.info_outline,
                                        size: 20,
                                        color: _pageIndex == 0
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      title: Text(
                                        context.tr('pageIntroOutcomes'),
                                      ),
                                      selected: _pageIndex == 0,
                                      onTap: () => setState(() {
                                        _pageIndex = 0;
                                        _inlineDocumentUrl = null;
                                      }),
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.account_tree_outlined,
                                        size: 20,
                                        color: _pageIndex == 1
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      title: Text(
                                        context.tr('pageUnitsTopics'),
                                      ),
                                      selected: _pageIndex == 1,
                                      onTap: () => setState(() {
                                        _pageIndex = 1;
                                        _inlineDocumentUrl = null;
                                      }),
                                    ),
                                    ListTile(
                                      leading: Icon(
                                        Icons.extension,
                                        size: 20,
                                        color: _pageIndex == 2
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      title: Text(
                                        context.tr('pageActivitiesGamesQuiz'),
                                      ),
                                      selected: _pageIndex == 2,
                                      onTap: () => setState(() {
                                        _pageIndex = 2;
                                        _inlineDocumentUrl = null;
                                      }),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          // Content - Kurs yayını veya döküman görüntüleyici
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (_inlineDocumentUrl != null)
                  _buildDocumentViewer(context)
                else if (_selectedCourse == null)
                  _buildNoCourseSelected(context)
                else
                  _buildCourseContent(context),
                // Sidebar kapalıyken menüyü açan buton
                if (!_sidebarExpanded)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(8),
                      child: IconButton(
                        icon: const Icon(Icons.menu),
                        tooltip: context.tr('myLessons'),
                        onPressed: () =>
                            setState(() => _sidebarExpanded = true),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTeachHeader(BuildContext context, List<Course> courses) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(56, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCourse?.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('courses'),
                  border: const OutlineInputBorder(),
                ),
                items: courses
                    .map(
                      (course) => DropdownMenuItem(
                        value: course.id,
                        child: Text(
                          course.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  final selected = courses.where((course) => course.id == value);
                  if (selected.isEmpty) return;
                  setState(() {
                    _selectedCourse = selected.first;
                    _pageIndex = 0;
                    _inlineDocumentUrl = null;
                  });
                },
              ),
              if (_selectedCourse != null) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _mobilePageChip(context, 0, context.tr('pageIntroOutcomes')),
                      const SizedBox(width: 8),
                      _mobilePageChip(context, 1, context.tr('pageUnitsTopics')),
                      const SizedBox(width: 8),
                      _mobilePageChip(
                        context,
                        2,
                        context.tr('pageActivitiesGamesQuiz'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobilePageChip(BuildContext context, int pageIndex, String label) {
    final selected = _pageIndex == pageIndex;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _pageIndex = pageIndex;
        _inlineDocumentUrl = null;
      }),
    );
  }

  Widget _buildNoCourseSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('selectCourseToTeach'),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent(BuildContext context) {
    final course = _selectedCourse!;
    final isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    return Column(
      children: [
        if (!isCompact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _pageIndex > 0
                      ? () => setState(() => _pageIndex--)
                      : null,
                ),
                Text(
                  _pageIndex == 0
                      ? context.tr('pageIntroOutcomes')
                      : _pageIndex == 1
                      ? context.tr('pageUnitsTopics')
                      : context.tr('pageActivitiesGamesQuiz'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _pageIndex < 2
                      ? () => setState(() => _pageIndex++)
                      : null,
                ),
              ],
            ),
          ),
        Expanded(
          child: _pageIndex == 0
              ? _buildPage1(context)
              : _pageIndex == 1
              ? _buildPage2(context)
              : _buildPage3(context),
        ),
        if (context.read<AppProvider>().repo.getSettingsOnlineLessonFeatures())
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _OnlineLessonCard(course: course),
          ),
      ],
    );
  }

  Widget _buildPage1(BuildContext context) {
    final course = _selectedCourse!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            course.displayName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${course.subject} • ${course.classId}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('coursePurpose'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            course.purpose ?? context.tr('purposeNotSpecified'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
          if (course.outcomes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              context.tr('outcomes'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...course.outcomes.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flag,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        o.text,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtHours(int minutes) {
    final h = minutes / 60;
    return h == h.truncateToDouble() ? '${h.toInt()}' : h.toString();
  }

  Widget _buildPage2(BuildContext context) {
    final course = _selectedCourse!;
    if (course.structure.isEmpty) {
      return Center(child: Text(context.tr('noContentYet')));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('courseStructure'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...course.structure.map(
            (unit) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.folder),
                title: Text(unit.title),
                subtitle: unit.estimatedMinutes > 0
                    ? Text(
                        '${_fmtHours(unit.estimatedMinutes)} ${context.tr('hoursAbbr')}',
                      )
                    : null,
                children: unit.children.isEmpty
                    ? []
                    : unit.children
                          .map((t) => _buildTopicTile(context, t))
                          .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3(BuildContext context) {
    final course = _selectedCourse!;
    if (course.postLessonActivities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('noContentYet'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('step6Title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...course.postLessonActivities.map((item) {
            final type = item['type'] as String? ?? '';
            final title =
                item['name'] as String? ?? item['title'] as String? ?? '-';
            final rawItems = item['instructionItems'];
            final instructionItems = <Map<String, String>>[];
            if (rawItems is List) {
              for (final x in rawItems) {
                if (x is Map) {
                  final m = Map<String, dynamic>.from(x);
                  final t = m['type']?.toString() ?? 'text';
                  final c =
                      m['content']?.toString() ?? m['data']?.toString() ?? '';
                  instructionItems.add({'type': t, 'content': c});
                }
              }
            }
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: Icon(_teachActivityIconForType(type)),
                title: Text('$title ($type)'),
                children: _teachBuildActivityExpandContent(
                  context,
                  item,
                  instructionItems,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _teachActivityIconForType(String type) {
    switch (type) {
      case 'activity':
        return Icons.assignment;
      case 'game':
        return Icons.sports_esports;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.extension;
    }
  }

  List<Widget> _teachBuildActivityExpandContent(
    BuildContext context,
    Map<String, dynamic> item,
    List<Map<String, String>> instructionItems,
  ) {
    final type = item['type'] as String? ?? '';
    final children = <Widget>[];
    if (type == 'activity') {
      final instructions = item['instructions'] as String? ?? '';
      if (instructions.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('activityInstructions'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  instructions,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
      }
    } else if (type == 'game') {
      final rules =
          item['gameRules'] as String? ?? item['rules'] as String? ?? '';
      if (rules.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('gameRules'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(rules, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      }
    } else if (type == 'quiz') {
      final quizLink = item['quizFileOrLink'] as String?;
      if (quizLink != null && quizLink.isNotEmpty) {
        final isUrl =
            quizLink.startsWith('http://') || quizLink.startsWith('https://');
        children.add(
          _teachActivityDocTile(context, {
            'type': isUrl ? 'link' : 'file',
            'content': quizLink,
          }),
        );
      }
    }
    if (instructionItems.isNotEmpty) {
      if (children.isNotEmpty) children.add(const Divider(height: 1));
      children.addAll(
        instructionItems.map((doc) => _teachActivityDocTile(context, doc)),
      );
    }
    if (children.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr('noDocuments'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return children;
  }

  Widget _teachActivityDocTile(BuildContext context, Map<String, String> doc) {
    final type = doc['type'] ?? 'text';
    final content = doc['content'] ?? '';
    IconData icon = Icons.text_fields;
    if (type == 'file')
      icon = Icons.insert_drive_file;
    else if (type == 'video')
      icon = Icons.video_file;
    else if (type == 'audio')
      icon = Icons.audiotrack;
    else if (type == 'link')
      icon = Icons.link;
    final isUrl =
        content.startsWith('http://') || content.startsWith('https://');
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(
        content.length > 60 ? '${content.substring(0, 60)}...' : content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: isUrl
          ? () async {
              final uri = Uri.tryParse(content);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
    );
  }

  Widget _buildTopicTile(BuildContext context, CourseStructureItem topic) {
    if (topic.contents.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.topic, size: 20),
        title: Text(topic.title),
      );
    }
    return ExpansionTile(
      leading: const Icon(Icons.topic, size: 20),
      title: Text(topic.title),
      children: topic.contents
          .map((c) => _buildContentTile(context, c))
          .toList(),
    );
  }

  Widget _buildContentTile(BuildContext context, LessonContentItem c) {
    final url = c.data;
    final isUrl =
        url != null &&
        (url.startsWith('http://') || url.startsWith('https://'));
    final label = c.title.isNotEmpty ? c.title : (url ?? '-');
    return ListTile(
      dense: true,
      leading: Icon(_iconForType(c.type), size: 18),
      title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: url != null && url.isNotEmpty
          ? () async {
              if (isUrl) {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } else {
                if (FeatureFlags.homeRecentItems) {
                  context.read<AppProvider>().repo.setLastOpenedDocument(url);
                }
                setState(() => _inlineDocumentUrl = url);
              }
            }
          : null,
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'link':
        return Icons.link;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'word':
        return Icons.description;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildDocumentViewer(BuildContext context) {
    final path = _inlineDocumentUrl!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _inlineDocumentUrl = null),
              ),
              Expanded(
                child: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildPdfViewer(path)),
      ],
    );
  }

  Widget _buildPdfViewer(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return Center(child: Text(context.tr('fileNotFound')));
    }
    return _InlinePdfViewer(filePath: path);
  }
}

class _InlinePdfViewer extends StatefulWidget {
  const _InlinePdfViewer({required this.filePath});

  final String filePath;

  @override
  State<_InlinePdfViewer> createState() => _InlinePdfViewerState();
}

const double _kEraserRadius = 18;

class _InlinePdfViewerState extends State<_InlinePdfViewer> {
  late PdfController _controller;
  bool _penMode = false;
  bool _eraserMode = false;
  Color _penColor = Colors.red;
  double _penStrokeWidth = 3;
  bool _screenshotMode = false;
  final GlobalKey _captureKey = GlobalKey();
  _DrawingOverlayController? _drawingController;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openFile(widget.filePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureScreenshot({Rect? region}) async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      const pixelRatio = 2.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      ui.Image croppedImage = image;
      if (region != null && region.width > 4 && region.height > 4) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final srcRect = Rect.fromLTWH(
          region.left * pixelRatio,
          region.top * pixelRatio,
          region.width * pixelRatio,
          region.height * pixelRatio,
        );
        final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
        canvas.drawImageRect(image, srcRect, dstRect, Paint());
        final picture = recorder.endRecording();
        croppedImage = await picture.toImage(
          srcRect.width.toInt(),
          srcRect.height.toInt(),
        );
      }
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${dir.path}/TeacherApp/Screenshots');
      if (!await screenshotsDir.exists())
        await screenshotsDir.create(recursive: true);
      final file = File(
        '${screenshotsDir.path}/ekran_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('screenshotSaved')}: ${file.path}'),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  static const List<Color> _penColors = [
    Colors.red,
    Colors.blue,
    Colors.black,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.teal,
  ];

  static const List<double> _penStrokeWidths = [1, 2, 3, 5, 8];

  void _showColorAndThicknessMenu(BuildContext context) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 220,
        80,
        20,
        MediaQuery.of(context).size.height - 200,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('penColor'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _penColors.map((c) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _penColor = c);
                      _drawingController?.setColor(c);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _penColor == c
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('penThickness'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: _penStrokeWidths.map((w) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _penStrokeWidth = w);
                      _drawingController?.setStrokeWidth(w);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 6,
                      width: 20 + w,
                      decoration: BoxDecoration(
                        color: _penStrokeWidth == w
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(context),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RepaintBoundary(
                key: _captureKey,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(
                      ignoring: _penMode,
                      child: PdfView(controller: _controller),
                    ),
                    if (_penMode)
                      _DrawingOverlay(
                        penColor: _penColor,
                        penStrokeWidth: _penStrokeWidth,
                        eraserMode: _eraserMode,
                        onControllerReady: (c) => _drawingController = c,
                      ),
                  ],
                ),
              ),
              if (_screenshotMode)
                _ScreenshotOverlay(
                  onFull: () {
                    _captureScreenshot();
                    setState(() => _screenshotMode = false);
                  },
                  onRegion: (rect) {
                    _captureScreenshot(region: rect);
                    setState(() => _screenshotMode = false);
                  },
                  onCancel: () => setState(() => _screenshotMode = false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: context.tr('prevPage'),
            onPressed: () => _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: _controller.pageListenable,
            builder: (_, page, __) {
              final total = _controller.pagesCount ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$page / ${total > 0 ? total : "?"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: context.tr('nextPage'),
            onPressed: () => _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: context.tr('firstPage'),
            onPressed: () => _controller.jumpToPage(1),
          ),
          const VerticalDivider(width: 24),
          IconButton(
            icon: Icon(_penMode ? Icons.draw : Icons.draw_outlined),
            tooltip: context.tr('penMode'),
            onPressed: () => setState(() => _penMode = !_penMode),
          ),
          if (_penMode) ...[
            IconButton(
              icon: Icon(
                _eraserMode
                    ? Icons.cleaning_services
                    : Icons.cleaning_services_outlined,
              ),
              tooltip: context.tr('erasePart'),
              onPressed: () {
                setState(() => _eraserMode = !_eraserMode);
                _drawingController?.setEraserMode(_eraserMode);
              },
            ),
            IconButton(
              icon: Icon(Icons.palette_outlined, color: _penColor),
              tooltip: context.tr('penColor'),
              onPressed: () => _showColorAndThicknessMenu(context),
            ),
            IconButton(
              icon: const Icon(Icons.content_cut),
              tooltip: context.tr('screenshot'),
              onPressed: () => setState(() => _screenshotMode = true),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawingOverlayController {
  void Function(Color)? _setColor;
  void Function(double)? _setStrokeWidth;
  void Function(bool)? _setEraserMode;
  void setColor(Color c) => _setColor?.call(c);
  void setStrokeWidth(double w) => _setStrokeWidth?.call(w);
  void setEraserMode(bool v) => _setEraserMode?.call(v);
}

class _DrawingOverlay extends StatefulWidget {
  const _DrawingOverlay({
    required this.penColor,
    required this.penStrokeWidth,
    required this.eraserMode,
    required this.onControllerReady,
  });

  final Color penColor;
  final double penStrokeWidth;
  final bool eraserMode;
  final void Function(_DrawingOverlayController) onControllerReady;

  @override
  State<_DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<_DrawingOverlay> {
  final List<List<Offset>> _strokes = [];
  final ValueNotifier<int> _versionNotifier = ValueNotifier(0);
  late _DrawingOverlayController _controller;
  late Color _currentColor;
  late double _currentStrokeWidth;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.penColor;
    _currentStrokeWidth = widget.penStrokeWidth;
    _controller = _DrawingOverlayController()
      .._setColor = (c) {
        _currentColor = c;
        _versionNotifier.value++;
      }
      .._setStrokeWidth = (w) {
        _currentStrokeWidth = w;
        _versionNotifier.value++;
      }
      .._setEraserMode = (_) {};
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onControllerReady(_controller),
    );
  }

  @override
  void dispose() {
    _versionNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DrawingOverlay old) {
    super.didUpdateWidget(old);
    if (widget.penColor != old.penColor) _currentColor = widget.penColor;
    if (widget.penStrokeWidth != old.penStrokeWidth)
      _currentStrokeWidth = widget.penStrokeWidth;
  }

  void _addPoint(Offset p) {
    if (_strokes.isEmpty) return;
    _strokes.last.add(p);
    _versionNotifier.value++;
  }

  void _eraseAt(Offset pos) {
    final newStrokes = <List<Offset>>[];
    for (final stroke in _strokes) {
      final segments = <List<Offset>>[];
      List<Offset> current = [];
      for (final p in stroke) {
        if ((p - pos).distance < _kEraserRadius) {
          if (current.length >= 2) segments.add(List.from(current));
          current = [];
        } else {
          current.add(p);
        }
      }
      if (current.length >= 2) segments.add(List.from(current));
      newStrokes.addAll(segments);
    }
    final oldLen = _strokes.fold<int>(0, (s, x) => s + x.length);
    final newLen = newStrokes.fold<int>(0, (s, x) => s + x.length);
    if (newStrokes.length != _strokes.length || newLen != oldLen) {
      _strokes.clear();
      _strokes.addAll(newStrokes);
      _versionNotifier.value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          final pos = d.localPosition;
          if (widget.eraserMode) {
            _eraseAt(pos);
          } else {
            _strokes.add([pos]);
            _versionNotifier.value++;
          }
        },
        onPanUpdate: (d) {
          final pos = d.localPosition;
          if (widget.eraserMode) {
            _eraseAt(pos);
          } else {
            _addPoint(pos);
          }
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _versionNotifier,
          builder: (_, version, __) => CustomPaint(
            painter: _DrawingPainter(
              strokes: _strokes,
              color: _currentColor,
              strokeWidth: _currentStrokeWidth,
              version: version,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
    required this.version,
  });

  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) =>
      old.version != version || old.strokeWidth != strokeWidth;
}

class _ScreenshotOverlay extends StatefulWidget {
  const _ScreenshotOverlay({
    required this.onFull,
    required this.onRegion,
    required this.onCancel,
  });

  final VoidCallback onFull;
  final void Function(Rect) onRegion;
  final VoidCallback onCancel;

  @override
  State<_ScreenshotOverlay> createState() => _ScreenshotOverlayState();
}

class _ScreenshotOverlayState extends State<_ScreenshotOverlay> {
  Offset? _start;
  Offset? _current;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black38,
        child: Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                setState(() {
                  _start = e.localPosition;
                  _current = e.localPosition;
                });
              },
              onPointerMove: (e) {
                if (_start != null) setState(() => _current = e.localPosition);
              },
              onPointerUp: (_) {
                if (_start != null && _current != null) {
                  final rect = Rect.fromPoints(_start!, _current!);
                  if (rect.width > 4 && rect.height > 4) {
                    widget.onRegion(rect);
                  }
                }
                setState(() {
                  _start = null;
                  _current = null;
                });
              },
              child: CustomPaint(
                painter: _SelectionPainter(start: _start, current: _current),
                size: Size.infinite,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('screenshot'),
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(
                              Icons.crop_free,
                              color: Colors.white,
                            ),
                            label: Text(
                              context.tr('screenshotFullBtn'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            onPressed: widget.onFull,
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: widget.onCancel,
                            child: Text(
                              context.tr('screenshotCancel'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// extra.md: Online ders – katılım, teknik not, yansıma, kayıt linki
class _OnlineLessonCard extends StatefulWidget {
  const _OnlineLessonCard({required this.course});

  final Course course;

  @override
  State<_OnlineLessonCard> createState() => _OnlineLessonCardState();
}

class _OnlineLessonCardState extends State<_OnlineLessonCard> {
  late TextEditingController _attendanceCtrl;
  late TextEditingController _technicalCtrl;
  late TextEditingController _reflectionCtrl;
  late TextEditingController _recordingCtrl;
  List<_OnlineAttendanceStudent> _students = const [];
  Map<String, bool> _attendanceByStudent = {};

  @override
  void initState() {
    super.initState();
    _attendanceCtrl = TextEditingController();
    _technicalCtrl = TextEditingController();
    _reflectionCtrl = TextEditingController();
    _recordingCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _attendanceCtrl.dispose();
    _technicalCtrl.dispose();
    _reflectionCtrl.dispose();
    _recordingCtrl.dispose();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    final repo = context.read<AppProvider>().repo;
    final note = repo.getTeachOnlineSessionNote(
      widget.course.id,
      DateTime.now(),
    );
    _students = _loadStudents(repo);
    _attendanceByStudent = {for (final student in _students) student.id: false};
    final rawRecords = note['attendanceRecords'];
    if (rawRecords != null && rawRecords.isNotEmpty) {
      try {
        final decoded = List<Map<String, dynamic>>.from(
          (jsonDecode(rawRecords) as List<dynamic>).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
        for (final item in decoded) {
          final id = item['studentId']?.toString() ?? '';
          if (id.isEmpty) continue;
          _attendanceByStudent[id] = item['attended'] == true;
        }
      } catch (_) {}
    }
    _attendanceCtrl.text = note['attendanceNote'] ?? note['attendance'] ?? '';
    _technicalCtrl.text = note['technical'] ?? '';
    _reflectionCtrl.text = note['reflection'] ?? '';
    _recordingCtrl.text = note['recordingLink'] ?? '';
    setState(() {});
  }

  List<_OnlineAttendanceStudent> _loadStudents(AppRepository repo) {
    final seen = <String>{};
    final result = <_OnlineAttendanceStudent>[];

    for (final student in repo.getGuidanceStudents()) {
      if (student.classId != widget.course.classId) continue;
      if (seen.add(student.id)) {
        result.add(
          _OnlineAttendanceStudent(id: student.id, name: student.fullName),
        );
      }
    }

    for (final student in repo.getStudentsByClass(widget.course.classId)) {
      if (seen.add(student.id)) {
        result.add(
          _OnlineAttendanceStudent(id: student.id, name: student.name),
        );
      }
    }

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  String _buildAttendanceSummary() {
    if (_students.isEmpty) return _attendanceCtrl.text.trim();
    final attended = _attendanceByStudent.values.where((v) => v).length;
    final absent = _attendanceByStudent.length - attended;
    return '${context.tr('present')}: $attended • ${context.tr('absent')}: $absent';
  }

  Future<void> _save() async {
    final repo = context.read<AppProvider>().repo;
    final attendanceRecords = _students
        .map(
          (student) => {
            'studentId': student.id,
            'studentName': student.name,
            'attended': _attendanceByStudent[student.id] ?? false,
          },
        )
        .toList();
    await repo.setTeachOnlineSessionNote(widget.course.id, DateTime.now(), {
      'attendance': _buildAttendanceSummary(),
      'attendanceNote': _attendanceCtrl.text.trim(),
      'attendanceRecords': jsonEncode(attendanceRecords),
      'technical': _technicalCtrl.text.trim(),
      'reflection': _reflectionCtrl.text.trim(),
      'recordingLink': _recordingCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('saved'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendedCount = _attendanceByStudent.values.where((v) => v).length;
    final absentCount = _attendanceByStudent.length - attendedCount;
    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.videocam,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(context.tr('teachOnlineLabel')),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_students.isNotEmpty) ...[
                  Text(
                    '${widget.course.classId} • ${context.tr('students')}: ${_students.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text('${context.tr('present')}: $attendedCount'),
                      ),
                      Chip(
                        label: Text('${context.tr('absent')}: $absentCount'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._students.map(
                    (student) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(student.name),
                      subtitle: Text(
                        (_attendanceByStudent[student.id] ?? false)
                            ? context.tr('present')
                            : context.tr('absent'),
                      ),
                      value: _attendanceByStudent[student.id] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _attendanceByStudent[student.id] = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _attendanceCtrl,
                  decoration: InputDecoration(
                    labelText: _students.isEmpty
                        ? context.tr('teachAttendanceNote')
                        : context.tr('notes'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: _students.isEmpty ? 1 : 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _technicalCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('teachTechnicalNote'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reflectionCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('teachReflectionNote'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _recordingCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('teachRecordingLink'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: _save, child: Text(context.tr('save'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineAttendanceStudent {
  const _OnlineAttendanceStudent({required this.id, required this.name});

  final String id;
  final String name;
}

class _SelectionPainter extends CustomPainter {
  _SelectionPainter({this.start, this.current});

  final Offset? start;
  final Offset? current;

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;
    final rect = Rect.fromPoints(start!, current!);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter old) =>
      old.start != start || old.current != current;
}
