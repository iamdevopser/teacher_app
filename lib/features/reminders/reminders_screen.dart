import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/reminder.dart';
import '../../data/repositories/app_repository.dart';
import 'reminder_form_extensions.dart';

/// Reminders: exams, homework, meetings - local notifications only
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.tr('reminders')),
        actions: const [AppBarActions()],
      ),
      body: const _RemindersList(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reminders_add_fab',
        onPressed: () => _showAddReminder(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addReminder')),
      ),
    );
  }
}

void showEditReminder(BuildContext context, Reminder existing) {
  final profile = context.read<AppProvider>().profile;

  ReminderType type = existing.type;
  final titleController = TextEditingController(text: existing.title);
  final descController = TextEditingController(
    text: existing.description ?? '',
  );
  DateTime dateTime = existing.dateTime;
  String? selectedClass = existing.classId;
  int? priority = existing.priority;
  String? recurringRule = existing.recurringRule;
  String? linkedEntityType = existing.linkedEntityType;
  String? linkedEntityId = existing.linkedEntityId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('editReminder'),
                style: Theme.of(ctx2).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReminderType>(
                value: type,
                decoration: InputDecoration(
                  labelText: context.tr('reminderType'),
                ),
                items: ReminderType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeLabel(context, t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => type = v ?? ReminderType.other),
              ),
              ...buildReminderExtensionFields(
                ctx2,
                setState,
                priority: priority,
                onPriorityChanged: (v) => priority = v,
                recurringRule: recurringRule,
                onRecurringChanged: (v) => recurringRule = v,
                linkedEntityType: linkedEntityType,
                linkedEntityId: linkedEntityId,
                onLinkChanged: (t, id) {
                  linkedEntityType = t;
                  linkedEntityId = id;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: context.tr('title')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(labelText: context.tr('notes')),
                maxLines: 2,
              ),
              if (profile != null && profile.classesTaught.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: InputDecoration(
                    labelText: context.tr('classLabel'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('selectClass')),
                    ),
                    ...profile.classesTaught
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ],
                  onChanged: (v) => setState(() => selectedClass = v),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: Text(context.tr('date')),
                subtitle: Text(
                  '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx2,
                    initialDate: dateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay.fromDateTime(dateTime),
                    );
                    if (time != null) {
                      setState(
                        () => dateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final updated = Reminder(
                        id: existing.id,
                        type: type,
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        dateTime: dateTime,
                        classId: selectedClass,
                        notified: existing.notified,
                        createdAt: existing.createdAt,
                        priority: priority,
                        recurringRule: recurringRule,
                        linkedEntityType: linkedEntityType,
                        linkedEntityId: linkedEntityId,
                      );
                      await context.read<AppProvider>().repo.updateReminder(
                        updated,
                      );
                      if (context.mounted) {
                        context.read<AppProvider>().refresh();
                        Navigator.pop(ctx2);
                      }
                    },
                    child: Text(context.tr('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Public entry for showing add reminder (e.g. from Home quick actions).
void showAddReminder(BuildContext context) => _showAddReminder(context);

void _showAddReminder(BuildContext context) {
  final profile = context.read<AppProvider>().profile;

  ReminderType type = ReminderType.other;
  final titleController = TextEditingController();
  final descController = TextEditingController();
  DateTime dateTime = DateTime.now().add(const Duration(hours: 1));
  String? selectedClass;
  int? priority;
  String? recurringRule;
  String? linkedEntityType;
  String? linkedEntityId;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('addReminder'),
                style: Theme.of(ctx2).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReminderType>(
                value: type,
                decoration: InputDecoration(
                  labelText: context.tr('reminderType'),
                ),
                items: ReminderType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeLabel(context, t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => type = v ?? ReminderType.other),
              ),
              ...buildReminderExtensionFields(
                ctx2,
                setState,
                priority: priority,
                onPriorityChanged: (v) => priority = v,
                recurringRule: recurringRule,
                onRecurringChanged: (v) => recurringRule = v,
                linkedEntityType: linkedEntityType,
                linkedEntityId: linkedEntityId,
                onLinkChanged: (t, id) {
                  linkedEntityType = t;
                  linkedEntityId = id;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: context.tr('title')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(labelText: context.tr('notes')),
                maxLines: 2,
              ),
              if (profile != null && profile.classesTaught.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: InputDecoration(
                    labelText: context.tr('classLabel'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr('selectClass')),
                    ),
                    ...profile.classesTaught
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ],
                  onChanged: (v) => setState(() => selectedClass = v),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                title: Text(context.tr('date')),
                subtitle: Text(
                  '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx2,
                    initialDate: dateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: ctx2,
                      initialTime: TimeOfDay.fromDateTime(dateTime),
                    );
                    if (time != null) {
                      setState(
                        () => dateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx2),
                    child: Text(context.tr('cancel')),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final reminder = Reminder(
                        id: AppRepository.generateId(),
                        type: type,
                        title: titleController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        dateTime: dateTime,
                        classId: selectedClass,
                        notified: false,
                        createdAt: DateTime.now(),
                        priority: priority,
                        recurringRule: recurringRule,
                        linkedEntityType: linkedEntityType,
                        linkedEntityId: linkedEntityId,
                      );
                      await context.read<AppProvider>().repo.addReminder(
                        reminder,
                      );
                      if (context.mounted) {
                        context.read<AppProvider>().refresh();
                        Navigator.pop(ctx2);
                      }
                    },
                    child: Text(context.tr('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _typeLabel(BuildContext context, ReminderType t) {
  return context.tr(
    'reminderType${t.name[0].toUpperCase()}${t.name.substring(1)}',
  );
}

class _RemindersList extends StatelessWidget {
  const _RemindersList();

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final reminders = repo.getReminders();
    reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    if (reminders.isEmpty) {
      return Center(child: Text(context.tr('noReminders')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      itemBuilder: (_, i) {
        final r = reminders[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _typeIcon(r.type),
              color: _priorityColor(context, r.priority),
            ),
            title: Row(
              children: [
                Expanded(child: Text(r.title)),
                if (FeatureFlags.remindersPriority &&
                    r.priority != null &&
                    r.priority! > 1)
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                if (FeatureFlags.remindersRecurring &&
                    r.recurringRule != null &&
                    r.recurringRule!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.repeat,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '${r.dateTime.day}/${r.dateTime.month}/${r.dateTime.year} ${r.dateTime.hour}:${r.dateTime.minute.toString().padLeft(2, '0')}'
              '${FeatureFlags.remindersRecurring && r.recurringRule != null && r.recurringRule!.isNotEmpty ? " • ${_recurringLabel(context, r.recurringRule!)}" : ""}',
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
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
                    await repo.deleteReminder(r.id);
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
          ),
        );
      },
    );
  }

  IconData _typeIcon(ReminderType t) {
    switch (t) {
      case ReminderType.exam:
        return Icons.quiz;
      case ReminderType.homework:
        return Icons.assignment;
      case ReminderType.meeting:
        return Icons.groups;
      case ReminderType.other:
        return Icons.notifications;
    }
  }

  Color _priorityColor(BuildContext context, int? p) {
    if (p == null) return Theme.of(context).colorScheme.primary;
    return p >= 2
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
  }

  String _recurringLabel(BuildContext context, String rule) {
    switch (rule) {
      case 'daily':
        return context.tr('reminderRecurringDaily');
      case 'weekly':
        return context.tr('reminderRecurringWeekly');
      case 'monthly':
        return context.tr('reminderRecurringMonthly');
      case 'yearly':
        return context.tr('reminderRecurringYearly');
      default:
        return rule;
    }
  }
}
