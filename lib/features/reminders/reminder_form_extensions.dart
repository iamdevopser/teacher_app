import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../core/utils/app_provider.dart';

/// ADDITIVE: Extra form fields for reminders (priority, recurring, link).
/// Shown only when feature flags are enabled.
List<Widget> buildReminderExtensionFields(
  BuildContext context,
  StateSetter setState, {
  required int? priority,
  required void Function(int?) onPriorityChanged,
  required String? recurringRule,
  required void Function(String?) onRecurringChanged,
  required String? linkedEntityType,
  required String? linkedEntityId,
  required void Function(String?, String?) onLinkChanged,
}) {
  if (!FeatureFlags.remindersRecurring &&
      !FeatureFlags.remindersPriority &&
      !FeatureFlags.remindersLinkToEntity) {
    return [];
  }

  final fields = <Widget>[];

  if (FeatureFlags.remindersPriority) {
    fields.addAll([
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        value: priority ?? 1,
        decoration: InputDecoration(labelText: context.tr('reminderPriority')),
        items: [
          DropdownMenuItem(value: 0, child: Text(context.tr('reminderPriorityLow'))),
          DropdownMenuItem(value: 1, child: Text(context.tr('reminderPriorityMedium'))),
          DropdownMenuItem(value: 2, child: Text(context.tr('reminderPriorityHigh'))),
        ],
        onChanged: (v) {
          onPriorityChanged(v ?? 1);
          setState(() {});
        },
      ),
    ]);
  }

  if (FeatureFlags.remindersRecurring) {
    final rules = ['', 'daily', 'weekly', 'monthly', 'yearly'];
    String ruleLabel(String r) {
      if (r.isEmpty) return context.tr('reminderRecurringNone');
      switch (r) {
        case 'daily': return context.tr('reminderRecurringDaily');
        case 'weekly': return context.tr('reminderRecurringWeekly');
        case 'monthly': return context.tr('reminderRecurringMonthly');
        case 'yearly': return context.tr('reminderRecurringYearly');
        default: return r;
      }
    }
    fields.addAll([
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: recurringRule ?? '',
        decoration: InputDecoration(labelText: context.tr('reminderRecurring')),
        items: rules.map((r) => DropdownMenuItem(value: r, child: Text(ruleLabel(r)))).toList(),
        onChanged: (v) => onRecurringChanged(v?.isEmpty == true ? null : v),
      ),
    ]);
  }

  if (FeatureFlags.remindersLinkToEntity) {
    final repo = context.read<AppProvider>().repo;
    final courses = repo.getCourses();
    fields.addAll([
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: linkedEntityType ?? '',
        decoration: InputDecoration(labelText: context.tr('reminderLinkTo')),
        items: [
          DropdownMenuItem(value: '', child: Text(context.tr('reminderRecurringNone'))),
          DropdownMenuItem(value: 'course', child: Text(context.tr('reminderLinkCourse'))),
          DropdownMenuItem(value: 'dailyPlan', child: Text(context.tr('reminderLinkDailyPlan'))),
          DropdownMenuItem(value: 'committeeTask', child: Text(context.tr('reminderLinkCommitteeTask'))),
        ],
        onChanged: (v) {
          onLinkChanged(v?.isEmpty == true ? null : v, null);
          setState(() {});
        },
      ),
      if (linkedEntityType == 'course' && courses.isNotEmpty) ...[
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: linkedEntityId ?? courses.first.id,
          decoration: InputDecoration(labelText: context.tr('courses')),
          items: courses
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            onLinkChanged(linkedEntityType, v);
            setState(() {});
          },
        ),
      ],
    ]);
  }

  return fields;
}
