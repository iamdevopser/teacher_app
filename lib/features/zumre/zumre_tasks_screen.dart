import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/zumre_models.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

class ZumreTasksScreen extends StatefulWidget {
  const ZumreTasksScreen({super.key});

  @override
  State<ZumreTasksScreen> createState() => _ZumreTasksScreenState();
}

class _ZumreTasksScreenState extends State<ZumreTasksScreen> {
  ZumreTask? _selectedItem;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.watch<AppProvider>().repo;
    final list = repo.getZumreTasks();
    final meetings = repo.getZumreMeetings();
    final decisions = repo.getZumreDecisions();
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
            ? _buildPanel(context, _selectedItem!, meetings, decisions)
            : null,
        content: list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('zumre_no_tasks'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showForm(
                          context,
                          meetings: meetings,
                          decisions: decisions,
                        ),
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
                  final t = list[i];
                  final statusKey = t.status == 'tamamlandi'
                      ? 'zumre_status_done'
                      : t.status == 'devam_ediyor'
                      ? 'zumre_status_in_progress'
                      : 'zumre_status_pending';
                  final isSelected = _selectedItem?.id == t.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          t.status == 'tamamlandi'
                              ? Icons.check_circle
                              : Icons.pending_actions,
                          color: t.status == 'tamamlandi' ? Colors.green : null,
                        ),
                      ),
                      title: Text(t.title),
                      subtitle: Text(
                        [
                          if (t.dueDate != null)
                            '${context.tr('date')}: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}',
                          context.tr(statusKey),
                          if (FeatureFlags.zumreDecisionTaskLink &&
                              t.relatedDecisionId != null)
                            '• ${context.tr('zumre_related_decision')}',
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedItem = t);
                        } else {
                          _showForm(
                            context,
                            item: t,
                            meetings: meetings,
                            decisions: decisions,
                          );
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
              heroTag: 'zumre_tasks_add_fab',
              onPressed: () =>
                  _showForm(context, meetings: meetings, decisions: decisions),
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
    ZumreTask item,
    List<ZumreMeeting> meetings,
    List<ZumreDecision> decisions,
  ) {
    final statusKey = item.status == 'tamamlandi'
        ? 'zumre_status_done'
        : item.status == 'devam_ediyor'
        ? 'zumre_status_in_progress'
        : 'zumre_status_pending';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _detailRow(context, context.tr('description'), item.description),
          _detailRow(
            context,
            context.tr('zumre_task_status'),
            context.tr(statusKey),
          ),
          if (item.dueDate != null)
            _detailRow(
              context,
              context.tr('zumre_due_date'),
              '${item.dueDate!.day}/${item.dueDate!.month}/${item.dueDate!.year}',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showForm(
                  context,
                  item: item,
                  meetings: meetings,
                  decisions: decisions,
                ),
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
    ZumreTask? item,
    required List<ZumreMeeting> meetings,
    required List<ZumreDecision> decisions,
  }) {
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String? relatedId = item?.relatedMeetingId;
    String? relatedDecisionId = item?.relatedDecisionId;
    DateTime? dueDate = item?.dueDate;
    String status = item?.status ?? 'beklemede';

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
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_task_title'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('description'),
                  ),
                  maxLines: 2,
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
                if (FeatureFlags.zumreDecisionTaskLink &&
                    decisions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: relatedDecisionId,
                    decoration: InputDecoration(
                      labelText: context.tr('zumre_related_decision'),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('-')),
                      ...decisions.map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            d.decisionSummary.isEmpty
                                ? d.id
                                : d.decisionSummary.length > 40
                                ? '${d.decisionSummary.substring(0, 40)}...'
                                : d.decisionSummary,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setModal(() => relatedDecisionId = v),
                  ),
                ],
                const SizedBox(height: 12),
                ListTile(
                  title: Text(context.tr('zumre_due_date')),
                  subtitle: Text(
                    dueDate != null
                        ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                        : '-',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setModal(() => dueDate = null),
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx2,
                            initialDate: dueDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (d != null) setModal(() => dueDate = d);
                        },
                      ),
                    ],
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: InputDecoration(
                    labelText: context.tr('zumre_task_status'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'beklemede',
                      child: Text(context.tr('zumre_status_pending')),
                    ),
                    DropdownMenuItem(
                      value: 'devam_ediyor',
                      child: Text(context.tr('zumre_status_in_progress')),
                    ),
                    DropdownMenuItem(
                      value: 'tamamlandi',
                      child: Text(context.tr('zumre_status_done')),
                    ),
                  ],
                  onChanged: (v) => setModal(() => status = v ?? 'beklemede'),
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
                        final t = ZumreTask(
                          id: item?.id ?? AppRepository.generateId(),
                          title: title,
                          description: descCtrl.text.trim(),
                          relatedMeetingId: relatedId,
                          relatedDecisionId: FeatureFlags.zumreDecisionTaskLink
                              ? relatedDecisionId
                              : null,
                          dueDate: dueDate,
                          status: status,
                        );
                        if (item != null) {
                          await context
                              .read<AppProvider>()
                              .repo
                              .updateZumreTask(t);
                        } else {
                          await context.read<AppProvider>().repo.addZumreTask(
                            t,
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

  void _confirmDelete(BuildContext context, ZumreTask t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text('${t.title} ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteZumreTask(t.id);
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
