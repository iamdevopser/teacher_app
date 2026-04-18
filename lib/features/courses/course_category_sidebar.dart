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

/// Kurs ekranı sol şeridi: [ExpansionTile] ile «Kategoriler» → kategori → kurslar.
/// Gruplama [Course.category] ile (boş kategori klasörü oluşturulmaz).
class CourseCategorySidebar extends StatelessWidget {
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

  static String _categoryKey(Course c) => c.category.trim();

  @override
  Widget build(BuildContext context) {
    final courses = filteredCourses;
    Widget tree;
    if (courses.isEmpty) {
      tree = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr('courseNoMatching'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      final uncategorized =
          courses.where((c) => _categoryKey(c).isEmpty).toList();
      final byCat = <String, List<Course>>{};
      for (final c in courses) {
        final k = _categoryKey(c);
        if (k.isEmpty) continue;
        byCat.putIfAbsent(k, () => []).add(c);
      }
      final sortedKeys = byCat.keys.toList()..sort();

      tree = ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        children: [
          ExpansionTile(
            key: const PageStorageKey<String>('course_categories_root'),
            initiallyExpanded: true,
            leading: const Icon(Icons.folder),
            title: Text(
              context.tr('courseCategories'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            children: [
              ...uncategorized.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _courseTile(context, c),
                ),
              ),
              ...sortedKeys.map(
                (cat) => ExpansionTile(
                  key: PageStorageKey<String>('course_cat_$cat'),
                  leading: const Icon(Icons.folder),
                  title: Text(
                    cat,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  children: byCat[cat]!
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _courseTile(context, c),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final child = Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: tree,
    );
    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return child;
  }

  Widget _courseTile(BuildContext context, Course course) {
    final isSelected = selectedCourseId == course.id;
    final archived = course.status == CourseStatus.archived;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35)
          : null,
      child: ListTile(
        dense: true,
        leading: leadingBuilder(context, course),
        title: Text(
          course.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitleBuilder(course),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (v) => onMenuAction(v, course),
          itemBuilder: (_) => menuItemsBuilder(context, course),
        ),
        onTap: () async {
          if (archived) return;
          if (isWide) {
            onCourseTap(course);
          } else if (onCourseTapMobile != null) {
            await onCourseTapMobile!(course);
          } else {
            onCourseTap(course);
          }
        },
      ),
    );
  }
}
