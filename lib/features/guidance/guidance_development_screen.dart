import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

/// extra.md: Öğrenci Gelişim – pozitif gelişim notları (problem değil, ceza/disiplin yok).
/// Akademik gelişim, sosyal/duygusal gözlemler, öğrenci öz değerlendirme.
class GuidanceDevelopmentScreen extends StatefulWidget {
  const GuidanceDevelopmentScreen({super.key});

  @override
  State<GuidanceDevelopmentScreen> createState() =>
      _GuidanceDevelopmentScreenState();
}

class _GuidanceDevelopmentScreenState extends State<GuidanceDevelopmentScreen> {
  List<Map<String, dynamic>> _notes = [];
  Map<String, dynamic>? _selectedNote;

  void _load() {
    final repo = context.read<AppProvider>().repo;
    _notes = repo.getGuidanceDevelopmentNotes();
    _notes.sort((a, b) {
      final da = DateTime.tryParse(a['date']?.toString() ?? '');
      final db = DateTime.tryParse(b['date']?.toString() ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    if (_selectedNote != null) {
      final id = _selectedNote!['id']?.toString();
      try {
        _selectedNote = _notes.firstWhere(
          (note) => note['id']?.toString() == id,
        );
      } catch (_) {
        _selectedNote = _notes.isNotEmpty ? _notes.first : null;
      }
    }
    setState(() {});
  }

  Future<void> _showForm([Map<String, dynamic>? existing]) async {
    final repo = context.read<AppProvider>().repo;
    final students = repo.getGuidanceStudents();
    final studentIdCtrl = TextEditingController(
      text: existing?['studentId']?.toString() ?? '',
    );
    final studentNameCtrl = TextEditingController(
      text: existing?['studentName']?.toString() ?? '',
    );
    DateTime date = existing != null && existing['date'] != null
        ? DateTime.tryParse(existing['date'].toString()) ?? DateTime.now()
        : DateTime.now();
    final academicCtrl = TextEditingController(
      text: existing?['academicNote']?.toString() ?? '',
    );
    final socialCtrl = TextEditingController(
      text: existing?['socialEmotionalNote']?.toString() ?? '',
    );
    final selfCtrl = TextEditingController(
      text: existing?['selfAssessment']?.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          title: Text(
            existing != null ? context.tr('edit') : context.tr('add'),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: students.any((s) => s.id == studentIdCtrl.text)
                        ? studentIdCtrl.text
                        : null,
                    decoration: InputDecoration(
                      labelText: context.tr('studentLabel'),
                    ),
                    items: students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) {
                        final s = students.firstWhere((x) => x.id == id);
                        studentIdCtrl.text = id;
                        studentNameCtrl.text = s.fullName;
                        setDialogState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(context.tr('date')),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setDialogState(() => date = d);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: academicCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('guidanceDevelopmentTypeAcademic'),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: socialCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('guidanceDevelopmentTypeSocial'),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: selfCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr('guidanceDevelopmentTypeSelf'),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final id = studentIdCtrl.text.trim();
                final name = studentNameCtrl.text.trim();
                if (id.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(ctx2).showSnackBar(
                    SnackBar(content: Text(context.tr('studentLabel'))),
                  );
                  return;
                }
                final note = {
                  'id': existing?['id'] ?? AppRepository.generateId(),
                  'studentId': id,
                  'studentName': name,
                  'date': date.toIso8601String(),
                  'academicNote': academicCtrl.text.trim(),
                  'socialEmotionalNote': socialCtrl.text.trim(),
                  'selfAssessment': selfCtrl.text.trim(),
                  'createdAt':
                      (existing?['createdAt'] ??
                              DateTime.now().toIso8601String())
                          .toString(),
                };
                if (existing != null) {
                  await repo.updateGuidanceDevelopmentNote(
                    note['id'] as String,
                    note,
                  );
                } else {
                  await repo.addGuidanceDevelopmentNote(note);
                }
                if (ctx2.mounted) Navigator.pop(ctx, true);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(Map<String, dynamic> note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(
          '${note['studentName']} – ${context.tr('guidanceDevelopmentTab')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().repo.deleteGuidanceDevelopmentNote(
        note['id'] as String,
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    return Scaffold(
      body: PlannerSplitView(
        emptyState: _notes.isNotEmpty ? _buildPlaceholder(context) : null,
        onClosePanel: _selectedNote != null
            ? () => setState(() => _selectedNote = null)
            : null,
        sidePanel: _selectedNote != null
            ? _buildPanel(context, _selectedNote!)
            : null,
        content: _notes.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('guidanceDevelopmentEmpty'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => _showForm(),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('add')),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notes.length,
                itemBuilder: (_, i) {
                  final n = _notes[i];
                  final isSelected =
                      _selectedNote?['id']?.toString() == n['id']?.toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: const Icon(
                        Icons.trending_up,
                        color: Colors.green,
                      ),
                      title: Text(n['studentName']?.toString() ?? '-'),
                      subtitle: Text(
                        n['date']?.toString().substring(0, 10) ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedNote = n);
                        } else {
                          _showForm(n);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: _notes.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'guidance_development_add_fab',
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: Text(context.tr('add')),
            )
          : null,
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

  Widget _buildPanel(BuildContext context, Map<String, dynamic> note) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            note['studentName']?.toString() ?? '-',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(note['date']?.toString().substring(0, 10) ?? ''),
          const SizedBox(height: 16),
          _detailRow(
            context,
            context.tr('guidanceDevelopmentTypeAcademic'),
            note['academicNote']?.toString() ?? '',
          ),
          _detailRow(
            context,
            context.tr('guidanceDevelopmentTypeSocial'),
            note['socialEmotionalNote']?.toString() ?? '',
          ),
          _detailRow(
            context,
            context.tr('guidanceDevelopmentTypeSelf'),
            note['selfAssessment']?.toString() ?? '',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showForm(note),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _delete(note),
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }
}
