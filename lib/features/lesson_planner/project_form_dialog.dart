import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/app_repository.dart';

/// Proje Ekle/Düzenle formu
class ProjectFormDialog extends StatefulWidget {
  const ProjectFormDialog({this.project, super.key});

  final ProjectModel? project;

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  List<String> _selectedClasses = [];
  final _purposeCtrl = TextEditingController();
  final _outcomesCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _scopeCtrl = TextEditingController();
  final _teacherNotesCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final _contentCriteriaCtrl = TextEditingController();
  final _participationCriteriaCtrl = TextEditingController();
  final _presentationCriteriaCtrl = TextEditingController();
  final _timeCriteriaCtrl = TextEditingController();
  final _processNotesCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _devNotesCtrl = TextEditingController();

  late ProjectType _type;
  late DateTime _startDate;
  late DateTime _endDate;
  late ProjectStatus _status;
  List<ProjectStep> _steps = [];

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl.text = p?.name ?? '';
    _subjectCtrl.text = p?.subject ?? '';
    _selectedClasses = (p?.classLevel ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _purposeCtrl.text = p?.purpose ?? '';
    _outcomesCtrl.text = p?.outcomes ?? '';
    _skillsCtrl.text = p?.skills ?? '';
    _shortDescCtrl.text = p?.shortDescription ?? '';
    _scopeCtrl.text = p?.scope ?? '';
    _teacherNotesCtrl.text = p?.teacherNotes ?? '';
    _materialsCtrl.text = p?.materials ?? '';
    _contentCriteriaCtrl.text = p?.contentCriteria ?? '';
    _participationCriteriaCtrl.text = p?.participationCriteria ?? '';
    _presentationCriteriaCtrl.text = p?.presentationCriteria ?? '';
    _timeCriteriaCtrl.text = p?.timeManagementCriteria ?? '';
    _processNotesCtrl.text = p?.processNotes ?? '';
    _observationsCtrl.text = p?.observations ?? '';
    _devNotesCtrl.text = p?.developmentNotes ?? '';
    _type = p?.type ?? ProjectType.inClass;
    _startDate = p?.startDate ?? DateTime.now();
    _endDate = p?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _status = p?.status ?? ProjectStatus.draft;
    _steps = p?.steps.map((s) => ProjectStep(id: s.id, title: s.title, description: s.description, estimatedDuration: s.estimatedDuration)).toList() ?? [];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _purposeCtrl.dispose();
    _outcomesCtrl.dispose();
    _skillsCtrl.dispose();
    _shortDescCtrl.dispose();
    _scopeCtrl.dispose();
    _teacherNotesCtrl.dispose();
    _materialsCtrl.dispose();
    _contentCriteriaCtrl.dispose();
    _participationCriteriaCtrl.dispose();
    _presentationCriteriaCtrl.dispose();
    _timeCriteriaCtrl.dispose();
    _processNotesCtrl.dispose();
    _observationsCtrl.dispose();
    _devNotesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('projectNameRequired'))));
      return;
    }
    final project = ProjectModel(
      id: widget.project?.id ?? AppRepository.generateId(),
      name: name,
      type: _type,
      subject: _subjectCtrl.text.trim(),
      classLevel: _selectedClasses.join(', '),
      startDate: _startDate,
      endDate: _endDate,
      purpose: _purposeCtrl.text.trim(),
      outcomes: _outcomesCtrl.text.trim(),
      skills: _skillsCtrl.text.trim(),
      shortDescription: _shortDescCtrl.text.trim(),
      scope: _scopeCtrl.text.trim(),
      teacherNotes: _teacherNotesCtrl.text.trim(),
      steps: _steps,
      materials: _materialsCtrl.text.trim(),
      contentCriteria: _contentCriteriaCtrl.text.trim(),
      participationCriteria: _participationCriteriaCtrl.text.trim(),
      presentationCriteria: _presentationCriteriaCtrl.text.trim(),
      timeManagementCriteria: _timeCriteriaCtrl.text.trim(),
      processNotes: _processNotesCtrl.text.trim(),
      observations: _observationsCtrl.text.trim(),
      developmentNotes: _devNotesCtrl.text.trim(),
      status: _status,
      createdAt: widget.project?.createdAt ?? DateTime.now(),
      participants: widget.project?.participants ?? const [],
    );
    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    final classes = _buildClassList();
    return Dialog(
      child: SizedBox(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            AppBar(
              title: Text(widget.project != null ? context.tr('edit') : context.tr('addProject')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
                FilledButton(onPressed: _save, child: Text(context.tr('save'))),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section('1. ${context.tr('projectBasicInfo')}', [
                      _textField(_nameCtrl, context.tr('projectName')),
                      DropdownButtonFormField<ProjectType>(
                        value: _type,
                        decoration: InputDecoration(labelText: context.tr('projectType')),
                        items: ProjectType.values.map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t)))).toList(),
                        onChanged: (v) => setState(() => _type = v ?? _type),
                      ),
                      _textField(_subjectCtrl, context.tr('projectSubject')),
                      _classSelector(classes),
                      _dateField(context.tr('projectStartDate'), _startDate, (d) => setState(() => _startDate = d)),
                      _dateField(context.tr('projectEndDate'), _endDate, (d) => setState(() => _endDate = d)),
                    ]),
                    _section('2. ${context.tr('projectPurpose')}', [
                      _textField(_purposeCtrl, context.tr('projectPurpose'), lines: 3),
                      _textField(_outcomesCtrl, context.tr('projectOutcomes'), lines: 3),
                      _textField(_skillsCtrl, context.tr('projectSkills'), lines: 2),
                    ]),
                    _section('3. ${context.tr('projectDescription')}', [
                      _textField(_shortDescCtrl, context.tr('projectShortDesc'), lines: 2),
                      _textField(_scopeCtrl, context.tr('projectScope'), lines: 2),
                      _textField(_teacherNotesCtrl, context.tr('projectTeacherNotes'), lines: 2),
                    ]),
                    _section('4. ${context.tr('projectSteps')}', [
                      ..._steps.asMap().entries.map((e) => _stepTile(e.key, e.value)),
                      TextButton.icon(
                        onPressed: _addStep,
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('addStep')),
                      ),
                    ]),
                    _section('5. ${context.tr('projectMaterials')}', [
                      _textField(_materialsCtrl, context.tr('projectMaterials'), lines: 3),
                    ]),
                    _section('6. ${context.tr('projectEvaluation')}', [
                      _textField(_contentCriteriaCtrl, context.tr('projectContentCriteria')),
                      _textField(_participationCriteriaCtrl, context.tr('projectParticipationCriteria')),
                      _textField(_presentationCriteriaCtrl, context.tr('projectPresentationCriteria')),
                      _textField(_timeCriteriaCtrl, context.tr('projectTimeCriteria')),
                    ]),
                    _section('7. ${context.tr('projectNotes')}', [
                      _textField(_processNotesCtrl, context.tr('projectProcessNotes'), lines: 2),
                      _textField(_observationsCtrl, context.tr('projectObservations'), lines: 2),
                      _textField(_devNotesCtrl, context.tr('projectDevNotes'), lines: 2),
                    ]),
                    _section('8. ${context.tr('projectStatus')}', [
                      DropdownButtonFormField<ProjectStatus>(
                        value: _status,
                        decoration: InputDecoration(labelText: context.tr('projectStatus')),
                        items: ProjectStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                        onChanged: (v) => setState(() => _status = v ?? _status),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        maxLines: lines,
      ),
    );
  }

  Widget _dateField(String label, DateTime date, void Function(DateTime) onChanged) {
    return ListTile(
      title: Text(label),
      subtitle: Text('${date.day}/${date.month}/${date.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onChanged(d);
      },
    );
  }

  Widget _stepTile(int index, ProjectStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(step.title),
        subtitle: Text(step.description),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => setState(() => _steps.removeAt(index)),
        ),
        onTap: () {
          final titleCtrl = TextEditingController(text: step.title);
          final descCtrl = TextEditingController(text: step.description);
          final durCtrl = TextEditingController(text: step.estimatedDuration);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(context.tr('editStep')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: context.tr('stepTitle'))),
                  TextField(controller: descCtrl, decoration: InputDecoration(labelText: context.tr('stepDescription')), maxLines: 2),
                  TextField(controller: durCtrl, decoration: InputDecoration(labelText: context.tr('stepDuration'))),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
                FilledButton(
                  onPressed: () {
                    setState(() => _steps[index] = ProjectStep(id: step.id, title: titleCtrl.text, description: descCtrl.text, estimatedDuration: durCtrl.text));
                    Navigator.pop(ctx);
                  },
                  child: Text(context.tr('save')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addStep() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('addStep')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: InputDecoration(labelText: context.tr('stepTitle'))),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: context.tr('stepDescription')), maxLines: 2),
            TextField(controller: durCtrl, decoration: InputDecoration(labelText: context.tr('stepDuration'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          FilledButton(
            onPressed: () {
              setState(() => _steps.add(ProjectStep(
                id: AppRepository.generateId(),
                title: titleCtrl.text,
                description: descCtrl.text,
                estimatedDuration: durCtrl.text,
              )));
              Navigator.pop(ctx);
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  String _typeLabel(ProjectType t) {
    switch (t) {
      case ProjectType.inClass: return context.tr('projectTypeInClass');
      case ProjectType.semester: return context.tr('projectTypeSemester');
      case ProjectType.social: return context.tr('projectTypeSocial');
      case ProjectType.club: return context.tr('projectTypeClub');
    }
  }

  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.draft: return context.tr('projectStatusDraft');
      case ProjectStatus.inProgress: return context.tr('projectStatusInProgress');
      case ProjectStatus.completed: return context.tr('projectStatusCompleted');
      case ProjectStatus.archived: return context.tr('projectStatusArchived');
    }
  }

  Widget _classSelector(List<String> classes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showClassPicker(classes),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: context.tr('projectClass'),
            hintText: context.tr('selectClasses'),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            _selectedClasses.isEmpty
                ? ''
                : (_selectedClasses.length <= 4
                    ? _selectedClasses.join(', ')
                    : '${_selectedClasses.length} ${context.tr('classesSelected')}'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  void _showClassPicker(List<String> classes) {
    var selected = List<String>.from(_selectedClasses);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx3, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('selectClasses'), style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
                        FilledButton(
                          onPressed: () {
                            setState(() => _selectedClasses = selected);
                            Navigator.pop(ctx);
                          },
                          child: Text(context.tr('ok')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: classes.length,
                  itemBuilder: (_, i) {
                    final c = classes[i];
                    final isSelected = selected.contains(c);
                    return CheckboxListTile(
                      title: Text(c),
                      value: isSelected,
                      onChanged: (_) {
                        setModalState(() {
                          if (isSelected) {
                            selected.remove(c);
                          } else {
                            selected.add(c);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildClassList() {
    final list = <String>[];
    for (final g in AppConstants.grades) {
      for (final b in AppConstants.branches) {
        list.add('$g$b');
      }
    }
    return list;
  }
}
