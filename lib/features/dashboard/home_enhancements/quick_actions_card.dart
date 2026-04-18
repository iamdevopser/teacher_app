import 'package:flutter/material.dart';
import '../../main_shell/main_shell_screen.dart';
import '../../reminders/reminders_screen.dart';
import '../../../core/localization/tr_extension.dart';

/// ADDITIVE: Quick actions - Add Reminder, Daily Plan, Teach.
/// Wrapped in feature flag; does not affect existing layout when disabled.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                context.tr('quickActions'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => showAddReminder(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_alarm, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr('addReminder')),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => MainShellScope.of(context)?.onSwitchTo(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.today, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr('dailyPlan')),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => MainShellScope.of(context)?.onSwitchTo(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, size: 20),
                      const SizedBox(width: 8),
                      Text(context.tr('myLessons')),
                    ],
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
