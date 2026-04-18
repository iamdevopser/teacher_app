import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/assessment.dart';
import '../../data/models/student.dart';
import '../../data/repositories/app_repository.dart';

/// Exams/assignments, simple score input
class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final profile = context.watch<AppProvider>().profile;
    final classes = profile?.classesTaught ?? [];
    _selectedClass ??= classes.isNotEmpty ? classes.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('assessments')),
        actions: const [AppBarActions()],
      ),
      body: Column(
        children: [
          if (classes.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: classes.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(c),
                      selected: _selectedClass == c,
                      onSelected: (_) => setState(() => _selectedClass = c),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _selectedClass == null
                ? const Center(child: Text(''))
                : _AssessmentsList(classId: _selectedClass!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'assessments_add_fab',
        onPressed: () => _showAddAssessment(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addAssessment')),
      ),
    );
  }

  void _showAddAssessment(BuildContext context) {
    final profile = context.read<AppProvider>().profile;
    if (profile == null || profile.classesTaught.isEmpty) return;

    String? selectedClass;
    String? selectedStudent;
    final subjectController = TextEditingController();
    final titleController = TextEditingController();
    final scoreController = TextEditingController();
    final commentsController = TextEditingController();
    var date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final c = selectedClass ?? _selectedClass;
          final students = c != null
              ? context.read<AppProvider>().repo.getStudentsByClass(c)
              : <Student>[];
          return Padding(
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
                    context.tr('addAssessment'),
                    style: Theme.of(ctx2).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedClass ?? _selectedClass,
                    decoration: InputDecoration(
                      labelText: context.tr('classLabel'),
                    ),
                    items: profile.classesTaught
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setModalState(() {
                      selectedClass = v;
                      selectedStudent = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStudent,
                    decoration: InputDecoration(
                      labelText: context.tr('studentLabel'),
                    ),
                    items: students
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => selectedStudent = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: context.tr('subject'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: context.tr('title')),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: scoreController,
                    decoration: InputDecoration(labelText: context.tr('score')),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: commentsController,
                    decoration: InputDecoration(
                      labelText: context.tr('comments'),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(context.tr('date')),
                    subtitle: Text('${date.day}/${date.month}/${date.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setModalState(() => date = picked);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: Text(context.tr('cancel')),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final c = selectedClass ?? _selectedClass;
                          if (c == null || selectedStudent == null) return;
                          final score =
                              double.tryParse(scoreController.text) ?? 0;
                          final assessment = Assessment(
                            id: AppRepository.generateId(),
                            studentId: selectedStudent!,
                            classId: c,
                            subject: subjectController.text.trim(),
                            title: titleController.text.trim(),
                            score: score,
                            comments: commentsController.text.trim(),
                            date: date,
                            createdAt: DateTime.now(),
                          );
                          await context.read<AppProvider>().repo.addAssessment(
                            assessment,
                          );
                          if (context.mounted) {
                            context.read<AppProvider>().refresh();
                            Navigator.pop(ctx2);
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
          );
        },
      ),
    );
  }
}

class _AssessmentsList extends StatelessWidget {
  const _AssessmentsList({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final students = repo.getStudentsByClass(classId);
    final studentMap = {for (var s in students) s.id: s};
    final assessments = repo.getAssessmentsByClass(classId);
    assessments.sort((a, b) => b.date.compareTo(a.date));

    if (assessments.isEmpty) {
      return Center(child: Text(context.tr('addAssessmentHint')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assessments.length,
      itemBuilder: (_, i) {
        final a = assessments[i];
        final student = studentMap[a.studentId];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${student?.name ?? a.studentId} - ${a.subject}'),
            subtitle: Text(
              '${a.title}: ${a.score} - ${a.date.day}/${a.date.month}/${a.date.year}',
            ),
          ),
        );
      },
    );
  }
}
