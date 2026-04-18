import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../core/utils/app_provider.dart';

/// ADDITIVE: Compact daily summary - today's lessons count, classes.
/// Does not affect layout when disabled.
class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.homeDailySummary) return const SizedBox.shrink();

    final repo = context.read<AppProvider>().repo;
    final scheduleItems = repo.getTodaysScheduleFromWeekly();
    final lessons = repo.getLessonsByDate(DateTime.now());

    final int lessonCount;
    final Set<String> classes = {};
    if (scheduleItems.isNotEmpty) {
      lessonCount = scheduleItems.length;
      for (final item in scheduleItems) {
        classes.add(item.classId);
      }
    } else {
      lessonCount = lessons.length;
      for (final l in lessons) {
        classes.add(l.classId);
      }
    }

    if (lessonCount == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                lessonCount == 1
                    ? '${context.tr('todayLessons')}: 1 ${context.tr('lesson')}'
                    : '${context.tr('todayLessons')}: $lessonCount ${context.tr('lessons')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (classes.isNotEmpty)
              Text(
                '${classes.length} ${context.tr('classesLabel')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
