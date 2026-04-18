import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/repositories/app_repository.dart';

class DailyLessonPlanForm extends StatefulWidget {
  const DailyLessonPlanForm({
    this.plan,
    this.initialDate,
    this.teacherName = '',
    super.key,
  });

  final DailyLessonPlan? plan;
  final DateTime? initialDate;
  final String teacherName;

  @override
  State<DailyLessonPlanForm> createState() => _DailyLessonPlanFormState();
}

class _DailyLessonPlanFormState extends State<DailyLessonPlanForm> {
  final _subjectCtrl = TextEditingController();
  List<String> _selectedClasses = [];
  final _teacherCtrl = TextEditingController();
  final _weekNoCtrl = TextEditingController();
  final _lessonNoCtrl = TextEditingController();
  final _hourCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _devCtrl = TextEditingController();
  final _evalCtrl = TextEditingController();
  final _methodCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _lessonLinkCtrl = TextEditingController();
  final _lessonDurationCtrl = TextEditingController();
  final _linkedGroupCtrl = TextEditingController();

  late DateTime _date;
  bool _completed = false;
  bool _needsMakeup = false;
  bool _isPlanned = true;
  /// extra.md: face_to_face | online | hybrid
  String _lessonType = 'face_to_face';

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _date = p?.date ?? widget.initialDate ?? DateTime.now();
    _subjectCtrl.text = p?.subjectName ?? '';
    _selectedClasses = (p?.classId ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _teacherCtrl.text = p?.teacherName ?? widget.teacherName;
    _weekNoCtrl.text = (p?.weekNo ?? 0).toString();
    _lessonNoCtrl.text = (p?.lessonNo ?? 0).toString();
    _hourCtrl.text = p?.lessonHour ?? '';
    _topicCtrl.text = p?.topic ?? '';
    _outcomeCtrl.text = p?.outcome ?? '';
    _introCtrl.text = p?.intro ?? '';
    _devCtrl.text = p?.development ?? '';
    _evalCtrl.text = p?.evaluation ?? '';
    _methodCtrl.text = p?.method ?? '';
    _materialCtrl.text = p?.material ?? '';
    _noteCtrl.text = p?.lessonNote ?? '';
    _completed = p?.completed ?? false;
    _needsMakeup = p?.needsMakeup ?? false;
    _isPlanned = (p?.isPlanned ?? true) && !_completed && !_needsMakeup;
    _lessonType = p?.lessonType ?? 'face_to_face';
    _lessonLinkCtrl.text = p?.lessonLink ?? '';
    _lessonDurationCtrl.text = p?.lessonDurationMinutes?.toString() ?? '';
    _linkedGroupCtrl.text = p?.linkedGroupId ?? '';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _teacherCtrl.dispose();
    _weekNoCtrl.dispose();
    _lessonNoCtrl.dispose();
    _hourCtrl.dispose();
    _topicCtrl.dispose();
    _outcomeCtrl.dispose();
    _introCtrl.dispose();
    _devCtrl.dispose();
    _evalCtrl.dispose();
    _methodCtrl.dispose();
    _materialCtrl.dispose();
    _noteCtrl.dispose();
    _lessonLinkCtrl.dispose();
    _lessonDurationCtrl.dispose();
    _linkedGroupCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final plan = DailyLessonPlan(
      id: widget.plan?.id ?? AppRepository.generateId(),
      subjectName: _subjectCtrl.text.trim(),
      classId: _selectedClasses.join(', '),
      teacherName: _teacherCtrl.text.trim(),
      date: _date,
      weekNo: int.tryParse(_weekNoCtrl.text.trim()) ?? 0,
      lessonNo: int.tryParse(_lessonNoCtrl.text.trim()) ?? 0,
      lessonHour: _hourCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      outcome: _outcomeCtrl.text.trim(),
      intro: _introCtrl.text.trim(),
      development: _devCtrl.text.trim(),
      evaluation: _evalCtrl.text.trim(),
      method: _methodCtrl.text.trim(),
      material: _materialCtrl.text.trim(),
      lessonNote: _noteCtrl.text.trim(),
      completed: _completed,
      needsMakeup: _needsMakeup,
      isPlanned: _isPlanned,
      createdAt: widget.plan?.createdAt ?? DateTime.now(),
      lessonType: _lessonType,
      lessonLink: _lessonLinkCtrl.text.trim().isEmpty ? null : _lessonLinkCtrl.text.trim(),
      lessonDurationMinutes: int.tryParse(_lessonDurationCtrl.text.trim()),
      linkedGroupId: _linkedGroupCtrl.text.trim().isEmpty ? null : _linkedGroupCtrl.text.trim(),
    );
    Navigator.pop(context, plan);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppProvider>().profile;
    final classes = (profile?.classesTaught ?? []).isNotEmpty
        ? profile!.classesTaught!
        : AppConstants.allClasses;

    return Dialog(
      child: SizedBox(
        width: 500,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            AppBar(
              title: Text(widget.plan != null ? context.tr('editPlan') : context.tr('addDailyPlan')),
              actions: [
                const AppBarActions(),
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
                    _section('a. ${context.tr('sectionBasicInfo')}', [
                    _textField(_subjectCtrl, context.tr('subject')),
                    _classMultiSelect(classes),
                    _textField(_teacherCtrl, context.tr('teacherName')),
                    _dateField(),
                    _textField(_weekNoCtrl, context.tr('weekNo')),
                    _textField(_lessonNoCtrl, context.tr('lessonNo')),
                    _textField(_hourCtrl, context.tr('weeklyHours'), hint: context.tr('lessonHourHint')),
                    ]),
                    if (context.read<AppProvider>().repo.getSettingsOnlineLessonFeatures())
                      _section(context.tr('lessonType'), [
                        RadioListTile<String>(
                          title: Text(context.tr('lessonTypeFaceToFace')),
                          value: 'face_to_face',
                          groupValue: _lessonType,
                          onChanged: (v) => setState(() => _lessonType = v ?? 'face_to_face'),
                        ),
                        RadioListTile<String>(
                          title: Text(context.tr('lessonTypeOnline')),
                          value: 'online',
                          groupValue: _lessonType,
                          onChanged: (v) => setState(() => _lessonType = v ?? 'online'),
                        ),
                        RadioListTile<String>(
                          title: Text(context.tr('lessonTypeHybrid')),
                          value: 'hybrid',
                          groupValue: _lessonType,
                          onChanged: (v) => setState(() => _lessonType = v ?? 'hybrid'),
                        ),
                        if (_lessonType == 'online' || _lessonType == 'hybrid') ...[
                          _textField(_lessonLinkCtrl, context.tr('lessonLink')),
                          _textField(_lessonDurationCtrl, context.tr('lessonDurationMinutes')),
                          _textField(_linkedGroupCtrl, context.tr('linkedGroup')),
                        ],
                      ]),
                    _section('b. ${context.tr('sectionTopicOutcome')}', [
                    _textField(_topicCtrl, context.tr('topic'), lines: 2),
                    _textField(_outcomeCtrl, context.tr('outcome'), lines: 2),
                    ]),
                    _section('c. ${context.tr('sectionLessonFlow')}', [
                    _labeledField(_introCtrl, '${context.tr('intro')} (10 ${context.tr('minutesAbbr')})', lines: 2),
                    _labeledField(_devCtrl, '${context.tr('development')} (25 ${context.tr('minutesAbbr')})', lines: 3),
                    _labeledField(_evalCtrl, '${context.tr('result')} (10 ${context.tr('minutesAbbr')})', lines: 2),
                    ]),
                    _section('d. ${context.tr('sectionMethodMaterial')}', [
                      _textField(_methodCtrl, context.tr('method')),
                      _textField(_materialCtrl, context.tr('material')),
                    ]),
                    _section('e. ${context.tr('sectionNotes')}', [
                      _textField(_noteCtrl, context.tr('lessonNotesHint'), lines: 3),
                    ]),
                    _section('f. ${context.tr('sectionCompletion')}', [
                      RadioListTile<String>(
                        title: Text(context.tr('lessonPlanned')),
                        value: 'planned',
                        groupValue: _completed ? 'completed' : (_needsMakeup ? 'makeup' : 'planned'),
                        onChanged: (v) => setState(() {
                          _isPlanned = true;
                          _completed = false;
                          _needsMakeup = false;
                        }),
                      ),
                      RadioListTile<String>(
                        title: Text(context.tr('lessonCompleted')),
                        value: 'completed',
                        groupValue: _completed ? 'completed' : (_needsMakeup ? 'makeup' : 'planned'),
                        onChanged: (v) => setState(() {
                          _completed = true;
                          _isPlanned = false;
                          _needsMakeup = false;
                        }),
                      ),
                      RadioListTile<String>(
                        title: Text(context.tr('needsMakeup')),
                        value: 'makeup',
                        groupValue: _completed ? 'completed' : (_needsMakeup ? 'makeup' : 'planned'),
                        onChanged: (v) => setState(() {
                          _needsMakeup = true;
                          _isPlanned = false;
                          _completed = false;
                        }),
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

  Widget _labeledField(TextEditingController ctrl, String label, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        maxLines: lines,
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, {int lines = 1, String? hint, List<String>? dropdownItems}) {
    if (dropdownItems != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: ctrl.text.isEmpty ? null : (dropdownItems.contains(ctrl.text) ? ctrl.text : null),
          decoration: InputDecoration(labelText: label),
          items: dropdownItems.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => ctrl.text = v ?? ''),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, hintText: hint),
        maxLines: lines,
      ),
    );
  }

  Widget _dateField() {
    return ListTile(
      title: Text(context.tr('date')),
      subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (d != null) setState(() => _date = d);
      },
    );
  }

  Widget _classMultiSelect(List<String> availableClasses) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('classLevel'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          InputDecorator(
            decoration: InputDecoration(
              hintText: context.tr('selectClasses'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedClasses.map((c) => Chip(
                  label: Text(c),
                  onDeleted: () {
                    setState(() {
                      _selectedClasses = List<String>.from(_selectedClasses)..remove(c);
                    });
                  },
                )),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('selectClasses')),
                  onPressed: () async {
                    final picked = await showDialog<List<String>>(
                      context: context,
                      builder: (ctx) => _ClassPickerDialog(
                        available: availableClasses,
                        selected: _selectedClasses,
                      ),
                    );
                    if (picked != null) setState(() => _selectedClasses = picked);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassPickerDialog extends StatefulWidget {
  const _ClassPickerDialog({
    required this.available,
    required this.selected,
  });

  final List<String> available;
  final List<String> selected;

  @override
  State<_ClassPickerDialog> createState() => _ClassPickerDialogState();
}

class _ClassPickerDialogState extends State<_ClassPickerDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('classLevel')),
      content: SizedBox(
        width: 320,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.available.length,
                itemBuilder: (_, i) {
                  final c = widget.available[i];
                  final isSelected = _selected.contains(c);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(c),
                    onChanged: (_) {
                      setState(() {
                        if (isSelected) {
                          _selected.remove(c);
                        } else {
                          _selected.add(c);
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(context.tr('ok')),
        ),
      ],
    );
  }
}
