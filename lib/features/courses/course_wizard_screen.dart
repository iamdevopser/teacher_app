import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/course.dart';
import '../../data/models/course_models.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/repositories/app_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/course_file_storage_service.dart';
import '../../data/services/daily_plan_file_service.dart';
import '../lesson_planner/lesson_document_dialog.dart';
import 'course_wizard_controller.dart';

/// Adım adım kurs oluşturma sihirbazı.
/// [CourseWizardController] üst rotada [ChangeNotifierProvider] ile verilmelidir.
class CourseWizardScreen extends StatefulWidget {
  const CourseWizardScreen({super.key});

  @override
  State<CourseWizardScreen> createState() => _CourseWizardScreenState();
}

class _CourseWizardScreenState extends State<CourseWizardScreen>
    with WidgetsBindingObserver {
  late final CourseWizardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<CourseWizardController>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadPersistedDraft();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.flushPersistNow();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _controller.flushPersistNow();
    }
  }

  void _next() {
    final step = _controller.step;
    if (step == 0) {
      final c = _controller.course;
      final cat = c.effectiveCategory;
      if (cat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('courseCategoryRequired'))),
        );
        return;
      }
      if (c.category.trim() != cat || c.subject.trim() != cat) {
        _controller.setCourse(c.copyWith(category: cat, subject: cat));
      }
    }
    if (step < 2) _controller.setStep(step + 1);
  }

  void _prev() {
    if (_controller.step > 0) _controller.setStep(_controller.step - 1);
  }

  Future<void> _save() async {
    final repo = context.read<AppProvider>().repo;
    if (_controller.isEditing) {
      await repo.updateCourse(_controller.course);
    } else {
      await repo.addCourse(_controller.course);
    }
    await _controller.clearPersistedDraft();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CourseWizardController>();
    final profile = context.watch<AppProvider>().profile;
    final taught = profile?.classesTaught;
    final classes = (taught != null && taught.isNotEmpty)
        ? taught
        : AppConstants.allClasses;
    final step = ctrl.step;

    return Scaffold(
      appBar: AppBar(
        title: Text(step == 0
            ? (ctrl.isEditing
                ? context.tr('edit')
                : context.tr('newCourse'))
            : '${context.tr('step')} ${step + 1}/3'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [AppBarActions()],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (step + 1) / 3,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(classes, ctrl),
            ),
          ),
          _buildBottomBar(step),
        ],
      ),
    );
  }

  Widget _buildStepContent(List<String> classes, CourseWizardController ctrl) {
    return IndexedStack(
      index: ctrl.step,
      alignment: Alignment.topCenter,
      children: [
        _Step1BasicInfo(
          course: ctrl.course,
          classes: classes,
          onChanged: _controller.setCourse,
        ),
        _Step2Structure(
          course: ctrl.course,
          classes: classes,
          onChanged: _controller.setCourse,
        ),
        _Step3Activities(
          course: ctrl.course,
          onChanged: _controller.setCourse,
        ),
      ],
    );
  }

  Widget _buildBottomBar(int step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: step > 0 ? _prev : null,
            child: Text(context.tr('back')),
          ),
          if (step < 2)
            FilledButton(
              onPressed: _next,
              child: Text(context.tr('next')),
            )
          else
            FilledButton(
              onPressed: () => _save(),
              child: Text(context.tr('saveCourse')),
            ),
        ],
      ),
    );
  }
}

class _Step1BasicInfo extends StatelessWidget {
  const _Step1BasicInfo({
    required this.course,
    required this.classes,
    required this.onChanged,
  });

  final Course course;
  final List<String> classes;
  final ValueChanged<Course> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('1️⃣ ${context.tr('newCourse')}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        _CreationDateField(
          date: course.createdAt,
          onChanged: (d) => onChanged(course.copyWith(createdAt: d, updatedAt: DateTime.now())),
        ),
        _LtrTextField(
          label: context.tr('preparedByTeacher'),
          value: course.teacherName ?? '',
          hint: context.tr('teacherName'),
          onChanged: (v) => onChanged(course.copyWith(teacherName: v.isEmpty ? null : v)),
        ),
        _LtrTextField(
          label: context.tr('courseCategory'),
          value: course.category.isNotEmpty ? course.category : course.subject,
          hint: context.tr('courseCategoryHint'),
          onChanged: (v) => onChanged(
            course.copyWith(category: v, subject: v),
          ),
        ),
        _LtrTextField(
          label: context.tr('courseName'),
          value: course.name,
          hint: context.tr('hintCourseName'),
          onChanged: (v) => onChanged(course.copyWith(name: v)),
        ),
        const SizedBox(height: 12),
        Text(context.tr('classLevel'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ClassMultiSelect(
          selectedClasses: course.classId.isEmpty ? [] : course.classId.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
          availableClasses: classes,
          onChanged: (list) => onChanged(course.copyWith(classId: list.join(','))),
        ),
        const SizedBox(height: 16),
        _LtrTextField(
          label: context.tr('purpose'),
          value: course.purpose ?? '',
          hint: context.tr('purpose'),
          maxLines: 3,
          onChanged: (v) => onChanged(course.copyWith(purpose: v.isEmpty ? null : v)),
        ),
        const SizedBox(height: 16),
        Text(context.tr('courseOutcomes'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...course.outcomes.asMap().entries.map((e) {
          return _LtrOutcomeField(
            label: '${context.tr('outcome')} ${e.key + 1}',
            value: e.value.text,
            onChanged: (v) {
              final updated = List<CourseOutcome>.from(course.outcomes);
              updated[e.key] = CourseOutcome(id: e.value.id, text: v, type: e.value.type);
              onChanged(course.copyWith(outcomes: updated));
            },
            onDelete: () {
              final updated = List<CourseOutcome>.from(course.outcomes)..removeAt(e.key);
              onChanged(course.copyWith(outcomes: updated));
            },
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            final updated = List<CourseOutcome>.from(course.outcomes)
              ..add(CourseOutcome(id: AppRepository.generateId(), text: '', type: 'general'));
            onChanged(course.copyWith(outcomes: updated));
          },
          icon: const Icon(Icons.add),
          label: Text(context.tr('addOutcome')),
        ),
        const SizedBox(height: 16),
        _NumberField(
          label: context.tr('totalHours'),
          value: course.weeklyHours,
          onChanged: (v) => onChanged(course.copyWith(weeklyHours: v)),
        ),
        _LtrTextField(
          label: context.tr('targetAudience'),
          value: course.targetAudience ?? '',
          hint: context.tr('hintTargetAudience'),
          onChanged: (v) =>
              onChanged(course.copyWith(targetAudience: v.isEmpty ? null : v)),
        ),
      ],
    );
  }
}

/// Adım 1 textbox'ları için LTR düzeltmesi - StatefulWidget + Directionality
class _LtrTextField extends StatefulWidget {
  const _LtrTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final int maxLines;

  @override
  State<_LtrTextField> createState() => _LtrTextFieldState();
}

class _LtrTextFieldState extends State<_LtrTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LtrTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintTextDirection: TextDirection.ltr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              maxLines: widget.maxLines,
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Çoklu sınıf seçimi
class _ClassMultiSelect extends StatelessWidget {
  const _ClassMultiSelect({
    required this.selectedClasses,
    required this.availableClasses,
    required this.onChanged,
  });

  final List<String> selectedClasses;
  final List<String> availableClasses;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...selectedClasses.map((c) => Chip(
            label: Text(c),
            onDeleted: () {
              final updated = List<String>.from(selectedClasses)..remove(c);
              onChanged(updated);
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
                  selected: selectedClasses,
                ),
              );
              if (picked != null) onChanged(picked);
            },
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
            Text('${_selected.length} ${context.tr('classesSelected')}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(context.tr('ok')),
        ),
      ],
    );
  }
}

