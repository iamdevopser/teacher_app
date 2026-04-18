import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/tr_extension.dart';
import '../../../core/utils/app_provider.dart';

/// Anasayfada gün içinde alınan ders notlarını listeler.
class DailyLessonNotesCard extends StatefulWidget {
  const DailyLessonNotesCard({super.key, this.showTitle = true});

  final bool showTitle;

  @override
  State<DailyLessonNotesCard> createState() => _DailyLessonNotesCardState();
}

class _DailyLessonNotesCardState extends State<DailyLessonNotesCard> {
  List<Map<String, dynamic>> _notesFor(BuildContext context) {
    final today = DateTime.now();
    final notes = context.read<AppProvider>().repo.getDailyLessonNotesByDate(today);
    notes.sort((a, b) => (b['createdAt'] as String? ?? '').compareTo(a['createdAt'] as String? ?? ''));
    return notes;
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  void _addNote() {
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('dailyLessonNotes'), style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.tr('dailyLessonNotesHint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.tr('cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final text = textCtrl.text.trim();
                        if (text.isEmpty) return;
                        await context.read<AppProvider>().repo.addDailyLessonNote({
                          'id': DateTime.now().millisecondsSinceEpoch.toString(),
                          'text': text,
                          'date': _todayStr(),
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          context.read<AppProvider>().refresh();
                          setState(() {});
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

  void _editNote(Map<String, dynamic> note) {
    final textCtrl = TextEditingController(text: note['text'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('edit'), style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: context.tr('dailyLessonNotesHint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.tr('cancel')),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final text = textCtrl.text.trim();
                        if (text.isEmpty) return;
                        final updated = Map<String, dynamic>.from(note)..['text'] = text;
                        await context.read<AppProvider>().repo.updateDailyLessonNote(
                          note['id'] as String,
                          updated,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          context.read<AppProvider>().refresh();
                          setState(() {});
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

  void _deleteNote(Map<String, dynamic> note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(context.tr('dailyLessonNoteDeleteConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true) {
      await context.read<AppProvider>().repo.deleteDailyLessonNote(note['id'] as String);
      context.read<AppProvider>().refresh();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final _notes = _notesFor(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showTitle) ...[
              Row(
                children: [
                  Icon(Icons.note_alt, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('dailyLessonNotes'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addNote,
                    tooltip: context.tr('add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addNote,
                    tooltip: context.tr('add'),
                  ),
                ],
              ),
            ],
            if (_notes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  context.tr('dailyLessonNotesEmpty'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              )
            else
              ..._notes.take(10).map((note) {
                final text = note['text'] as String? ?? '';
                final createdAt = note['createdAt'] as String? ?? '';
                String timeStr = '';
                try {
                  final dt = DateTime.parse(createdAt);
                  timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {}
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      text.length > 80 ? '${text.substring(0, 80)}...' : text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: timeStr.isNotEmpty ? Text(timeStr, style: Theme.of(context).textTheme.bodySmall) : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editNote(note);
                        else if (v == 'delete') _deleteNote(note);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(context.tr('edit'))),
                        PopupMenuItem(value: 'delete', child: Text(context.tr('delete'))),
                      ],
                    ),
                    onTap: () => _editNote(note),
                  ),
                );
              }),
            if (_notes.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.tr('dailyLessonNotes')} (+${_notes.length - 10})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
