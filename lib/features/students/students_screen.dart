import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/student.dart';
import '../../data/repositories/app_repository.dart';

/// Student management: class-based lists, profiles
class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final profile = context.watch<AppProvider>().profile;
    final classes = profile?.classesTaught ?? [];
    _selectedClass ??= classes.isNotEmpty ? classes.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('students')),
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
                ? Center(child: Text(context.tr('noStudents')))
                : _StudentsList(classId: _selectedClass!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'students_add_fab',
        onPressed: () => _showAddStudent(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addStudent')),
      ),
    );
  }

  void _showAddStudent(BuildContext context) {
    final profile = context.read<AppProvider>().profile;
    if (profile == null || profile.classesTaught.isEmpty) return;

    String? selectedClass;
    final nameController = TextEditingController();
    final academicController = TextEditingController();
    final behavioralController = TextEditingController();

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
                context.tr('addStudent'),
                style: Theme.of(ctx).textTheme.titleLarge,
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
                onChanged: (v) => selectedClass = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.tr('studentName'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: academicController,
                decoration: InputDecoration(
                  labelText: context.tr('academicNotes'),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: behavioralController,
                decoration: InputDecoration(
                  labelText: context.tr('behavioralNotes'),
                ),
                maxLines: 2,
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
                      final c = selectedClass ?? _selectedClass;
                      if (c == null || nameController.text.trim().isEmpty)
                        return;
                      final student = Student(
                        id: AppRepository.generateId(),
                        classId: c,
                        name: nameController.text.trim(),
                        academicNotes: academicController.text.trim(),
                        behavioralNotes: behavioralController.text.trim(),
                        tags: [],
                        createdAt: DateTime.now(),
                      );
                      await context.read<AppProvider>().repo.addStudent(
                        student,
                      );
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
}

class _StudentsList extends StatelessWidget {
  const _StudentsList({required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final students = repo.getStudentsByClass(classId);

    if (students.isEmpty) {
      return Center(child: Text(context.tr('noStudents')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final s = students[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(s.name),
            subtitle: Text(
              [
                if (s.academicNotes.isNotEmpty) s.academicNotes,
                if (s.behavioralNotes.isNotEmpty) s.behavioralNotes,
              ].join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showStudentDetail(context, s),
          ),
        );
      },
    );
  }

  void _showStudentDetail(BuildContext context, Student student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(student.name, style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (student.academicNotes.isNotEmpty) ...[
              Text(
                context.tr('academicNotes'),
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              Text(student.academicNotes),
              const SizedBox(height: 12),
            ],
            if (student.behavioralNotes.isNotEmpty) ...[
              Text(
                context.tr('behavioralNotes'),
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              Text(student.behavioralNotes),
            ],
          ],
        ),
      ),
    );
  }
}
