import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/project_model.dart';
import '../../data/repositories/app_repository.dart';

/// Projeye öğrenci ekleme ve iş takibi dialogu
class ProjectParticipantsDialog extends StatefulWidget {
  const ProjectParticipantsDialog({
    required this.project,
    required this.onSave,
    super.key,
  });

  final ProjectModel project;
  final Future<void> Function(ProjectModel) onSave;

  @override
  State<ProjectParticipantsDialog> createState() => _ProjectParticipantsDialogState();
}

class _ProjectParticipantsDialogState extends State<ProjectParticipantsDialog> {
  late List<ProjectParticipant> _participants;

  @override
  void initState() {
    super.initState();
    _participants = widget.project.participants.map((p) => ProjectParticipant(
      id: p.id,
      studentId: p.studentId,
      studentName: p.studentName,
      classId: p.classId,
      workStatus: p.workStatus,
      notes: p.notes,
      tasks: p.tasks.map((t) => ProjectTask(id: t.id, title: t.title, isCompleted: t.isCompleted)).toList(),
    )).toList();
  }

  ProjectModel _projectWithParticipants() {
    return ProjectModel(
      id: widget.project.id,
      name: widget.project.name,
      type: widget.project.type,
      subject: widget.project.subject,
      classLevel: widget.project.classLevel,
      startDate: widget.project.startDate,
      endDate: widget.project.endDate,
      purpose: widget.project.purpose,
      outcomes: widget.project.outcomes,
      skills: widget.project.skills,
      shortDescription: widget.project.shortDescription,
      scope: widget.project.scope,
      teacherNotes: widget.project.teacherNotes,
      steps: widget.project.steps,
      materials: widget.project.materials,
      contentCriteria: widget.project.contentCriteria,
      participationCriteria: widget.project.participationCriteria,
      presentationCriteria: widget.project.presentationCriteria,
      timeManagementCriteria: widget.project.timeManagementCriteria,
      processNotes: widget.project.processNotes,
      observations: widget.project.observations,
      developmentNotes: widget.project.developmentNotes,
      status: widget.project.status,
      createdAt: widget.project.createdAt,
      participants: _participants,
    );
  }

