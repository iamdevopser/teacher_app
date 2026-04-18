import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/utils/app_provider.dart';
import '../../../core/constants/app_constants.dart';

/// ADDITIVE: Checklist-style daily tasks.
/// Stored separately; does not affect existing data.
class DailyTasksCard extends StatefulWidget {
  const DailyTasksCard({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<DailyTasksCard> createState() => _DailyTasksCardState();
}

class _DailyTasksCardState extends State<DailyTasksCard> {
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _tasks = context.read<AppProvider>().repo.getDailyTasks();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _tasks = _tasks.where((t) => (t['date'] as String? ?? '').startsWith(today)).toList();
  }

  Future<void> _saveTasks() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final all = context.read<AppProvider>().repo.getDailyTasks();
    final other = all.where((t) => !(t['date'] as String? ?? '').startsWith(today)).toList();
    await context.read<AppProvider>().repo.saveDailyTasks([...other, ..._tasks]);
    context.read<AppProvider>().refresh();
  }

  void _addTask() {
    setState(() {
      _tasks.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': '',
        'done': false,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      });
    });
    _saveTasks();
  }

  void _toggleTask(int i) {
    setState(() {
      _tasks[i]['done'] = !(_tasks[i]['done'] as bool? ?? false);
      _saveTasks();
    });
  }

  void _updateTask(int i, String text) {
    setState(() {
      _tasks[i]['text'] = text;
    });
    _saveTasks();
  }

  void _removeTask(int i) {
    setState(() {
      _tasks.removeAt(i);
      _saveTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.homeDailyTasks) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.showTitle)
                  Text(
                    context.tr('dailyTasks'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                  tooltip: context.tr('add'),
                ),
              ],
            ),
            if (_tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.tr('noDailyTasks'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ...List.generate(_tasks.length, (i) {
                final t = _tasks[i];
                final done = t['done'] as bool? ?? false;
                final text = t['text'] as String? ?? '';
                return ListTile(
                  dense: true,
                  leading: Checkbox(
                    value: done,
                    onChanged: (_) => _toggleTask(i),
                  ),
                  title: Text(
                    text.isEmpty ? context.tr('newTask') : text,
                    style: done
                        ? TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeTask(i),
                  ),
                  onTap: () async {
                    final controller = TextEditingController(text: text);
                    final result = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(context.tr('editTask')),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: context.tr('taskDescription'),
                          ),
                          onSubmitted: (v) => Navigator.pop(ctx, v),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(context.tr('cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, controller.text),
                            child: Text(context.tr('save')),
                          ),
                        ],
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() => _updateTask(i, result));
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
