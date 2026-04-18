import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/zumre_models.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

class ZumreNotesScreen extends StatefulWidget {
  const ZumreNotesScreen({super.key});

  @override
  State<ZumreNotesScreen> createState() => _ZumreNotesScreenState();
}

class _ZumreNotesScreenState extends State<ZumreNotesScreen> {
  ZumreNote? _selectedItem;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.watch<AppProvider>().repo;
    final list = repo.getZumreNotes()..sort((a, b) => b.date.compareTo(a.date));
    final meetings = repo.getZumreMeetings();
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    if (_selectedItem != null) {
      final id = _selectedItem!.id;
      try {
        _selectedItem = list.firstWhere((item) => item.id == id);
      } catch (_) {
        _selectedItem = list.isNotEmpty ? list.first : null;
      }
    }

    return Scaffold(
      body: PlannerSplitView(
        emptyState: list.isNotEmpty ? _buildPlaceholder(context) : null,
        onClosePanel: _selectedItem != null
            ? () => setState(() => _selectedItem = null)
            : null,
        sidePanel: _selectedItem != null
            ? _buildPanel(context, _selectedItem!, meetings)
            : null,
        content: list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('zumre_no_notes'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showForm(context, meetings: meetings),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('add')),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final n = list[i];
                  final isSelected = _selectedItem?.id == n.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.visibility),
                      ),
                      title: Text(n.title),
                      subtitle: Text(
                        '${n.date.day}/${n.date.month}/${n.date.year}${n.description.isNotEmpty ? ' • ${n.description}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedItem = n);
                        } else {
                          _showForm(context, item: n, meetings: meetings);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'zumre_notes_add_fab',
              onPressed: () => _showForm(context, meetings: meetings),
              icon: const Icon(Icons.add),
              label: Text(context.tr('add')),
            ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
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

  Widget _buildPanel(
    BuildContext context,
    ZumreNote item,
    List<ZumreMeeting> meetings,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${item.date.day}/${item.date.month}/${item.date.year}'),
          const SizedBox(height: 16),
          _detailRow(context, context.tr('description'), item.description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () =>
                    _showForm(context, item: item, meetings: meetings),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _confirmDelete(context, item),
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

  void _showForm(
    BuildContext context, {
    ZumreNote? item,
    required List<ZumreMeeting> meetings,
  }) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    DateTime date = item?.date ?? DateTime.now();
    String? relatedId = item?.relatedMeetingId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx2).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item == null ? context.tr('add') : context.tr('edit'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: context.tr('title')),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('description'),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(context.tr('date')),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModal(() => date = d);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: relatedId,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_related_meeting'),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('-')),
                    ...meetings.map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(
                          '${m.meetingDate.day}/${m.meetingDate.month}/${m.meetingDate.year}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setModal(() => relatedId = v),
                ),
                const SizedBox(height: 24),
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
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        final n = ZumreNote(
                          id: item?.id ?? AppRepository.generateId(),
                          title: title,
                          description: descCtrl.text.trim(),
                          date: date,
                          relatedMeetingId: relatedId,
                        );
                        if (item != null) {
                          await context
                              .read<AppProvider>()
                              .repo
                              .updateZumreNote(n);
                        } else {
                          await context.read<AppProvider>().repo.addZumreNote(
                            n,
                          );
                        }
                        if (context.mounted) {
                          context.read<AppProvider>().refresh();
                          Navigator.pop(ctx);
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

  void _confirmDelete(BuildContext context, ZumreNote n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text('${n.title} ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteZumreNote(n.id);
              if (context.mounted) {
                context.read<AppProvider>().refresh();
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}
