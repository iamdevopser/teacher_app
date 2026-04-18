import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/course.dart';
import '../../data/models/course_models.dart';
import '../../data/services/course_file_storage_service.dart';

/// Kurs önizleme ekranı - ders anlatırken kullanılacak formatta
class CoursePreviewScreen extends StatefulWidget {
  const CoursePreviewScreen({required this.course, super.key});

  final Course course;

  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen> {
  int _pageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _fmtHours(int minutes) {
    final h = minutes / 60;
    return h == h.truncateToDouble() ? '${h.toInt()}' : h.toString();
  }

  List<Widget> _buildPages(BuildContext context) {
    final course = widget.course;
    final pages = <Widget>[];

    pages.add(_PreviewPage(
      title: course.displayName,
      subtitle: '${course.effectiveCategory} • ${course.classId}',
      content: course.purpose ?? context.tr('purposeNotSpecified'),
      icon: Icons.school,
    ));

    if (course.outcomes.isNotEmpty) {
      for (final o in course.outcomes) {
        if (o.text.isNotEmpty) {
          pages.add(_PreviewPage(
            title: context.tr('outcome'),
            content: o.text,
            icon: Icons.flag,
          ));
        }
      }
    }

    for (final unit in course.structure) {
      pages.add(_PreviewPage(
        courseName: course.displayName,
        title: unit.title,
        subtitle: unit.estimatedMinutes > 0 ? '${_fmtHours(unit.estimatedMinutes)} ${context.tr('hoursAbbr')}' : null,
        content: unit.description ?? '',
        icon: Icons.folder,
        unitChildren: unit.children.isNotEmpty ? unit.children : null,
      ));
    }

    if (pages.isEmpty) {
      pages.add(_PreviewPage(
        title: course.displayName,
        content: context.tr('noContentYet'),
        icon: Icons.info_outline,
      ));
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.course.displayName),
        actions: [
          const AppBarActions(),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit),
            tooltip: context.tr('close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (ctx) {
                final pages = _buildPages(ctx);
                return PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  itemBuilder: (_, i) => pages[i],
                );
              },
            ),
          ),
          Builder(
            builder: (ctx) {
              final pages = _buildPages(ctx);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _pageIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                    Text(
                      '${_pageIndex + 1} / ${pages.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _pageIndex < pages.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({
    this.courseName,
    required this.title,
    required this.content,
    this.subtitle,
    required this.icon,
    this.unitChildren,
  });

  final String? courseName;
  final String title;
  final String content;
  final String? subtitle;
  final IconData icon;
  final List<CourseStructureItem>? unitChildren;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: unitChildren != null
                    ? _buildUnitContent(context)
                    : SelectableText(
                        content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontSize: 18,
                            ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitContent(BuildContext context) {
    final children = <Widget>[];
    if (content.isNotEmpty) {
      children.add(SelectableText(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 18,
            ),
      ));
      children.add(const SizedBox(height: 20));
    }
    children.add(Text(
      context.tr('topics'),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    ));
    children.add(const SizedBox(height: 12));
    for (final t in unitChildren!) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ${t.title}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18)),
            if (t.contents.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: t.contents
                    .map(
                      (c) => _buildContentChip(
                        context,
                        c,
                        topicTitle: t.title,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _buildContentChip(
    BuildContext context,
    LessonContentItem c, {
    required String topicTitle,
  }) {
    final url = c.data;
    final isUrl = url != null && (url.startsWith('http://') || url.startsWith('https://'));
    final label = c.title.isNotEmpty ? c.title : (isUrl ? context.tr('link') : (url ?? '-'));
    if (isUrl) {
      return Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final uri = Uri.tryParse(url);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link, size: 22, color: Theme.of(context).colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                const SizedBox(width: 8),
                FutureBuilder<bool>(
                  future: CourseFileStorageService.hasDownloadedLink(
                    url: url!,
                    courseName: courseName ?? 'course',
                    unitName: title,
                    topicName: topicTitle,
                  ),
                  builder: (context, snapshot) {
                    final downloaded = snapshot.data ?? false;
                    return OutlinedButton(
                      onPressed: () async {
                        try {
                          await CourseFileStorageService.downloadLinkToTopicFiles(
                            url: url,
                            courseName: courseName ?? 'course',
                            unitName: title,
                            topicName: topicTitle,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('courseLinkDownloadSuccess'),
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('courseLinkDownloadFailed'),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        downloaded
                            ? context.tr('courseDownloadAgain')
                            : context.tr('courseDownload'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: url != null && url.isNotEmpty
            ? () async {
                final resolvedPath = await CourseFileStorageService.resolvePath(
                  url,
                );
                final file = File(resolvedPath);
                if (await file.exists()) {
                  await OpenFile.open(resolvedPath);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, size: 22, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}