/// Adım 2 form alanları için LTR - label InputDecoration içinde
class _LtrInlineField extends StatefulWidget {
  const _LtrInlineField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<_LtrInlineField> createState() => _LtrInlineFieldState();
}

class _LtrInlineFieldState extends State<_LtrInlineField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LtrInlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintTextDirection: TextDirection.ltr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// Sınıf alanı (classes boşsa) - LTR düzeltmesi
class _LtrClassField extends StatefulWidget {
  const _LtrClassField({
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_LtrClassField> createState() => _LtrClassFieldState();
}

class _LtrClassFieldState extends State<_LtrClassField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LtrClassField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintTextDirection: TextDirection.ltr,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// Kazanım alanı - LTR düzeltmesi
class _LtrOutcomeField extends StatefulWidget {
  const _LtrOutcomeField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onDelete,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onDelete;

  @override
  State<_LtrOutcomeField> createState() => _LtrOutcomeFieldState();
}

class _LtrOutcomeFieldState extends State<_LtrOutcomeField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_LtrOutcomeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintTextDirection: TextDirection.ltr,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                maxLines: 2,
                onChanged: widget.onChanged,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: widget.onDelete),
        ],
      ),
    );
  }
}

class _CreationDateField extends StatelessWidget {
  const _CreationDateField({required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('creationDate'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            title: Text('${date.day}/${date.month}/${date.year}'),
            trailing: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (d != null) onChanged(d);
            },
          ),
        ],
      ),
    );
  }
}

class _Step2Structure extends StatefulWidget {
  const _Step2Structure({
    required this.course,
    required this.classes,
    required this.onChanged,
  });

  final Course course;
  final List<String> classes;
  final ValueChanged<Course> onChanged;

  @override
  State<_Step2Structure> createState() => _Step2StructureState();
}

