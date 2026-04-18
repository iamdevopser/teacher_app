import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/repositories/app_repository.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/course.dart';
import '../../data/models/course_models.dart';
import 'course_color_dialog.dart';
import 'course_color_dialog.dart';
import 'course_detail_screen.dart';
import 'course_wizard_controller.dart';
import 'course_wizard_screen.dart';
import '../lesson_planner/planner_split_view.dart';

/// Kurslar ekranı - kurs listesi, oluşturma ve detay
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _searchController = TextEditingController();
  String? _filterClass;
  String? _filterSubject;
  bool _showArchived = false;
  Course? _selectedCourse;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filterCourses(List<Course> courses) {
    var result = courses;
    if (!_showArchived && FeatureFlags.courseArchive) {
      result = result.where((c) => c.status != CourseStatus.archived).toList();
    }
    if (FeatureFlags.courseSearchFilter) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        result = result
            .where(
              (c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.subject.toLowerCase().contains(q) ||
                  c.classId.toLowerCase().contains(q),
            )
            .toList();
      }
      if (_filterClass != null && _filterClass!.isNotEmpty) {
        result = result.where((c) => c.classId == _filterClass).toList();
      }
      if (_filterSubject != null && _filterSubject!.isNotEmpty) {
        result = result.where((c) => c.subject == _filterSubject).toList();
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.read<AppProvider>().repo;
    final profile = context.watch<AppProvider>().profile;
    final courses = repo.getCourses();
    final filtered = _filterCourses(courses);
    final localeCode = context
        .read<LocaleProvider>()
        .effectiveLocale
        .languageCode;
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    if (_selectedCourse != null) {
      final selectedId = _selectedCourse!.id;
      try {
        _selectedCourse = courses.firstWhere(
          (course) => course.id == selectedId,
        );
      } catch (_) {
        _selectedCourse = filtered.isNotEmpty ? filtered.first : null;
      }
    }

    final allClasses =
        courses
            .map((c) => c.classId)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final allSubjects =
        courses
            .map((c) => c.subject)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('myCourses')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openCourseWizard(context),
          ),
          const AppBarActions(),
        ],
      ),
      body: courses.isEmpty
          ? _buildEmptyState(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (FeatureFlags.courseSearchFilter)
                  _buildSearchFilter(context, allClasses, allSubjects),
                Expanded(
                  child: PlannerSplitView(
                    emptyState: filtered.isNotEmpty
                        ? _buildSidebarPlaceholder(context)
                        : null,
                    onClosePanel: _selectedCourse != null
                        ? () => setState(() => _selectedCourse = null)
                        : null,
                    sidePanel: _selectedCourse != null
                        ? _buildCoursePanel(
                            context,
                            _selectedCourse!,
                            repo,
                            profile?.schoolName ?? '',
                            localeCode,
                          )
                        : null,
                    content: filtered.isEmpty
                        ? Center(
                            child: Text(
                              courses.isEmpty
                                  ? context.tr('noCoursesYet')
                                  : context.tr('courseNoMatching'),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final course = filtered[i];
                              final isSelected =
                                  _selectedCourse?.id == course.id;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: isSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.35)
                                    : null,
                                child: ListTile(
                                  leading: _buildCourseLeading(
                                    context,
                                    course,
                                    repo,
                                  ),
                                  title: Text(course.displayName),
                                  subtitle: Text(
                                    '${profile?.schoolName ?? ''} • ${course.status.label(localeCode)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  trailing: isWide
                                      ? const Icon(Icons.chevron_right)
                                      : PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (v) => _onCourseAction(
                                            context,
                                            v,
                                            course,
                                            repo,
                                          ),
                                          itemBuilder: (_) =>
                                              _buildCourseMenuItems(
                                                context,
                                                course,
                                              ),
                                        ),
                                  onTap: () async {
                                    if (course.status == CourseStatus.archived)
                                      return;
                                    if (isWide) {
                                      setState(() => _selectedCourse = course);
                                      return;
                                    }
                                    await _openCourseDetail(context, course);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'courses_add_fab',
        onPressed: () => _openCourseWizard(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchFilter(
    BuildContext context,
    List<String> allClasses,
    List<String> allSubjects,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: context.tr('courseSearchHint'),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterClass,
                  decoration: InputDecoration(
                    labelText: context.tr('courseFilterClass'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...allClasses.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterClass = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filterSubject,
                  decoration: InputDecoration(
                    labelText: context.tr('courseFilterSubject'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('all')),
                    ),
                    ...allSubjects.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterSubject = v),
                ),
              ),
            ],
          ),
          if (FeatureFlags.courseArchive)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => setState(() => _showArchived = !_showArchived),
                icon: Icon(
                  _showArchived ? Icons.visibility_off : Icons.visibility,
                ),
                label: Text(
                  _showArchived
                      ? context.tr('courseHideArchived')
                      : context.tr('courseShowArchived'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseLeading(
    BuildContext context,
    Course course,
    AppRepository repo,
  ) {
    if (!FeatureFlags.courseColorIcon) return const Icon(Icons.class_);
    final meta = repo.getCourseMetadata()[course.id];
    final colorVal = meta?['color'] as int?;
    final color = colorVal != null
        ? Color(colorVal)
        : Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(Icons.menu_book, color: color, size: 24),
    );
  }

  List<PopupMenuItem<String>> _buildCourseMenuItems(
    BuildContext context,
    Course course,
  ) {
    final items = <PopupMenuItem<String>>[];
    if (FeatureFlags.courseDuplication) {
      items.add(
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 8),
              Text(context.tr('courseDuplicate')),
            ],
          ),
        ),
      );
    }
    if (FeatureFlags.courseColorIcon) {
      items.add(
        PopupMenuItem(
          value: 'color',
          child: Row(
            children: [
              const Icon(Icons.palette, size: 20),
              const SizedBox(width: 8),
              Text(context.tr('courseSetColor')),
            ],
          ),
        ),
      );
    }
    if (FeatureFlags.courseArchive) {
      if (course.status == CourseStatus.archived) {
        items.add(
          PopupMenuItem(
            value: 'unarchive',
            child: Row(
              children: [
                const Icon(Icons.unarchive, size: 20),
                const SizedBox(width: 8),
                Text(context.tr('courseUnarchive')),
              ],
            ),
          ),
        );
      } else {
        items.add(
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                const Icon(Icons.archive, size: 20),
                const SizedBox(width: 8),
                Text(context.tr('courseArchive')),
              ],
            ),
          ),
        );
      }
    }
    items.add(
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
    );
    return items;
  }

  Future<void> _onCourseAction(
    BuildContext context,
    String action,
    Course course,
    AppRepository repo,
  ) async {
    switch (action) {
      case 'color':
        final meta = repo.getCourseMetadata()[course.id];
        final colorVal = meta?['color'] as int?;
        final initial = colorVal != null ? Color(colorVal) : null;
        final result = await showDialog<Color?>(
          context: context,
          builder: (_) => CourseColorDialog(
            initialColor: initial,
            onClear: () async {
              await repo.setCourseMetadata(course.id, {});
              if (context.mounted) context.read<AppProvider>().refresh();
            },
          ),
        );
        if (result != null && context.mounted) {
          await repo.setCourseMetadata(course.id, {'color': result.value});
          context.read<AppProvider>().refresh();
        }
        break;
      case 'duplicate':
        final suffix = context.tr('courseDuplicateSuffix');
        await repo.duplicateCourse(course, nameSuffix: suffix);
        if (context.mounted) context.read<AppProvider>().refresh();
        break;
      case 'archive':
        await repo.updateCourse(course.copyWith(status: CourseStatus.archived));
        if (context.mounted) context.read<AppProvider>().refresh();
        break;
      case 'unarchive':
        await repo.updateCourse(course.copyWith(status: CourseStatus.draft));
        if (context.mounted) context.read<AppProvider>().refresh();
        break;
      case 'delete':
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
          await repo.deleteCourse(course.id);
          context.read<AppProvider>().refresh();
        }
        break;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('noCoursesYet'),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('createCourseWizard'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () => _openCourseWizard(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                minimumSize: const Size(220, 56),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('createCourse'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr('selectItemToOpenSidebar'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCoursePanel(
    BuildContext context,
    Course course,
    AppRepository repo,
    String schoolName,
    String localeCode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            course.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('${course.classId} • ${course.subject}'),
          const SizedBox(height: 16),
          _detailRow(context, context.tr('schoolName'), schoolName),
          _detailRow(context, context.tr('subject'), course.subject),
          _detailRow(context, context.tr('classLabel'), course.classId),
          _detailRow(
            context,
            context.tr('courseStatus'),
            course.status.label(localeCode),
          ),
          _detailRow(context, context.tr('purpose'), course.purpose ?? ''),
          _detailRow(
            context,
            context.tr('weeklyHours'),
            course.weeklyHours.toString(),
          ),
          _detailRow(
            context,
            context.tr('totalWeeks'),
            course.totalWeeks.toString(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _openCourseDetail(context, course),
                icon: const Icon(Icons.open_in_new),
                label: Text(context.tr('preview')),
              ),
              if (FeatureFlags.courseDuplication)
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _onCourseAction(context, 'duplicate', course, repo),
                  icon: const Icon(Icons.copy),
                  label: Text(context.tr('courseDuplicate')),
                ),
              if (FeatureFlags.courseColorIcon)
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _onCourseAction(context, 'color', course, repo),
                  icon: const Icon(Icons.palette),
                  label: Text(context.tr('courseSetColor')),
                ),
              if (FeatureFlags.courseArchive)
                FilledButton.tonalIcon(
                  onPressed: () => _onCourseAction(
                    context,
                    course.status == CourseStatus.archived
                        ? 'unarchive'
                        : 'archive',
                    course,
                    repo,
                  ),
                  icon: Icon(
                    course.status == CourseStatus.archived
                        ? Icons.unarchive
                        : Icons.archive,
                  ),
                  label: Text(
                    course.status == CourseStatus.archived
                        ? context.tr('courseUnarchive')
                        : context.tr('courseArchive'),
                  ),
                ),
              FilledButton.tonalIcon(
                onPressed: () =>
                    _onCourseAction(context, 'delete', course, repo),
                icon: const Icon(Icons.delete),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _openCourseWizard(BuildContext context) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CourseWizardController.newDraft(),
          child: const CourseWizardScreen(),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AppProvider>().refresh();
    }
  }

  Future<void> _openCourseDetail(BuildContext context, Course course) async {
    final refresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CourseDetailScreen(course: course)),
    );
    if (refresh == true && context.mounted) {
      context.read<AppProvider>().refresh();
    }
  }
}
