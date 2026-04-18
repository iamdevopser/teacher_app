import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/app_provider.dart';
import '../main_shell/main_shell_screen.dart';
import '../reminders/reminders_screen.dart';
import 'home_enhancements/daily_summary_card.dart';
import 'home_enhancements/quick_actions_card.dart';
import 'home_enhancements/recent_items_card.dart';
import 'home_enhancements/daily_tasks_card.dart';
import 'home_enhancements/daily_lesson_notes_card.dart';
import 'home_enhancements/collapsible_section.dart';

/// Main dashboard with today's lessons and guidance info
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _dateStr;
  late String _timeStr;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateDateTime();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSideBySideLayout(BuildContext context, dynamic profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateTimeDisplay(dateStr: _dateStr, timeStr: _timeStr),
              const SizedBox(height: 16),
              if (profile != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${profile.teacherName} • ${profile.schoolName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              if (profile != null) const SizedBox(height: 16),
              Text(
                '${context.tr('todayLessons')} (${context.tr('weekDay${DateTime.now().weekday - 1}')}, $_dateStr)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const _TodayLessonsList(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _rightSideSections(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _rightSideSections(
    BuildContext context, {
    bool constrained = true,
  }) {
    Widget wrap(Widget child) => constrained
        ? ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
            child: child,
          )
        : child;

    final sections = <Widget>[];
    if (FeatureFlags.homeQuickActions) {
      sections.add(
        wrap(
          FeatureFlags.homeCollapsibleSections
              ? CollapsibleSection(
                  sectionId: 'quick_actions',
                  title: context.tr('quickActions'),
                  child: const QuickActionsCard(showTitle: false),
                )
              : const QuickActionsCard(),
        ),
      );
    }
    if (FeatureFlags.homeRecentItems &&
        (context.read<AppProvider>().repo.getLastSelectedCourseId() != null ||
            context.read<AppProvider>().repo.getLastOpenedDocument() != null)) {
      sections.add(
        wrap(
          FeatureFlags.homeCollapsibleSections
              ? CollapsibleSection(
                  sectionId: 'recent_items',
                  title: context.tr('recentItems'),
                  child: const RecentItemsCard(showTitle: false),
                )
              : const RecentItemsCard(),
        ),
      );
    }
    if (FeatureFlags.homeDailyTasks) {
      sections.add(
        wrap(
          FeatureFlags.homeCollapsibleSections
              ? CollapsibleSection(
                  sectionId: 'daily_tasks',
                  title: context.tr('dailyTasks'),
                  child: const DailyTasksCard(showTitle: false),
                )
              : const DailyTasksCard(),
        ),
      );
    }
    if (FeatureFlags.homeDailyLessonNotes) {
      sections.add(
        wrap(
          FeatureFlags.homeCollapsibleSections
              ? CollapsibleSection(
                  sectionId: 'daily_lesson_notes',
                  title: context.tr('dailyLessonNotes'),
                  child: const DailyLessonNotesCard(showTitle: false),
                )
              : const DailyLessonNotesCard(),
        ),
      );
    }
    sections.add(
      wrap(
        Card(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('guidance'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('guidanceDescription'),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => MainShellScope.of(context)?.onSwitchTo(4),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(context.tr('guidance')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    sections.add(
      wrap(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('upcomingReminders'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RemindersScreen()),
                  ),
                  child: Text(context.tr('reminders')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _UpcomingRemindersList(),
          ],
        ),
      ),
    );
    return sections;
  }

  Widget _buildStackedLayout(BuildContext context, dynamic profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateTimeDisplay(dateStr: _dateStr, timeStr: _timeStr),
        const SizedBox(height: 16),
        const DailySummaryCard(),
        const SizedBox(height: 16),
        if (profile != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${profile.teacherName} • ${profile.schoolName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        if (profile != null) const SizedBox(height: 16),
        Text(
          '${context.tr('todayLessons')} (${context.tr('weekDay${DateTime.now().weekday - 1}')}, $_dateStr)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const _TodayLessonsList(),
        const SizedBox(height: 24),
        ..._rightSideSections(context, constrained: false),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final profile = context.watch<AppProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home')),
        actions: const [AppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AppProvider>().refresh();
          _updateDateTime();
          setState(() {});
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactDevice =
                MediaQuery.sizeOf(context).shortestSide < 600;
            final useSideBySide =
                !isCompactDevice && constraints.maxWidth >= 600;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: useSideBySide
                  ? _buildSideBySideLayout(context, profile)
                  : _buildStackedLayout(context, profile),
            );
          },
        ),
      ),
    );
  }
}

class _DateTimeDisplay extends StatelessWidget {
  const _DateTimeDisplay({required this.dateStr, required this.timeStr});

  final String dateStr;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayLessonsList extends StatelessWidget {
  const _TodayLessonsList();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppProvider>().repo;
    final lessons = repo.getLessonsByDate(DateTime.now());
    final scheduleItems = repo.getTodaysScheduleFromWeekly();

    // Önce haftalık programdan bugünün derslerini göster
    if (scheduleItems.isNotEmpty) {
      final courses = repo.getCourses();
      final currentLesson = AppConstants.getCurrentLessonIndex();
      return Card(
        child: Column(
          children: scheduleItems.map((item) {
            final matching = courses.where((c) {
              final ids = c.classId
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty);
              return ids.contains(item.classId);
            }).toList();
            final course = matching.isNotEmpty ? matching.first : null;
            final cat = course?.effectiveCategory ?? '';
            final title = cat.isNotEmpty
                ? '${item.classId} - $cat'
                : item.classId;
            final isCurrentLesson =
                currentLesson > 0 && item.hour == currentLesson;
            final timeStr = item.hour <= AppConstants.lessonCount
                ? AppConstants.formatLessonTime(item.hour - 1)
                : '';
            return ListTile(
              tileColor: isCurrentLesson
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : null,
              leading: Icon(
                Icons.menu_book,
                color: isCurrentLesson
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                title,
                style: isCurrentLesson
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              subtitle: Text(
                timeStr.isNotEmpty
                    ? '${item.hour}. ${context.tr('lesson')} ($timeStr)'
                    : '${item.hour}. ${context.tr('lesson')}',
              ),
            );
          }).toList(),
        ),
      );
    }

    // Haftalık program boşsa günlük plan kayıtlarından (Lesson) göster
    if (lessons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(context.tr('noLessonsToday'))),
        ),
      );
    }

    return Card(
      child: Column(
        children: lessons.map((l) {
          return ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text('${l.classId} - ${l.subject}'),
            subtitle: Text(l.topic),
            trailing: Icon(
              l.completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: l.completed ? Colors.green : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UpcomingRemindersList extends StatelessWidget {
  const _UpcomingRemindersList();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppProvider>().repo;
    final reminders = repo.getUpcomingReminders(limit: 5);

    if (reminders.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(context.tr('noReminders'))),
        ),
      );
    }

    return Card(
      child: Column(
        children: reminders.map((r) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(r.title),
            subtitle: Text(
              '${r.dateTime.day}/${r.dateTime.month} ${r.dateTime.hour}:${r.dateTime.minute.toString().padLeft(2, '0')}',
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) async {
                if (v == 'edit') {
                  showEditReminder(context, r);
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(context.tr('delete')),
                      content: Text(
                        '${r.title}\n${context.tr('deleteReminderConfirm')}',
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
                  if (ok == true) {
                    await context.read<AppProvider>().repo.deleteReminder(r.id);
                    context.read<AppProvider>().refresh();
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr('edit')),
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
          );
        }).toList(),
      ),
    );
  }
}