  void _showAddStudentDialog() {
    final students = context.read<AppProvider>().repo.getAllStudentsForProjectSelection();
    final existingIds = _participants.map((p) => p.studentId).toSet();
    final available = students.where((s) => !existingIds.contains(s.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('noStudentsToAdd'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('addStudentToProject')),
        content: SizedBox(
          width: 350,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, i) {
              final s = available[i];
              return ListTile(
                title: Text(s.name),
                subtitle: Text(s.classId),
                onTap: () {
                  setState(() {
                    _participants.add(ProjectParticipant(
                      id: AppRepository.generateId(),
                      studentId: s.id,
                      studentName: s.name,
                      classId: s.classId,
                    ));
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showParticipantDetail(ProjectParticipant p, int index) {
    final notesCtrl = TextEditingController(text: p.notes);

    void updateParticipant(ProjectParticipant updated) {
      setState(() => _participants[index] = updated);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          final current = _participants[index];
          return AlertDialog(
            title: Text(current.studentName),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<ParticipantWorkStatus>(
                      value: current.workStatus,
                      decoration: InputDecoration(labelText: context.tr('workStatus')),
                      items: ParticipantWorkStatus.values.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_workStatusLabel(s)),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final updated = ProjectParticipant(
                            id: current.id,
                            studentId: current.studentId,
                            studentName: current.studentName,
                            classId: current.classId,
                            workStatus: v,
                            notes: notesCtrl.text,
                            tasks: current.tasks,
                          );
                          updateParticipant(updated);
                          setModalState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(labelText: context.tr('workNotes')),
                      maxLines: 3,
                      onChanged: (_) {
                        updateParticipant(ProjectParticipant(
                          id: current.id,
                          studentId: current.studentId,
                          studentName: current.studentName,
                          classId: current.classId,
                          workStatus: current.workStatus,
                          notes: notesCtrl.text,
                          tasks: current.tasks,
                        ));
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(context.tr('participantTasks'), style: Theme.of(context).textTheme.titleSmall),
                        if (current.tasks.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.tr('tasksCompleted').replaceAll('{x}', '${current.tasks.where((t) => t.isCompleted).length}').replaceAll('{y}', '${current.tasks.length}'),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...current.tasks.asMap().entries.map((e) => ListTile(
                      leading: Checkbox(
                        value: e.value.isCompleted,
                        onChanged: (v) {
                          final newTasks = current.tasks.toList();
                          newTasks[e.key] = ProjectTask(id: e.value.id, title: e.value.title, isCompleted: v ?? false);
                          updateParticipant(ProjectParticipant(
                            id: current.id,
                            studentId: current.studentId,
                            studentName: current.studentName,
                            classId: current.classId,
                            workStatus: current.workStatus,
                            notes: notesCtrl.text,
                            tasks: newTasks,
                          ));
                          setModalState(() {});
                        },
                      ),
                      title: Text(
                        e.value.title,
                        style: TextStyle(
                          decoration: e.value.isCompleted ? TextDecoration.lineThrough : null,
                          color: e.value.isCompleted ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6) : null,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          final newTasks = current.tasks.toList()..removeAt(e.key);
                          updateParticipant(ProjectParticipant(
                            id: current.id,
                            studentId: current.studentId,
                            studentName: current.studentName,
                            classId: current.classId,
                            workStatus: current.workStatus,
                            notes: notesCtrl.text,
                            tasks: newTasks,
                          ));
                          setModalState(() {});
                        },
                      ),
                    )),
                    TextButton.icon(
                      onPressed: () {
                        final taskCtrl = TextEditingController();
                        showDialog(
                          context: ctx2,
                          builder: (dCtx) => AlertDialog(
                            title: Text(context.tr('addTask')),
                            content: TextField(
                              controller: taskCtrl,
                              decoration: InputDecoration(labelText: context.tr('taskTitle')),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(context.tr('cancel'))),
                              FilledButton(
                                onPressed: () {
                                  if (taskCtrl.text.trim().isNotEmpty) {
                                    final newTasks = [...current.tasks, ProjectTask(id: AppRepository.generateId(), title: taskCtrl.text.trim())];
                                    updateParticipant(ProjectParticipant(
                                      id: current.id,
                                      studentId: current.studentId,
                                      studentName: current.studentName,
                                      classId: current.classId,
                                      workStatus: current.workStatus,
                                      notes: notesCtrl.text,
                                      tasks: newTasks,
                                    ));
                                    Navigator.pop(dCtx);
                                    setModalState(() {});
                                  }
                                },
                                child: Text(context.tr('add')),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('addTask')),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
            ],
          );
        },
      ),
    );
  }

  String _workStatusLabel(ParticipantWorkStatus s) {
    switch (s) {
      case ParticipantWorkStatus.notStarted: return context.tr('workStatusNotStarted');
      case ParticipantWorkStatus.inProgress: return context.tr('workStatusInProgress');
      case ParticipantWorkStatus.completed: return context.tr('workStatusCompleted');
    }
  }

  String _workStatusLabelShort(ParticipantWorkStatus s) {
    switch (s) {
      case ParticipantWorkStatus.notStarted: return context.tr('workStatusNotStarted');
      case ParticipantWorkStatus.inProgress: return context.tr('workStatusInProgress');
      case ParticipantWorkStatus.completed: return context.tr('workStatusCompleted');
    }
  }

  IconData _workStatusIcon(ParticipantWorkStatus s) {
    switch (s) {
      case ParticipantWorkStatus.notStarted: return Icons.schedule;
      case ParticipantWorkStatus.inProgress: return Icons.autorenew;
      case ParticipantWorkStatus.completed: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('projectParticipants')),
      content: SizedBox(
        width: 450,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _showAddStudentDialog,
              icon: const Icon(Icons.person_add),
              label: Text(context.tr('addStudentToProject')),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _participants.isEmpty
                  ? Center(child: Text(context.tr('noParticipantsYet')))
                  : ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (_, i) {
                        final p = _participants[i];
                        final completedTasks = p.tasks.where((t) => t.isCompleted).length;
                        final totalTasks = p.tasks.length;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_workStatusIcon(p.workStatus), color: p.workStatus == ParticipantWorkStatus.completed ? Colors.green : null),
                            title: Text(p.studentName),
                            subtitle: Text('${p.classId} • ${_workStatusLabelShort(p.workStatus)}${totalTasks > 0 ? ' • $completedTasks/$totalTasks ${context.tr('tasks')}' : ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => setState(() => _participants.removeAt(i)),
                                ),
                              ],
                            ),
                            onTap: () => _showParticipantDetail(p, i),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(
          onPressed: () async {
            await widget.onSave(_projectWithParticipants());
            if (mounted) Navigator.pop(context);
          },
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