class _Step2StructureState extends State<_Step2Structure> {
  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('2️⃣ ${context.tr('courseStructure')}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          context.tr('unitHierarchyDesc'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...course.structure.asMap().entries.map((e) => _buildUnitCard(e.key, e.value)),
        OutlinedButton.icon(
          onPressed: () => _addUnit(),
          icon: const Icon(Icons.add),
          label: Text(context.tr('addUnit')),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _addTopicToLastUnit(),
          icon: const Icon(Icons.add),
          label: Text(context.tr('addTopic')),
        ),
      ],
    );
  }

  Widget _buildUnitCard(int unitIndex, CourseStructureItem unit) {
    return Card(
      key: ValueKey(unit.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle),
        title: Row(
          children: [
            Expanded(child: Text('${context.tr('unitNo')} ${unit.orderNo}: ${unit.title}')),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: context.tr('deleteUnit'),
              onPressed: () => _deleteUnit(unitIndex),
            ),
          ],
        ),
        subtitle: unit.description != null
            ? Text(unit.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LtrInlineField(
                  label: context.tr('unitNo'),
                  value: unit.orderNo.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateUnit(unitIndex, unit.copyWith(orderNo: int.tryParse(v) ?? 1)),
                ),
                const SizedBox(height: 8),
                _LtrInlineField(
                  label: context.tr('unitName'),
                  value: unit.title,
                  onChanged: (v) => _updateUnit(unitIndex, unit.copyWith(title: v)),
                ),
                const SizedBox(height: 8),
                _LtrInlineField(
                  label: context.tr('description'),
                  value: unit.description ?? '',
                  maxLines: 2,
                  onChanged: (v) => _updateUnit(unitIndex, unit.copyWith(description: v.isEmpty ? null : v)),
                ),
                const SizedBox(height: 8),
                _LtrInlineField(
                  label: context.tr('estimatedLessonHours'),
                  value: unit.estimatedMinutes > 0 ? (unit.estimatedMinutes / 60).toString().replaceAll(RegExp(r'\.0$'), '') : '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final hours = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                    _updateUnit(unitIndex, unit.copyWith(estimatedMinutes: (hours * 60).round()));
                  },
                ),
                const SizedBox(height: 16),
                ...unit.children.asMap().entries.map((e) => _buildTopicCard(unitIndex, e.key, e.value)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _addTopic(unitIndex),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('addTopic')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(int unitIndex, int topicIndex, CourseStructureItem topic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text('${context.tr('topicNo')} ${topic.orderNo}: ${topic.title}')),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: context.tr('deleteTopic'),
              onPressed: () => _deleteTopic(unitIndex, topicIndex),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LtrInlineField(
                  label: context.tr('topicNo'),
                  value: topic.orderNo.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _updateTopic(unitIndex, topicIndex, topic.copyWith(orderNo: int.tryParse(v) ?? 1)),
                ),
                const SizedBox(height: 8),
                _LtrInlineField(
                  label: context.tr('topicName'),
                  value: topic.title,
                  onChanged: (v) => _updateTopic(unitIndex, topicIndex, topic.copyWith(title: v)),
                ),
                const SizedBox(height: 12),
                if (topic.lessonPlanPath != null)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(topic.lessonPlanTitle ?? context.tr('selectLessonPlan')),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _updateTopic(unitIndex, topicIndex, topic.copyWith(lessonPlanPath: null, lessonPlanTitle: null)),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _selectLessonPlan(unitIndex, topicIndex, topic),
                    icon: const Icon(Icons.description),
                    label: Text(context.tr('selectLessonPlan')),
                  ),
                const SizedBox(height: 8),
                if (topic.contents.isNotEmpty) ...[
                  ...topic.contents.map((c) => ListTile(
                    dense: true,
                    leading: Icon(_iconForContentType(c.type), size: 20),
                    title: Text(c.title.isNotEmpty ? c.title : (c.data ?? '-'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: c.data != null && c.data!.startsWith('http') ? Text(c.data!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        final updated = List<LessonContentItem>.from(topic.contents)..remove(c);
                        _updateTopic(unitIndex, topicIndex, topic.copyWith(contents: updated));
                      },
                    ),
                  )),
                  const SizedBox(height: 4),
                ],
                OutlinedButton.icon(
                  onPressed: () => _addDocument(unitIndex, topicIndex, topic),
                  icon: const Icon(Icons.folder_open),
                  label: Text(context.tr('addDocumentButton')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateUnit(int index, CourseStructureItem updated) {
    final list = List<CourseStructureItem>.from(widget.course.structure);
    list[index] = updated;
    widget.onChanged(widget.course.copyWith(structure: list));
  }

  IconData _iconForContentType(String type) {
    switch (type.toLowerCase()) {
      case 'link': return Icons.link;
      case 'pdf': return Icons.picture_as_pdf;
      case 'word': return Icons.description;
      case 'video': return Icons.video_file;
      case 'audio': return Icons.audiotrack;
      case 'image': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  void _updateTopic(int unitIndex, int topicIndex, CourseStructureItem updated) {
    final list = List<CourseStructureItem>.from(widget.course.structure);
    final unit = list[unitIndex];
    final topics = List<CourseStructureItem>.from(unit.children);
    topics[topicIndex] = updated;
    list[unitIndex] = unit.copyWith(children: topics);
    widget.onChanged(widget.course.copyWith(structure: list));
  }

  void _addUnit() {
    final updated = List<CourseStructureItem>.from(widget.course.structure)
      ..add(CourseStructureItem(
        id: AppRepository.generateId(),
        title: context.tr('newUnit'),
        orderIndex: widget.course.structure.length,
        orderNo: widget.course.structure.length + 1,
      ));
    widget.onChanged(widget.course.copyWith(structure: updated));
  }

  void _addTopic(int unitIndex) {
    final list = List<CourseStructureItem>.from(widget.course.structure);
    final unit = list[unitIndex];
    final topics = List<CourseStructureItem>.from(unit.children)
      ..add(CourseStructureItem(
        id: AppRepository.generateId(),
        title: '',
        orderIndex: unit.children.length,
        orderNo: unit.children.length + 1,
      ));
    list[unitIndex] = unit.copyWith(children: topics);
    widget.onChanged(widget.course.copyWith(structure: list));
  }

  void _addTopicToLastUnit() {
    if (widget.course.structure.isEmpty) {
      _addUnit();
      return;
    }
    _addTopic(widget.course.structure.length - 1);
  }

  Future<void> _deleteUnit(int unitIndex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteUnit')),
        content: Text(context.tr('deleteUnitConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      final list = List<CourseStructureItem>.from(widget.course.structure)..removeAt(unitIndex);
      widget.onChanged(widget.course.copyWith(structure: list));
    }
  }

  Future<void> _deleteTopic(int unitIndex, int topicIndex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteTopic')),
        content: Text(context.tr('deleteTopicConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      final list = List<CourseStructureItem>.from(widget.course.structure);
      final unit = list[unitIndex];
      final topics = List<CourseStructureItem>.from(unit.children)..removeAt(topicIndex);
      list[unitIndex] = unit.copyWith(children: topics);
      widget.onChanged(widget.course.copyWith(structure: list));
    }
  }

  Future<void> _selectLessonPlan(int unitIndex, int topicIndex, CourseStructureItem topic) async {
    final plans = context.read<AppProvider>().repo.getDailyLessonPlans();
    if (plans.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('noPlansYet'))),
        );
      }
      return;
    }
    final selected = await showDialog<DailyLessonPlan>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('selectLessonPlan')),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: plans.length,
            itemBuilder: (_, i) {
              final p = plans[i];
              return ListTile(
                title: Text('${p.subjectName} - ${p.classId}'),
                subtitle: Text(p.topic, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(ctx, p),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      final path = await DailyPlanFileService.generatePlanFile(selected);
      if (path != null) {
        _updateTopic(unitIndex, topicIndex, topic.copyWith(
          lessonPlanPath: path,
          lessonPlanTitle: '${selected.subjectName} - ${selected.classId}',
        ));
      }
    }
  }

  Future<void> _addDocument(int unitIndex, int topicIndex, CourseStructureItem topic) async {
    final doc = await showDialog<LessonDocument>(
      context: context,
      builder: (_) => const LessonDocumentDialog(hideClassSelector: true),
    );
    if (doc != null && doc.pathOrUrl != null && doc.pathOrUrl!.isNotEmpty && mounted) {
      String? storedPathOrUrl = doc.pathOrUrl;
      final isUrl = storedPathOrUrl!.startsWith('http://') ||
          storedPathOrUrl.startsWith('https://');
      if (!isUrl) {
        final unit = widget.course.structure[unitIndex];
        try {
          storedPathOrUrl = await CourseFileStorageService.copyToTopicFiles(
            sourcePath: storedPathOrUrl,
            courseName: widget.course.displayName,
            unitName: unit.title,
            topicName: topic.title,
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Dosya kopyalanamadi. Kayit islemi iptal edildi.',
                ),
              ),
            );
          }
          return;
        }
      }
      final content = LessonContentItem(
        id: doc.id,
        type: doc.format.toLowerCase(),
        title: doc.name,
        data: storedPathOrUrl,
        orderIndex: topic.contents.length,
      );
      final list = List<CourseStructureItem>.from(widget.course.structure);
      final unit = list[unitIndex];
      final topics = List<CourseStructureItem>.from(unit.children);
      final t = topics[topicIndex];
      topics[topicIndex] = t.copyWith(contents: [...t.contents, content]);
      list[unitIndex] = unit.copyWith(children: topics);
      widget.onChanged(widget.course.copyWith(structure: list));
    }
  }
}

class _Step3Activities extends StatelessWidget {
  const _Step3Activities({required this.course, required this.onChanged});

  final Course course;
  final ValueChanged<Course> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('3️⃣ ${context.tr('step3ActivitiesTitle')}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          context.tr('step6Features'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _showAddActivityDialog(context, course: course, onChanged: onChanged),
          icon: const Icon(Icons.assignment),
          label: Text(context.tr('addActivity')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddGameDialog(context, course: course, onChanged: onChanged),
          icon: const Icon(Icons.sports_esports),
          label: Text(context.tr('addGame')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddQuizDialog(context, course: course, onChanged: onChanged),
          icon: const Icon(Icons.quiz),
          label: Text(context.tr('addQuiz')),
        ),
        if (course.postLessonActivities.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(context.tr('step6Title'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...course.postLessonActivities.asMap().entries.map((e) {
            final item = e.value;
            final type = item['type'] as String? ?? '';
            final title = item['name'] as String? ?? item['title'] as String? ?? '-';
            final rawItems = item['instructionItems'];
            final instructionItems = <Map<String, String>>[];
            if (rawItems is List) {
              for (final x in rawItems) {
                if (x is Map) {
                  final m = Map<String, dynamic>.from(x);
                  final t = m['type']?.toString() ?? 'text';
                  final c = m['content']?.toString() ?? m['data']?.toString() ?? '';
                  instructionItems.add({'type': t, 'content': c});
                }
              }
            }
            final quizLink = item['quizFileOrLink'] as String?;
            final hasQuizLink = type == 'quiz' && quizLink != null && quizLink.isNotEmpty;
            final quizMode = item['quizMode'] as String? ?? 'manual';
            final rawQuizQs = item['questions'];
            var manualQuizQuestionCount = 0;
            if (type == 'quiz' &&
                quizMode == 'manual' &&
                rawQuizQs is List) {
              manualQuizQuestionCount = rawQuizQs.length;
            }
            final docCount = instructionItems.length + (hasQuizLink ? 1 : 0);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: Icon(_iconForType(type)),
                title: Text('$title ($type)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (manualQuizQuestionCount > 0)
                      Chip(
                        label: Text(
                          '$manualQuizQuestionCount ${context.tr('quizQuestionsBadgeSuffix')}',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (docCount > 0)
                      Chip(
                        label: Text('$docCount ${docCount == 1 ? context.tr('document') : context.tr('documents')}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: context.tr('edit'),
                      onPressed: () => _openEditDialog(context, e.key, item, course, onChanged),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: context.tr('delete'),
                      onPressed: () {
                        final updated = List<Map<String, dynamic>>.from(course.postLessonActivities)..removeAt(e.key);
                        onChanged(course.copyWith(postLessonActivities: updated));
                      },
                    ),
                  ],
                ),
                children: _buildActivityExpandContent(context, item, instructionItems),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _openEditDialog(BuildContext context, int index, Map<String, dynamic> item, Course course, ValueChanged<Course> onChanged) {
    final type = item['type'] as String? ?? '';
    if (type == 'activity') {
      _showAddActivityDialog(context, course: course, onChanged: onChanged, editIndex: index, existing: item);
    } else if (type == 'game') {
      _showAddGameDialog(context, course: course, onChanged: onChanged, editIndex: index, existing: item);
    } else if (type == 'quiz') {
      _showAddQuizDialog(context, course: course, onChanged: onChanged, editIndex: index, existing: item);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'activity': return Icons.assignment;
      case 'game': return Icons.sports_esports;
      case 'quiz': return Icons.quiz;
      default: return Icons.circle;
    }
  }

  List<Widget> _buildActivityExpandContent(BuildContext context, Map<String, dynamic> item, List<Map<String, String>> instructionItems) {
    final type = item['type'] as String? ?? '';
    final children = <Widget>[];
    if (type == 'activity') {
      final instructions = item['instructions'] as String? ?? '';
      if (instructions.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('activityInstructions'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(instructions, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ));
      }
    } else if (type == 'game') {
      final rules = item['gameRules'] as String? ?? item['rules'] as String? ?? '';
      if (rules.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('gameRules'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(rules, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ));
      }
    } else if (type == 'quiz') {
      final quizLink = item['quizFileOrLink'] as String?;
      if (quizLink != null && quizLink.isNotEmpty) {
        final isUrl = quizLink.startsWith('http://') || quizLink.startsWith('https://');
        children.add(_activityDocTile(context, {'type': isUrl ? 'link' : 'file', 'content': quizLink}));
      }
    }
    if (instructionItems.isNotEmpty) {
      if (children.isNotEmpty) children.add(const Divider(height: 1));
      children.addAll(instructionItems.map((doc) => _activityDocTile(context, doc)));
    }
    if (children.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(16),
        child: Text(context.tr('noDocuments'), style: Theme.of(context).textTheme.bodySmall),
      ));
    }
    return children;
  }

  Widget _activityDocTile(BuildContext context, Map<String, String> doc) {
    final type = doc['type'] ?? 'text';
    final content = doc['content'] ?? '';
    IconData icon = Icons.text_fields;
    if (type == 'file') icon = Icons.insert_drive_file;
    else if (type == 'video') icon = Icons.video_file;
    else if (type == 'audio') icon = Icons.audiotrack;
    else if (type == 'link') icon = Icons.link;
    final isUrl = content.startsWith('http://') || content.startsWith('https://');
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(content.length > 60 ? '${content.substring(0, 60)}...' : content, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: isUrl ? () async {
        final uri = Uri.tryParse(content);
        if (uri != null) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (_) {}
        }
      } : null,
    );
  }

  void _showAddActivityDialog(BuildContext context, {Course? course, ValueChanged<Course>? onChanged, int? editIndex, Map<String, dynamic>? existing}) {
    final c = course ?? this.course;
    final o = onChanged ?? this.onChanged;
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final outcomeCtrl = TextEditingController(text: existing?['targetedOutcome'] as String? ?? '');
    final instructionsCtrl = TextEditingController(text: existing?['instructions'] as String? ?? '');
    final noteCtrl = TextEditingController(text: existing?['teacherNote'] as String? ?? '');
    final durationVal = (existing?['duration'] as int?) ?? 0;
    final durationCtrl = TextEditingController(text: durationVal > 0 ? durationVal.toString() : '');
    String activityType = existing?['activityType'] as String? ?? 'individual';
    int duration = durationVal;
    final rawItems = existing?['instructionItems'];
    List<Map<String, String>> instructionItems = [];
    if (rawItems is List) {
      for (final x in rawItems) {
        if (x is Map) {
          final m = Map<String, dynamic>.from(x);
          instructionItems.add({
            'type': m['type']?.toString() ?? 'text',
            'content': m['content']?.toString() ?? m['data']?.toString() ?? '',
          });
        }
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => AlertDialog(
          title: Text(editIndex != null ? context.tr('edit') : context.tr('addActivity')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.tr('activityName'))),
                  const SizedBox(height: 12),
                  TextField(controller: outcomeCtrl, decoration: InputDecoration(labelText: context.tr('targetedOutcome')), maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: activityType,
                    decoration: InputDecoration(labelText: context.tr('activityType')),
                    items: [
                      DropdownMenuItem(value: 'individual', child: Text(context.tr('individual'))),
                      DropdownMenuItem(value: 'group', child: Text(context.tr('group'))),
                      DropdownMenuItem(value: 'inClass', child: Text(context.tr('inClass'))),
                    ],
                    onChanged: (v) => setModalState(() => activityType = v ?? 'individual'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: context.tr('durationMinutes')),
                    onChanged: (v) => duration = int.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('activityInstructions'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  TextField(controller: instructionsCtrl, decoration: InputDecoration(hintText: context.tr('activityInstructions')), maxLines: 4),
                  const SizedBox(height: 16),
                  Text(context.tr('activityDocuments'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  ...instructionItems.asMap().entries.map((e) => _instructionItemTile(ctx, setModalState, e.key, e.value, instructionItems, () => setModalState(() => instructionItems.removeAt(e.key)))),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _addInstructionChip(ctx, setModalState, 'text', instructionItems, context.tr('contentTypeText')),
                      _addInstructionChip(ctx, setModalState, 'file', instructionItems, context.tr('format')),
                      _addInstructionChip(ctx, setModalState, 'video', instructionItems, 'Video'),
                      _addInstructionChip(ctx, setModalState, 'audio', instructionItems, 'Audio'),
                      _addInstructionChip(ctx, setModalState, 'link', instructionItems, 'Link'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: noteCtrl, decoration: InputDecoration(labelText: context.tr('teacherNote')), maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                final item = {
                  'type': 'activity',
                  'name': nameCtrl.text.trim(),
                  'targetedOutcome': outcomeCtrl.text.trim(),
                  'activityType': activityType,
                  'duration': int.tryParse(durationCtrl.text) ?? duration,
                  'instructions': instructionsCtrl.text.trim(),
                  'instructionItems': instructionItems,
                  'teacherNote': noteCtrl.text.trim(),
                };
                final updated = List<Map<String, dynamic>>.from(c.postLessonActivities);
                if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
                  updated[editIndex!] = item;
                } else {
                  updated.add(item);
                }
                o(c.copyWith(postLessonActivities: updated));
                Navigator.pop(ctx);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionItemTile(BuildContext ctx, StateSetter setModalState, int i, Map<String, String> item, List<Map<String, String>> list, VoidCallback onRemove) {
    final type = item['type'] ?? 'text';
    final content = item['content'] ?? '';
    IconData icon = Icons.text_fields;
    if (type == 'file') icon = Icons.insert_drive_file;
    else if (type == 'video') icon = Icons.video_file;
    else if (type == 'audio') icon = Icons.audiotrack;
    else if (type == 'link') icon = Icons.link;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(content.length > 50 ? '${content.substring(0, 50)}...' : content, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setModalState(() => list.removeAt(i))),
    );
  }

  Widget _addInstructionChip(BuildContext ctx, StateSetter setModalState, String type, List<Map<String, String>> list, String label) {
    return ActionChip(
      avatar: Icon(_iconForInstructionType(type), size: 18),
      label: Text(label),
      onPressed: () => _addInstructionItem(ctx, setModalState, type, list),
    );
  }

  IconData _iconForInstructionType(String type) {
    switch (type) {
      case 'text': return Icons.text_fields;
      case 'file': return Icons.insert_drive_file;
      case 'video': return Icons.video_file;
      case 'audio': return Icons.audiotrack;
      case 'link': return Icons.link;
      default: return Icons.add;
    }
  }

  Future<void> _addInstructionItem(BuildContext ctx, StateSetter setModalState, String type, List<Map<String, String>> list) async {
    if (type == 'text') {
      final ctrl = TextEditingController();
      await showDialog(
        context: ctx,
        builder: (dctx) => AlertDialog(
          title: Text(ctx.tr('implementationGuide')),
          content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Metin girin')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx), child: Text(ctx.tr('cancel'))),
            FilledButton(onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                list.add({'type': 'text', 'content': ctrl.text.trim()});
                setModalState(() {});
              }
              Navigator.pop(dctx);
            }, child: Text(ctx.tr('save'))),
          ],
        ),
      );
    } else if (type == 'file') {
      final result = await FilePicker.platform.pickFiles(allowMultiple: false);
      if (result != null && result.files.single.path != null) {
        list.add({'type': 'file', 'content': result.files.single.path!});
        setModalState(() {});
      }
    } else if (type == 'link') {
      final ctrl = TextEditingController();
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) ctrl.text = data.text!.trim();
      await showDialog(
        context: ctx,
        builder: (dctx) => AlertDialog(
          title: const Text('Link ekle'),
          content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://...')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx), child: Text(ctx.tr('cancel'))),
            FilledButton(onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                list.add({'type': 'link', 'content': ctrl.text.trim()});
                setModalState(() {});
              }
              Navigator.pop(dctx);
            }, child: Text(ctx.tr('save'))),
          ],
        ),
      );
    } else {
      final ctrl = TextEditingController();
      final isFile = await showDialog<bool>(
        context: ctx,
        builder: (dctx) => AlertDialog(
          title: Text(type == 'video' ? 'Video ekle' : 'Ses ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.pop(dctx, true),
                icon: const Icon(Icons.folder_open),
                label: Text(ctx.tr('selectFileButton')),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(dctx, false),
                icon: const Icon(Icons.link),
                label: Text(ctx.tr('pasteUrl')),
              ),
            ],
          ),
        ),
      );
      if (isFile == true) {
        final result = await FilePicker.platform.pickFiles(allowMultiple: false);
        if (result != null && result.files.single.path != null) {
          list.add({'type': type, 'content': result.files.single.path!});
          setModalState(() {});
        }
      } else if (isFile == false) {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        if (data?.text?.trim().isNotEmpty ?? false) ctrl.text = data!.text!.trim();
        await showDialog(
          context: ctx,
          builder: (dctx) => AlertDialog(
            title: Text(type == 'video' ? 'Video URL' : 'Ses URL'),
            content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://...')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dctx), child: Text(ctx.tr('cancel'))),
              FilledButton(onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  list.add({'type': type, 'content': ctrl.text.trim()});
                  setModalState(() {});
                }
                Navigator.pop(dctx);
              }, child: Text(ctx.tr('save'))),
            ],
          ),
        );
      }
    }
  }

  void _showAddGameDialog(BuildContext context, {Course? course, ValueChanged<Course>? onChanged, int? editIndex, Map<String, dynamic>? existing}) {
    final c = course ?? this.course;
    final o = onChanged ?? this.onChanged;
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final rulesCtrl = TextEditingController(text: existing?['gameRules'] as String? ?? '');
    final materialsCtrl = TextEditingController(text: existing?['materials'] as String? ?? '');
    final guidanceCtrl = TextEditingController(text: existing?['teacherGuidance'] as String? ?? '');
    String gameType = existing?['gameType'] as String? ?? 'word';
    final durationVal = (existing?['duration'] as int?) ?? 0;
    final durationCtrl = TextEditingController(text: durationVal > 0 ? durationVal.toString() : '');
    int duration = durationVal;
    final rawItems = existing?['instructionItems'];
    List<Map<String, String>> instructionItems = [];
    if (rawItems is List) {
      for (final x in rawItems) {
        if (x is Map) {
          final m = Map<String, dynamic>.from(x);
          instructionItems.add({
            'type': m['type']?.toString() ?? 'text',
            'content': m['content']?.toString() ?? m['data']?.toString() ?? '',
          });
        }
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => AlertDialog(
          title: Text(editIndex != null ? context.tr('edit') : context.tr('addGame')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.tr('gameName'))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gameType,
                    decoration: InputDecoration(labelText: context.tr('gameType')),
                    items: [
                      DropdownMenuItem(value: 'word', child: const Text('Kelime / kavram oyunu')),
                      DropdownMenuItem(value: 'memory', child: const Text('Hafıza / eşleştirme')),
                      DropdownMenuItem(value: 'trueFalse', child: const Text('Doğru – yanlış')),
                      DropdownMenuItem(value: 'race', child: const Text('Zamanla yarış')),
                      DropdownMenuItem(value: 'roleplay', child: const Text('Rol canlandırma')),
                    ],
                    onChanged: (v) => setModalState(() => gameType = v ?? 'word'),
                  ),
                  const SizedBox(height: 12),
                  Text(context.tr('gameRules'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  TextField(controller: rulesCtrl, decoration: InputDecoration(hintText: context.tr('gameRules')), maxLines: 4),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: context.tr('durationMinutes')),
                    onChanged: (v) => duration = int.tryParse(v) ?? 0,
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: materialsCtrl, decoration: InputDecoration(labelText: context.tr('requiredMaterials')), maxLines: 2),
                  const SizedBox(height: 12),
                  Text(context.tr('gameDocuments'), style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  ...instructionItems.asMap().entries.map((e) => _instructionItemTile(ctx, setModalState, e.key, e.value, instructionItems, () => setModalState(() => instructionItems.removeAt(e.key)))),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _addInstructionChip(ctx, setModalState, 'text', instructionItems, context.tr('contentTypeText')),
                      _addInstructionChip(ctx, setModalState, 'file', instructionItems, context.tr('format')),
                      _addInstructionChip(ctx, setModalState, 'video', instructionItems, 'Video'),
                      _addInstructionChip(ctx, setModalState, 'audio', instructionItems, 'Audio'),
                      _addInstructionChip(ctx, setModalState, 'link', instructionItems, 'Link'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: guidanceCtrl, decoration: InputDecoration(labelText: context.tr('teacherGuidance')), maxLines: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                duration = int.tryParse(durationCtrl.text) ?? 0;
                final item = {
                  'type': 'game',
                  'name': nameCtrl.text.trim(),
                  'gameType': gameType,
                  'gameRules': rulesCtrl.text.trim(),
                  'instructionItems': instructionItems,
                  'duration': duration,
                  'materials': materialsCtrl.text.trim(),
                  'teacherGuidance': guidanceCtrl.text.trim(),
                };
                final updated = List<Map<String, dynamic>>.from(c.postLessonActivities);
                if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
                  updated[editIndex] = item;
                } else {
                  updated.add(item);
                }
                o(c.copyWith(postLessonActivities: updated));
                Navigator.pop(ctx);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuizDialog(BuildContext context, {Course? course, ValueChanged<Course>? onChanged, int? editIndex, Map<String, dynamic>? existing}) {
    final c = course ?? this.course;
    final o = onChanged ?? this.onChanged;
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final qfl = existing?['quizFileOrLink'] as String?;
    String quizMode = (qfl != null && qfl.isNotEmpty) ? 'file' : (existing?['quizMode'] as String? ?? 'manual');
    String quizType = existing?['quizType'] as String? ?? 'multipleChoice';
    final durationVal = (existing?['duration'] as int?) ?? 0;
    final durationCtrl = TextEditingController(text: durationVal > 0 ? durationVal.toString() : '');
    int duration = durationVal;
    String? quizFileOrLink = existing?['quizFileOrLink'] as String?;
    final quizShareId =
        existing?['quizShareId'] as String? ?? AppRepository.generateId();
    final existingTpq = existing?['timePerQuestion'] as int?;
    final timePerQCtrl = TextEditingController(
      text: (existingTpq != null && existingTpq > 0) ? '$existingTpq' : '',
    );
    final rawQuestions = existing?['questions'];
    List<Map<String, dynamic>> questions = [];
    if (rawQuestions is List) {
      for (final x in rawQuestions) {
        if (x is Map) {
          final m = Map<String, dynamic>.from(x);
          questions.add({
            'question': m['question']?.toString() ?? '',
            'options': List<String>.from(m['options'] as List? ?? ['', '']),
            'correctIndex': m['correctIndex'] as int? ?? 0,
          });
        }
      }
    }
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => AlertDialog(
          title: Text(editIndex != null ? context.tr('edit') : context.tr('addQuiz')),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: titleCtrl, decoration: InputDecoration(labelText: context.tr('quizTitle'))),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'file', label: Text(context.tr('quizAsFileOrLink')), icon: const Icon(Icons.insert_drive_file, size: 18)),
                      ButtonSegment(value: 'manual', label: Text(context.tr('addQuestionManually')), icon: const Icon(Icons.quiz, size: 18)),
                    ],
                    selected: {quizMode},
                    onSelectionChanged: (v) => setModalState(() => quizMode = v.first),
                  ),
                  const SizedBox(height: 12),
                  if (quizMode == 'file') ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(allowMultiple: false);
                        if (result != null && result.files.single.path != null) {
                          setModalState(() => quizFileOrLink = result.files.single.path);
                        }
                      },
                      icon: const Icon(Icons.folder_open),
                      label: Text(context.tr('selectFileButton')),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final ctrl = TextEditingController(text: data?.text?.trim() ?? '');
                        await showDialog(
                          context: ctx,
                          builder: (dctx) => AlertDialog(
                            title: const Text('Quiz linki'),
                            content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'https://...')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dctx), child: Text(context.tr('cancel'))),
                              FilledButton(onPressed: () {
                                if (ctrl.text.trim().isNotEmpty) {
                                  setModalState(() => quizFileOrLink = ctrl.text.trim());
                                }
                                Navigator.pop(dctx);
                              }, child: Text(context.tr('save'))),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.link),
                      label: Text(context.tr('pasteUrl')),
                    ),
                    if (quizFileOrLink != null) Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(quizFileOrLink!.length > 40 ? '${quizFileOrLink!.substring(0, 40)}...' : quizFileOrLink!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      value: quizType,
                      decoration: InputDecoration(labelText: context.tr('quizType')),
                      items: [
                        DropdownMenuItem(value: 'multipleChoice', child: const Text('Çoktan seçmeli')),
                        DropdownMenuItem(value: 'trueFalse', child: const Text('Doğru – yanlış')),
                        DropdownMenuItem(value: 'fillBlank', child: const Text('Boşluk doldurma')),
                        DropdownMenuItem(value: 'shortAnswer', child: const Text('Kısa cevap')),
                      ],
                      onChanged: (v) => setModalState(() => quizType = v ?? 'multipleChoice'),
                    ),
                    const SizedBox(height: 12),
                    ...questions.asMap().entries.map(
                          (e) => _QuizQuestionFieldCard(
                            key: ObjectKey(e.value),
                            questionMap: e.value,
                            questionIndexDisplay: e.key + 1,
                            onRemove: () =>
                                setModalState(() => questions.remove(e.value)),
                          ),
                        ),
                    OutlinedButton.icon(
                      onPressed: () => setModalState(() => questions.add({
                        'question': '',
                        'options': ['', ''],
                        'correctIndex': 0,
                      })),
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('addQuestion')),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${questions.length} ${context.tr('quizQuestionCountLabel')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  TextField(
                    controller: timePerQCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: context.tr('quizTimePerQuestion'),
                      hintText: context.tr('quizTimePerQuestionHint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SelectableText(
                          'teacherplanner://quiz/$quizShareId',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('quizCopyShareLink'),
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: 'teacherplanner://quiz/$quizShareId',
                            ),
                          );
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('quizLinkCopied')),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: context.tr('durationMinutes')),
                    onChanged: (v) => duration = int.tryParse(v) ?? 0,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                if (quizMode == 'manual' && questions.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(context.tr('quizNeedOneQuestion'))),
                  );
                  return;
                }
                final tpq = int.tryParse(timePerQCtrl.text.trim()) ?? 0;
                if (tpq < 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(context.tr('error'))),
                  );
                  return;
                }
                duration = int.tryParse(durationCtrl.text) ?? 0;
                final item = {
                  'type': 'quiz',
                  'title': titleCtrl.text.trim(),
                  'quizMode': quizMode,
                  'quizType': quizType,
                  'duration': duration,
                  'timePerQuestion': tpq,
                  'quizShareId': quizShareId,
                  if (quizMode == 'file') 'quizFileOrLink': quizFileOrLink,
                  if (quizMode == 'manual') 'questions': questions,
                };
                final updated = List<Map<String, dynamic>>.from(c.postLessonActivities);
                if (editIndex != null && editIndex >= 0 && editIndex < updated.length) {
                  updated[editIndex] = item;
                } else {
                  updated.add(item);
                }
                o(c.copyWith(postLessonActivities: updated));
                Navigator.pop(ctx);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

}

