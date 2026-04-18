import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/guidance_student.dart';
import '../../data/models/guidance_models.dart';
import '../../data/repositories/app_repository.dart';
import '../lesson_planner/planner_split_view.dart';

/// Öğrenci Problemleri: Devamsızlık, başarısızlık, disiplin sorunları
class GuidanceProblemsScreen extends StatefulWidget {
  const GuidanceProblemsScreen({super.key});

  @override
  State<GuidanceProblemsScreen> createState() => _GuidanceProblemsScreenState();
}

class _GuidanceProblemsScreenState extends State<GuidanceProblemsScreen> {
  StudentProblemType? _filterType;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  StudentProblem? _selectedProblem;

  List<StudentProblem> _applyFilters(List<StudentProblem> list) {
    var out = list;
    if (_filterType != null)
      out = out.where((p) => p.type == _filterType).toList();
    if (FeatureFlags.problemsDateFilter &&
        (_dateFrom != null || _dateTo != null)) {
      out = out.where((p) {
        final d = DateTime(p.date.year, p.date.month, p.date.day);
        if (_dateFrom != null &&
            d.isBefore(
              DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day),
            ))
          return false;
        if (_dateTo != null &&
            d.isAfter(
              DateTime(
                _dateTo!.year,
                _dateTo!.month,
                _dateTo!.day,
              ).add(const Duration(days: 1)),
            ))
          return false;
        return true;
      }).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final problems = repo.getStudentProblems();
    final filtered = _applyFilters(problems);
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    if (_selectedProblem != null) {
      final id = _selectedProblem!.id;
      try {
        _selectedProblem = problems.firstWhere((problem) => problem.id == id);
      } catch (_) {
        _selectedProblem = filtered.isNotEmpty ? filtered.first : null;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text(context.tr('all')),
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                ...StudentProblemType.values.map(
                  (t) => FilterChip(
                    label: Text(_typeLabel(context, t)),
                    selected: _filterType == t,
                    onSelected: (_) => setState(() => _filterType = t),
                  ),
                ),
                if (FeatureFlags.problemsDateFilter) ...[
                  FilterChip(
                    label: Text(
                      _dateFrom != null || _dateTo != null
                          ? '${_dateFrom != null ? '${_dateFrom!.day}/${_dateFrom!.month}' : '...'} - ${_dateTo != null ? '${_dateTo!.day}/${_dateTo!.month}' : '...'}'
                          : context.tr('date'),
                    ),
                    selected: _dateFrom != null || _dateTo != null,
                    onSelected: (_) async {
                      final from = await showDatePicker(
                        context: context,
                        initialDate: _dateFrom ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (from != null && mounted) {
                        final to = await showDatePicker(
                          context: context,
                          initialDate: _dateTo ?? from,
                          firstDate: from,
                          lastDate: DateTime(2030),
                        );
                        if (mounted)
                          setState(() {
                            _dateFrom = from;
                            _dateTo = to ?? from;
                          });
                      }
                    },
                  ),
                  if (_dateFrom != null || _dateTo != null)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                      }),
                      icon: const Icon(Icons.clear, size: 18),
                      label: Text(context.tr('clear')),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            child: PlannerSplitView(
              emptyState: filtered.isNotEmpty
                  ? _buildPlaceholder(context)
                  : null,
              onClosePanel: _selectedProblem != null
                  ? () => setState(() => _selectedProblem = null)
                  : null,
              sidePanel: _selectedProblem != null
                  ? _buildProblemPanel(context, _selectedProblem!)
                  : null,
              content: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('noRecordsYet'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final isSelected = _selectedProblem?.id == p.id;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                                    .withValues(alpha: 0.35)
                              : null,
                          child: ListTile(
                            leading: Icon(
                              _typeIcon(p.type),
                              color: _typeColor(p.type),
                            ),
                            title: Text(p.studentName),
                            subtitle: Text(
                              [
                                if (p.description.isNotEmpty)
                                  p.description
                                else
                                  p.typeLabel(
                                    context
                                        .read<LocaleProvider>()
                                        .effectiveLocale
                                        .languageCode,
                                  ),
                                if (FeatureFlags.problemsSeverityLevels &&
                                    p.severity != null)
                                  ' • ${p.severity}',
                                if (FeatureFlags.problemsResolutionStatus &&
                                    p.resolutionStatus != null)
                                  ' • ${p.resolutionStatus}',
                              ].join(''),
                            ),
                            trailing: isWide
                                ? const Icon(Icons.chevron_right)
                                : null,
                            onTap: () {
                              if (isWide) {
                                setState(() => _selectedProblem = p);
                              } else {
                                _showProblemForm(context, problem: p);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'guidance_problems_add_fab',
        onPressed: () => _showProblemForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addProblem')),
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

  Widget _buildProblemPanel(BuildContext context, StudentProblem problem) {
    final localeCode = context
        .read<LocaleProvider>()
        .effectiveLocale
        .languageCode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            problem.studentName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(problem.typeLabel(localeCode)),
          const SizedBox(height: 16),
          _detailRow(
            context,
            context.tr('problemType'),
            problem.typeLabel(localeCode),
          ),
          _detailRow(context, context.tr('description'), problem.description),
          _detailRow(
            context,
            context.tr('date'),
            '${problem.date.day}/${problem.date.month}/${problem.date.year}',
          ),
          if (FeatureFlags.problemsSeverityLevels)
            _detailRow(context, context.tr('severity'), problem.severity ?? ''),
          if (FeatureFlags.problemsResolutionStatus)
            _detailRow(
              context,
              context.tr('resolutionStatus'),
              problem.resolutionStatus ?? '',
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showProblemForm(context, problem: problem),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _confirmDelete(context, problem),
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

  String _typeLabel(BuildContext context, StudentProblemType t) {
    return context.tr(
      'problemType${t.name[0].toUpperCase()}${t.name.substring(1)}',
    );
  }

  IconData _typeIcon(StudentProblemType t) {
    switch (t) {
      case StudentProblemType.attendance:
        return Icons.event_busy;
      case StudentProblemType.failure:
        return Icons.school;
      case StudentProblemType.discipline:
        return Icons.gavel;
      case StudentProblemType.other:
        return Icons.info;
    }
  }

  Color _typeColor(StudentProblemType t) {
    switch (t) {
      case StudentProblemType.attendance:
        return Colors.orange;
      case StudentProblemType.failure:
        return Colors.red;
      case StudentProblemType.discipline:
        return Colors.deepPurple;
      case StudentProblemType.other:
        return Colors.grey;
    }
  }

  void _showProblemForm(BuildContext context, {StudentProblem? problem}) {
    final repo = context.read<AppProvider>().repo;
    final students = repo.getGuidanceStudents();
    if (students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('addStudentFirst'))));
      return;
    }

    GuidanceStudent? selectedStudent;
    if (problem != null) {
      selectedStudent = students.cast<GuidanceStudent?>().firstWhere(
        (s) => s?.id == problem.studentId,
        orElse: () => null,
      );
    }
    var type = problem?.type ?? StudentProblemType.attendance;
    final descCtrl = TextEditingController(text: problem?.description ?? '');
    var date = problem?.date ?? DateTime.now();
    String? severity = problem?.severity;
    String? resolutionStatus = problem?.resolutionStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Padding(
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
                  problem == null
                      ? context.tr('addProblem')
                      : context.tr('edit'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GuidanceStudent>(
                  value:
                      selectedStudent ??
                      (students.isNotEmpty ? students.first : null),
                  decoration: InputDecoration(
                    labelText: context.tr('studentLabel'),
                  ),
                  items: students
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s, child: Text(s.fullName)),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedStudent = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<StudentProblemType>(
                  value: type,
                  decoration: InputDecoration(
                    labelText: context.tr('problemType'),
                  ),
                  items: StudentProblemType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(_typeLabel(context, t)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => type = v ?? type),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('description'),
                  ),
                  maxLines: 3,
                ),
                if (FeatureFlags.problemsSeverityLevels) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: severity,
                    decoration: InputDecoration(
                      labelText: context.tr('severity'),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('—')),
                      DropdownMenuItem(value: 'low', child: Text('Düşük')),
                      DropdownMenuItem(value: 'medium', child: Text('Orta')),
                      DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                    ],
                    onChanged: (v) => setModalState(() => severity = v),
                  ),
                ],
                if (FeatureFlags.problemsResolutionStatus) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: resolutionStatus,
                    decoration: InputDecoration(
                      labelText: context.tr('resolutionStatus'),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('—')),
                      DropdownMenuItem(value: 'open', child: Text('Açık')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('İşlemde'),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Text('Çözüldü'),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => resolutionStatus = v),
                  ),
                ],
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
                        final s = selectedStudent ?? students.first;
                        final sp = StudentProblem(
                          id: problem?.id ?? AppRepository.generateId(),
                          studentId: s.id,
                          studentName: s.fullName,
                          type: type,
                          description: descCtrl.text.trim(),
                          date: date,
                          createdAt: problem?.createdAt ?? DateTime.now(),
                          severity: FeatureFlags.problemsSeverityLevels
                              ? severity
                              : null,
                          resolutionStatus:
                              FeatureFlags.problemsResolutionStatus
                              ? resolutionStatus
                              : null,
                          parentMeetingId: problem?.parentMeetingId,
                        );
                        if (problem != null) {
                          await repo.updateStudentProblem(sp);
                        } else {
                          await repo.addStudentProblem(sp);
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

  void _confirmDelete(BuildContext context, StudentProblem p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text(
          '${p.studentName} - ${p.typeLabel(context.read<LocaleProvider>().effectiveLocale.languageCode)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteStudentProblem(p.id);
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
