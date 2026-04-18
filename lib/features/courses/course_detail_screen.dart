import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/course.dart';
import '../../data/models/course_models.dart';
import '../../data/services/course_file_storage_service.dart';
import 'package:share_plus/share_plus.dart';
import 'course_wizard_controller.dart';
import 'course_wizard_screen.dart';

String _fmtHours(int minutes) {
  final h = minutes / 60;
  return h == h.truncateToDouble() ? '${h.toInt()}' : h.toString();
}

IconData _activityIconForType(String type) {
  switch (type) {
    case 'activity': return Icons.assignment;
    case 'game': return Icons.sports_esports;
    case 'quiz': return Icons.quiz;
    default: return Icons.circle;
  }
}

List<Widget> _buildActivityExpandContent(
  BuildContext context,
  Map<String, dynamic> item,
  List<Map<String, String>> instructionItems,
) {
  final type = item['type'] as String? ?? '';
  final children = <Widget>[];
  if (type == 'activity') {
    final instructions = item['instructions'] as String? ?? '';
    if (instructions.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('activityInstructions'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(instructions, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ));
    }
  } else if (type == 'game') {
    final rules = item['gameRules'] as String? ?? item['rules'] as String? ?? '';
    if (rules.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('gameRules'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(rules, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ));
    }
  } else if (type == 'quiz') {
    final quizMode = item['quizMode'] as String? ?? 'manual';
    final quizLink = item['quizFileOrLink'] as String?;
    if (quizLink != null && quizLink.isNotEmpty) {
      final isUrl = quizLink.startsWith('http://') || quizLink.startsWith('https://');
      children.add(_activityDocTile(context, {'type': isUrl ? 'link' : 'file', 'content': quizLink}));
    }
    final rawQs = item['questions'];
    if (quizMode == 'manual' && rawQs is List) {
      for (var i = 0; i < rawQs.length; i++) {
        final raw = rawQs[i];
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final qText = m['question']?.toString() ?? '';
        final opts = m['options'];
        final ci = (m['correctIndex'] as int?) ?? 0;
        final lines = <String>[];
        if (opts is List) {
          for (var j = 0; j < opts.length; j++) {
            final mark = j == ci ? '✓ ' : '  ';
            lines.add('$mark${opts[j]}');
          }
        }
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('questionText')} ${i + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (qText.isNotEmpty)
                  Text(qText, style: Theme.of(context).textTheme.bodyMedium),
                if (lines.isNotEmpty)
                  Text(
                    lines.join('\n'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      }
    }
  }
  if (instructionItems.isNotEmpty) {
    if (children.isNotEmpty) children.add(const Divider(height: 1));
    children.addAll(instructionItems.map((doc) => _activityDocTile(context, doc)));
  }
  if (children.isEmpty) {
    children.add(Padding(
      padding: const EdgeInsets.all(16),
      child: Text(context.tr('noDocuments'), style: Theme.of(context).textTheme.bodySmall),
    ));
  }
  return children;
}

Widget _activityDocTile(BuildContext context, Map<String, String> doc) {
  final type = doc['type'] ?? 'text';
  final content = doc['content'] ?? '';
  IconData icon = Icons.text_fields;
  if (type == 'file') icon = Icons.insert_drive_file;
  else if (type == 'video') icon = Icons.video_file;
  else if (type == 'audio') icon = Icons.audiotrack;
  else if (type == 'link') icon = Icons.link;
  final isUrl = content.startsWith('http://') || content.startsWith('https://');
  return ListTile(
    dense: true,
    leading: Icon(icon, size: 20),
    title: Text(content.length > 60 ? '${content.substring(0, 60)}...' : content, maxLines: 2, overflow: TextOverflow.ellipsis),
    onTap: isUrl
        ? () async {
            final uri = Uri.tryParse(content);
            if (uri != null) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
            }
          }
        : null,
  );
}

class _TopicTile extends StatefulWidget {
  const _TopicTile({
    required this.topic,
    required this.courseName,
    required this.unitName,
  });

  final dynamic topic; // CourseStructureItem
  final String courseName;
  final String unitName;

  @override
  State<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<_TopicTile> {
  final Map<String, bool> _downloadedCache = <String, bool>{};
  final Set<String> _downloadingLinks = <String>{};

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'link': return Icons.link;
      case 'pdf': return Icons.picture_as_pdf;
      case 'word': return Icons.description;
      case 'video': return Icons.video_file;
      case 'audio': return Icons.audiotrack;
      case 'image': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Future<bool> _isLinkDownloaded(String url, String topicTitle) async {
    if (_downloadedCache.containsKey(url)) {
      return _downloadedCache[url]!;
    }
    final downloaded = await CourseFileStorageService.hasDownloadedLink(
      url: url,
      courseName: widget.courseName,
      unitName: widget.unitName,
      topicName: topicTitle,
    );
    _downloadedCache[url] = downloaded;
    return downloaded;
  }

  Future<void> _downloadLink(String url, String topicTitle) async {
    if (_downloadingLinks.contains(url)) return;
    setState(() => _downloadingLinks.add(url));
    try {
      await CourseFileStorageService.downloadLinkToTopicFiles(
        url: url,
        courseName: widget.courseName,
        unitName: widget.unitName,
        topicName: topicTitle,
      );
      _downloadedCache[url] = true;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(content: Text(context.tr('courseLinkDownloadSuccess'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('courseLinkDownloadFailed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingLinks.remove(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topic as CourseStructureItem;
    if (t.contents.isEmpty) {
      return ListTile(
        leading: const Icon(Icons.topic, size: 20),
        title: Text(t.title),
      );
    }
    return ExpansionTile(
      leading: const Icon(Icons.topic, size: 20),
      title: Text(t.title),
      children: t.contents.map((c) {
        final url = c.data;
        final isUrl = url != null && (url.startsWith('http://') || url.startsWith('https://'));
        return ListTile(
          dense: true,
          leading: Icon(_iconForType(c.type), size: 18),
          title: Text(c.title.isNotEmpty ? c.title : (url ?? '-'), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: isUrl ? Text(url, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)) : null,
          trailing: isUrl
              ? FutureBuilder<bool>(
                  future: _isLinkDownloaded(url, t.title),
                  builder: (context, snapshot) {
                    final isDownloaded = snapshot.data ?? false;
                    final isDownloading = _downloadingLinks.contains(url);
                    return TextButton(
                      onPressed: isDownloading
                          ? null
                          : () => _downloadLink(url, t.title),
                      child: Text(
                        isDownloading
                            ? context.tr('courseDownloading')
                            : (isDownloaded
                                  ? context.tr('courseDownloadAgain')
                                  : context.tr('courseDownload')),
                      ),
                    );
                  },
                )
              : null,
          onTap: url != null && url.isNotEmpty
              ? () async {
                  if (isUrl) {
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } else {
                    final resolvedPath = await CourseFileStorageService
                        .resolvePath(url);
                    final file = File(resolvedPath);
                    if (await file.exists()) {
                      await OpenFile.open(resolvedPath);
                    }
                  }
                }
              : null,
        );
      }).toList(),
    );
  }
}

/// Kurs detay ekranı - ders planları listesi
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppProvider>().repo;
    final lessons = repo
        .getLessonsByDate(DateTime.now())
        .where((l) =>
            l.classId == course.classId &&
            l.subject == course.effectiveCategory)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(course.displayName),
        actions: [
          const AppBarActions(),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: context.tr('edit'),
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => CourseWizardController.editing(course),
                    child: const CourseWizardScreen(),
                  ),
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'share') {
                final text = StringBuffer();
                text.writeln('${course.displayName}');
                text.writeln('${context.tr('coursePurpose')}: ${course.purpose ?? '-'}');
                if (course.outcomes.isNotEmpty) {
                  text.writeln('${context.tr('outcomes')}:');
                  for (final o in course.outcomes) {
                    text.writeln('• ${o.text}');
                  }
                }
                await Share.share(text.toString(), subject: course.displayName);
              } else if (v == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.tr('deleteCourse')),
                    content: Text(
                      '${course.displayName} - ${context.tr('deleteCourseConfirm')}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.tr('cancel')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                        ),
                        child: Text(context.tr('delete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await context.read<AppProvider>().repo.deleteCourse(course.id);
                  if (context.mounted) Navigator.pop(context, true);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text(context.tr('shareReport')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(context.tr('deleteCourse'), style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (course.purpose != null && course.purpose!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('coursePurpose'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.purpose!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (course.outcomes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.tr('outcomes'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...course.outcomes.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.flag, size: 20),
                        title: Text(o.text),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
            ],
            if (course.structure.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.tr('courseStructure'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...course.structure.map((u) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.folder),
                        title: Text(u.title),
                        subtitle: u.estimatedMinutes > 0
                            ? Text('${_fmtHours(u.estimatedMinutes)} ${context.tr('hoursAbbr')}')
                            : null,
                        children: u.children.isEmpty
                            ? []
                            : u.children
                                .map(
                                  (t) => _TopicTile(
                                    topic: t,
                                    courseName: course.displayName,
                                    unitName: u.title,
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
            ],
            if (course.postLessonActivities.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.tr('step6Title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              ...course.postLessonActivities.map((item) {
                final type = item['type'] as String? ?? '';
                final title = item['name'] as String? ?? item['title'] as String? ?? '-';
                final rawItems = item['instructionItems'];
                final instructionItems = <Map<String, String>>[];
                if (rawItems is List) {
                  for (final x in rawItems) {
                    if (x is Map) {
                      final m = Map<String, dynamic>.from(x);
                      final t = m['type']?.toString() ?? 'text';
                      final c = m['content']?.toString() ?? m['data']?.toString() ?? '';
                      instructionItems.add({'type': t, 'content': c});
                    }
                  }
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    child: ExpansionTile(
                      leading: Icon(_activityIconForType(type)),
                      title: Text('$title ($type)'),
                      children: _buildActivityExpandContent(context, item, instructionItems),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('todayLessons'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            lessons.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('noLessonsForCourse'),
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('addFromPlans'),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: lessons
                        .map((l) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Card(
                                child: ListTile(
                                  leading: Icon(
                                    l.completed
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: l.completed ? Colors.green : null,
                                  ),
                                  title: Text(l.topic),
                                  subtitle: Text(l.notes.isNotEmpty ? l.notes : '-'),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
