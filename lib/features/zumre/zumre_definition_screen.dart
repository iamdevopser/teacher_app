import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/zumre_models.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

class ZumreDefinitionScreen extends StatefulWidget {
  const ZumreDefinitionScreen({super.key});

  @override
  State<ZumreDefinitionScreen> createState() => _ZumreDefinitionScreenState();
}

class _ZumreDefinitionScreenState extends State<ZumreDefinitionScreen> {
  ZumreDefinition? _selectedItem;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.watch<AppProvider>().repo;
    final list = repo.getZumreDefinitions();
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
                        Icons.info_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('zumre_no_definitions'),
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
                  final z = list[i];
                  final isSelected = _selectedItem?.id == z.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.school)),
                      title: Text(z.name),
                      subtitle: Text(
                        [
                          z.branch,
                          z.academicYear,
                          z.schoolType,
                        ].where((s) => s.isNotEmpty).join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedItem = z);
                        } else {
                          _showForm(context, item: z);
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
              heroTag: 'zumre_definition_add_fab',
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

  Widget _buildPanel(BuildContext context, ZumreDefinition item) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _detailRow(context, context.tr('zumre_branch'), item.branch),
          _detailRow(
            context,
            context.tr('zumre_academic_year'),
            item.academicYear,
          ),
          _detailRow(context, context.tr('zumre_school_type'), item.schoolType),
          _detailRow(
            context,
            context.tr('zumre_department_head'),
            item.departmentHead,
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

  void _showForm(BuildContext context, {ZumreDefinition? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final branchCtrl = TextEditingController(text: item?.branch ?? '');
    final yearCtrl = TextEditingController(text: item?.academicYear ?? '');
    final schoolCtrl = TextEditingController(text: item?.schoolType ?? '');
    final headCtrl = TextEditingController(text: item?.departmentHead ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('zumre_name'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: branchCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('zumre_branch'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: yearCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('zumre_academic_year'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: schoolCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('zumre_school_type'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: headCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('zumre_department_head'),
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
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final z = ZumreDefinition(
                        id: item?.id ?? AppRepository.generateId(),
                        name: name,
                        branch: branchCtrl.text.trim(),
                        academicYear: yearCtrl.text.trim(),
                        schoolType: schoolCtrl.text.trim(),
                        departmentHead: headCtrl.text.trim(),
                      );
                      if (item != null) {
                        await context
                            .read<AppProvider>()
                            .repo
                            .updateZumreDefinition(z);
                      } else {
                        await context
                            .read<AppProvider>()
                            .repo
                            .addZumreDefinition(z);
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
    );
  }

  void _confirmDelete(BuildContext context, ZumreDefinition z) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text('${z.name} ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteZumreDefinition(
                z.id,
              );
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
