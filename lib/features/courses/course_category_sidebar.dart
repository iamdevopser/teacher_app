import 'package:flutter/material.dart';

import '../../core/localization/tr_extension.dart';
import '../../data/models/course.dart';
import '../../data/models/course_models.dart';

typedef CourseLeadingBuilder = Widget Function(
  BuildContext context,
  Course course,
);

typedef CourseSubtitleBuilder = String Function(Course course);

typedef CourseMenuItemsBuilder = List<PopupMenuItem<String>> Function(
  BuildContext context,
  Course course,
);

/// Kurs ekranı sol şeridi: "Kategoriler" kökü → kategori klasörleri → kurslar.
/// Genişlikte [onCourseTap] ile seçim; dar ekranda [onCourseTapMobile] ile detay rotası.
class CourseCategorySidebar extends StatefulWidget {
  const CourseCategorySidebar({
    super.key,
    required this.filteredCourses,
    this.selectedCourseId,
    required this.onCourseTap,
    this.onCourseTapMobile,
    required this.leadingBuilder,
    required this.subtitleBuilder,
    required this.onMenuAction,
    required this.menuItemsBuilder,
    this.width,
    required this.isWide,
  });

  final List<Course> filteredCourses;
  final String? selectedCourseId;
  final void Function(Course course) onCourseTap;
  final Future<void> Function(Course course)? onCourseTapMobile;
  final CourseLeadingBuilder leadingBuilder;
  final CourseSubtitleBuilder subtitleBuilder;
  final void Function(String action, Course course) onMenuAction;
  final CourseMenuItemsBuilder menuItemsBuilder;
  final double? width;
  final bool isWide;

  @override
  State<CourseCategorySidebar> createState() => _CourseCategorySidebarState();
}

class _CourseCategorySidebarState extends State<CourseCategorySidebar> {
  bool _rootExpanded = true;
  final Set<String> _openCategories = <String>{};

  @override
  Widget build(BuildContext context) {
    final tree = _buildTree(context);
    final child = Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: tree,
    );
    if (widget.width != null) {
      return SizedBox(width: widget.width, child: child);
    }
    return child;
  }

  Widget _buildTree(BuildContext context) {
    final courses = widget.filteredCourses;
    if (courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr('courseNoMatching'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final uncategorized =
        courses.where((c) => c.effectiveCategory.isEmpty).toList();
    final byCat = <String, List<Course>>{};
    for (final c in courses) {
      final k = c.effectiveCategory;
      if (k.isEmpty) continue;
      byCat.putIfAbsent(k, () => []).add(c);
    }
    final sortedKeys = byCat.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      children: [
        _folderHeader(
          context,
          title: context.tr('courseCategories'),
          expanded: _rootExpanded,
          onTap: () => setState(() => _rootExpanded = !_rootExpanded),
        ),
        if (_rootExpanded) ...[
          if (uncategorized.isNotEmpty)
            ...uncategorized.map((c) => _courseTile(context, c, depth: 1)),
          ...sortedKeys.map(
            (cat) => _categoryBlock(context, cat, byCat[cat]!),
          ),
        ],
      ],
    );
  }

  Widget _folderHeader(
    BuildContext context, {
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(expanded ? Icons.folder_open : Icons.folder, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _categoryBlock(
    BuildContext context,
    String category,
    List<Course> list,
  ) {
    final open = _openCategories.contains(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: InkWell(
            onTap: () => setState(() {
              if (open) {
                _openCategories.remove(category);
              } else {
                _openCategories.add(category);
              }
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Icon(open ? Icons.folder_open : Icons.folder, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),
        ),
        if (open)
          ...list.map((c) => _courseTile(context, c, depth: 2)),
      ],
    );
  }

  Widget _courseTile(BuildContext context, Course course, {required int depth}) {
    final isSelected = widget.selectedCourseId == course.id;
    final archived = course.status == CourseStatus.archived;
    final pad = 8.0 + depth * 12.0;
    return Padding(
      padding: EdgeInsets.only(left: pad),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        color: isSelected
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.35)
            : null,
        child: ListTile(
          dense: true,
          leading: widget.leadingBuilder(context, course),
          title: Text(
            course.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            widget.subtitleBuilder(course),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) => widget.onMenuAction(v, course),
            itemBuilder: (_) => widget.menuItemsBuilder(context, course),
          ),
          onTap: () async {
            if (archived) return;
            if (widget.isWide) {
              widget.onCourseTap(course);
            } else if (widget.onCourseTapMobile != null) {
              await widget.onCourseTapMobile!(course);
            } else {
              widget.onCourseTap(course);
            }
          },
        ),
      ),
    );
  }
}
