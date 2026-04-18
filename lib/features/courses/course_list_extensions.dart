import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../core/utils/app_provider.dart';
import 'course_detail_screen.dart';

/// ADDITIVE: Search, filter, archive toggle for courses.
/// Wraps the course list when flags are enabled.
class CourseListWithFilters extends StatefulWidget {
  const CourseListWithFilters({
    super.key,
    required this.courses,
    required this.profile,
    required this.localeCode,
    required this.onRefresh,
    required this.onDelete,
    required this.emptyWidget,
  });

  final List<Course> courses;
  final dynamic profile;
  final String localeCode;
  final VoidCallback onRefresh;
  final Future<void> Function(Course course) onDelete;
  final Widget emptyWidget;

  @override
  State<CourseListWithFilters> createState() => _CourseListWithFiltersState();
}

class _CourseListWithFiltersState extends State<CourseListWithFilters> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterClass;
  String? _filterSubject;
  bool _showArchived = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> get _filteredCourses {
    var list = widget.courses;
    if (FeatureFlags.courseArchive && !_showArchived) {
      list = list.where((c) => c.status != CourseStatus.archived).toList();
    }
    if (FeatureFlags.courseSearchFilter && _searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) ||
          c.subject.toLowerCase().contains(q) ||
          c.classId.toLowerCase().contains(q)).toList();
    }
    if (FeatureFlags.courseSearchFilter && _filterClass != null) {
      list = list.where((c) => c.classId == _filterClass).toList();
    }
    if (FeatureFlags.courseSearchFilter && _filterSubject != null) {
      list = list.where((c) => c.subject == _filterSubject).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = FeatureFlags.courseSearchFilter || FeatureFlags.courseArchive;
    if (!hasFilters) {
      return _buildList(context, widget.courses);
    }

    final classes = widget.courses.map((c) => c.classId).where((s) => s.isNotEmpty).toSet().toList()..sort();
    final subjects = widget.courses.map((c) => c.subject).where((s) => s.isNotEmpty).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (FeatureFlags.courseSearchFilter) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: context.tr('search') + '...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              children: [
                if (classes.isNotEmpty)
                  DropdownButton<String>(
                    value: _filterClass,
                    hint: Text(context.tr('classLabel')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('all'))),
                      ...classes.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _filterClass = v),
                  ),
                if (subjects.isNotEmpty)
                  DropdownButton<String>(
                    value: _filterSubject,
                    hint: Text(context.tr('subject')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.tr('all'))),
                      ...subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (v) => setState(() => _filterSubject = v),
                  ),
              ],
            ),
          ),
        ],
        if (FeatureFlags.courseArchive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: CheckboxListTile(
              value: _showArchived,
              onChanged: (v) => setState(() => _showArchived = v ?? false),
              title: Text(context.tr('courseStatusArchived')),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        Expanded(
          child: _filteredCourses.isEmpty
              ? widget.emptyWidget
              : _buildList(context, _filteredCourses),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, List<Course> courses) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, i) {
        final course = courses[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.class_),
            title: Text(course.displayName),
            subtitle: Text(
              '${widget.profile?.schoolName ?? ''} • ${course.status.label(widget.localeCode)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(context.tr('deleteCourse')),
                      content: Text(
                        '${course.displayName}\n${context.tr('deleteCourseConfirm')}',
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
                  if (ok == true && context.mounted) {
                    await widget.onDelete(course);
                  }
                } else if (v == 'archive' && FeatureFlags.courseArchive) {
                  await _toggleArchive(context, course);
                } else if (v == 'duplicate' && FeatureFlags.courseDuplication) {
                  await _duplicateCourse(context, course);
                }
              },
              itemBuilder: (_) => [
                if (FeatureFlags.courseArchive)
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(course.status == CourseStatus.archived ? Icons.unarchive : Icons.archive, size: 20),
                        const SizedBox(width: 8),
                        Text(course.status == CourseStatus.archived ? context.tr('unarchive') : context.tr('archive')),
                      ],
                    ),
                  ),
                if (FeatureFlags.courseDuplication)
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        const Icon(Icons.copy, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('duplicate')),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr('delete')),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () async {
              if (course.status == CourseStatus.archived && !_showArchived) return;
              final refresh = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseDetailScreen(course: course),
                ),
              );
              if (refresh == true && context.mounted) {
                widget.onRefresh();
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleArchive(BuildContext context, Course course) async {
    final newStatus = course.status == CourseStatus.archived ? CourseStatus.active : CourseStatus.archived;
    final updated = course.copyWith(status: newStatus);
    await context.read<AppProvider>().repo.updateCourse(updated);
    if (context.mounted) widget.onRefresh();
  }

  Future<void> _duplicateCourse(BuildContext context, Course course) async {
    final now = DateTime.now();
    final dup = course.copyWith(
      id: AppRepository.generateId(),
      name: '${course.name} (${context.tr('copy')})',
      createdAt: now,
      updatedAt: now,
    );
    await context.read<AppProvider>().repo.addCourse(dup);
    if (context.mounted) widget.onRefresh();
  }
}