/// Manuel quiz soruları: controller'lar tek sefer oluşturulur (LTR + kalıcı düzenleme).
class _QuizQuestionFieldCard extends StatefulWidget {
  const _QuizQuestionFieldCard({
    super.key,
    required this.questionMap,
    required this.questionIndexDisplay,
    required this.onRemove,
  });

  final Map<String, dynamic> questionMap;
  final int questionIndexDisplay;
  final VoidCallback onRemove;

  @override
  State<_QuizQuestionFieldCard> createState() => _QuizQuestionFieldCardState();
}

class _QuizQuestionFieldCardState extends State<_QuizQuestionFieldCard> {
  late TextEditingController _questionCtrl;
  late List<TextEditingController> _optionCtrls;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(
      text: widget.questionMap['question'] as String? ?? '',
    );
    _questionCtrl.addListener(_syncQuestion);
    final opts = List<String>.from(
      widget.questionMap['options'] as List? ?? ['', ''],
    );
    _optionCtrls = opts.map((o) {
      final c = TextEditingController(text: o);
      c.addListener(_syncOptions);
      return c;
    }).toList();
  }

  @override
  void dispose() {
    _questionCtrl.removeListener(_syncQuestion);
    _questionCtrl.dispose();
    for (final c in _optionCtrls) {
      c.removeListener(_syncOptions);
      c.dispose();
    }
    super.dispose();
  }

  void _syncQuestion() {
    widget.questionMap['question'] = _questionCtrl.text;
  }

  void _syncOptions() {
    widget.questionMap['options'] =
        _optionCtrls.map((c) => c.text).toList();
  }

  @override
  Widget build(BuildContext context) {
    final correctRaw = widget.questionMap['correctIndex'] as int? ?? 0;
    final maxIdx = _optionCtrls.isEmpty ? 0 : _optionCtrls.length - 1;
    final groupValue = correctRaw.clamp(0, maxIdx);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    textDirection: TextDirection.ltr,
                    controller: _questionCtrl,
                    decoration: InputDecoration(
                      labelText:
                          '${context.tr('questionText')} ${widget.questionIndexDisplay}',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._optionCtrls.asMap().entries.map((e) {
              final idx = e.key;
              final ctrl = e.value;
              return Row(
                children: [
                  Radio<int>(
                    value: idx,
                    groupValue: groupValue,
                    onChanged: (v) {
                      setState(() {
                        widget.questionMap['correctIndex'] = v ?? 0;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      textDirection: TextDirection.ltr,
                      controller: ctrl,
                      decoration: InputDecoration(
                        labelText:
                            '${context.tr('answerOptions')} ${idx + 1}',
                      ),
                    ),
                  ),
                ],
              );
            }),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  final c = TextEditingController();
                  c.addListener(_syncOptions);
                  _optionCtrls.add(c);
                  _syncOptions();
                });
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('${context.tr('answerOptions')} ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint = '',
    this.maxLines = 1,
    this.textDirection,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String hint;
  final int maxLines;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: maxLines,
            textDirection: textDirection ?? TextDirection.ltr,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value > 0 ? widget.value.toString() : '');
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = widget.value > 0 ? widget.value.toString() : '';
      if (_controller.text != newText) {
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintTextDirection: TextDirection.ltr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              keyboardType: TextInputType.number,
              onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
            ),
          ),
        ],
      ),
    );
  }
}

