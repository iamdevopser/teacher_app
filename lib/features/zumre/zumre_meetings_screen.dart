import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/zumre_models.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

class ZumreMeetingsScreen extends StatefulWidget {
  const ZumreMeetingsScreen({super.key});

  @override
  State<ZumreMeetingsScreen> createState() => _ZumreMeetingsScreenState();
}

class _ZumreMeetingsScreenState extends State<ZumreMeetingsScreen> {
  ZumreMeeting? _selectedItem;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.watch<AppProvider>().repo;
    final list = repo.getZumreMeetings()
      ..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
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
            ? _buildPanel(context, _selectedItem!)
            : null,
        content: list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('zumre_no_meetings'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showForm(context),
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
                  final m = list[i];
                  final typeKey = m.meetingType == 'donem_basi'
                      ? 'zumre_meeting_type_start'
                      : m.meetingType == 'donem_sonu'
                      ? 'zumre_meeting_type_end'
                      : 'zumre_meeting_type_mid';
                  final isSelected = _selectedItem?.id == m.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.event)),
                      title: Text(
                        '${m.meetingDate.day}/${m.meetingDate.month}/${m.meetingDate.year} - ${context.tr(typeKey)}',
                      ),
                      subtitle: Text(
                        m.agendaItems.isNotEmpty ? m.agendaItems : m.decisions,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedItem = m);
                        } else {
                          _showForm(context, item: m);
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
              heroTag: 'zumre_meetings_add_fab',
              onPressed: () => _showForm(context),
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

  Widget _buildPanel(BuildContext context, ZumreMeeting item) {
    final typeKey = item.meetingType == 'donem_basi'
        ? 'zumre_meeting_type_start'
        : item.meetingType == 'donem_sonu'
        ? 'zumre_meeting_type_end'
        : 'zumre_meeting_type_mid';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(typeKey),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.meetingDate.day}/${item.meetingDate.month}/${item.meetingDate.year}',
          ),
          const SizedBox(height: 16),
          _detailRow(context, context.tr('zumre_agenda'), item.agendaItems),
          _detailRow(context, context.tr('zumre_decisions'), item.decisions),
          _detailRow(
            context,
            context.tr('zumre_teacher_tasks'),
            item.teacherTasks,
          ),
          if (item.nextMeetingDate != null)
            _detailRow(
              context,
              context.tr('zumre_next_meeting'),
              '${item.nextMeetingDate!.day}/${item.nextMeetingDate!.month}/${item.nextMeetingDate!.year}',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showForm(context, item: item),
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

  void _showForm(BuildContext context, {ZumreMeeting? item}) {
    final date = item?.meetingDate ?? DateTime.now();
    DateTime? pickedDate = date;
    String meetingType = item?.meetingType ?? 'ara';
    final agendaCtrl = TextEditingController(text: item?.agendaItems ?? '');
    final decisionsCtrl = TextEditingController(text: item?.decisions ?? '');
    final tasksCtrl = TextEditingController(text: item?.teacherTasks ?? '');
    DateTime? nextDate = item?.nextMeetingDate;

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
                ListTile(
                  title: Text(context.tr('date')),
                  subtitle: Text(
                    '${pickedDate?.day ?? 0}/${pickedDate?.month ?? 0}/${pickedDate?.year ?? 0}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx2,
                      initialDate: pickedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModal(() => pickedDate = d);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: meetingType,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_meeting_type'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'donem_basi',
                      child: Text(context.tr('zumre_meeting_type_start')),
                    ),
                    DropdownMenuItem(
                      value: 'donem_sonu',
                      child: Text(context.tr('zumre_meeting_type_end')),
                    ),
                    DropdownMenuItem(
                      value: 'ara',
                      child: Text(context.tr('zumre_meeting_type_mid')),
                    ),
                  ],
                  onChanged: (v) => setModal(() => meetingType = v ?? 'ara'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: agendaCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_agenda'),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: decisionsCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_decisions'),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tasksCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_teacher_tasks'),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(context.tr('zumre_next_meeting')),
                  subtitle: Text(
                    nextDate != null
                        ? '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}'
                        : '-',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (nextDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setModal(() => nextDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx2,
                            initialDate: nextDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setModal(() => nextDate = d);
                        },
                      ),
                    ],
                  ),
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
                        final m = ZumreMeeting(
                          id: item?.id ?? AppRepository.generateId(),
                          meetingDate: pickedDate ?? DateTime.now(),
                          meetingType: meetingType,
                          agendaItems: agendaCtrl.text.trim(),
                          decisions: decisionsCtrl.text.trim(),
                          teacherTasks: tasksCtrl.text.trim(),
                          nextMeetingDate: nextDate,
                        );
                        if (item != null) {
                          await context
                              .read<AppProvider>()
                              .repo
                              .updateZumreMeeting(m);
                        } else {
                          await context
                              .read<AppProvider>()
                              .repo
                              .addZumreMeeting(m);
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

  void _confirmDelete(BuildContext context, ZumreMeeting m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text(
          '${m.meetingDate.day}/${m.meetingDate.month}/${m.meetingDate.year} ${context.tr('confirmDelete')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteZumreMeeting(m.id);
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
