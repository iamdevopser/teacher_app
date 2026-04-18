import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/project_model.dart';
import '../../data/services/project_pdf_service.dart';
import 'planner_split_view.dart';
import 'project_form_dialog.dart';
import 'project_participants_dialog.dart';

/// Projeler sub-menüsü - Planlarım altında
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({super.key});

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _projects = context.read<AppProvider>().repo.getProjects();
    _projects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedProject != null) {
      final selectedId = _selectedProject!.id;
      try {
        _selectedProject = _projects.firstWhere((project) => project.id == selectedId);
      } catch (_) {
        _selectedProject = _projects.isNotEmpty ? _projects.first : null;
      }
    } else if (_projects.length == 1) {
      _selectedProject = _projects.first;
    }
    setState(() {});
  }

  Future<void> _addProject() async {
    final project = await showDialog<ProjectModel>(
      context: context,
      builder: (_) => const ProjectFormDialog(),
    );
    if (project != null && mounted) {
      await context.read<AppProvider>().repo.addProject(project);
      _load();
      setState(() => _selectedProject = project);
    }
  }

  Future<void> _editProject(ProjectModel p) async {
    final updated = await showDialog<ProjectModel>(
      context: context,
      builder: (_) => ProjectFormDialog(project: p),
    );
    if (updated != null && mounted) {
      await context.read<AppProvider>().repo.updateProject(updated);
      _load();
      setState(() => _selectedProject = updated);
    }
  }

  Future<void> _deleteProject(ProjectModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text('${p.name} - ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().repo.deleteProject(p.id);
      _load();
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

  String _typeLabel(ProjectType t) {
    switch (t) {
      case ProjectType.inClass: return context.tr('projectTypeInClass');
      case ProjectType.semester: return context.tr('projectTypeSemester');
      case ProjectType.social: return context.tr('projectTypeSocial');
      case ProjectType.club: return context.tr('projectTypeClub');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(context.tr('projects')),
              FilledButton.icon(
                onPressed: _addProject,
                icon: const Icon(Icons.add),
                label: Text(context.tr('addProject')),
              ),
            ],
          ),
        ),
        Expanded(
          child: PlannerSplitView(
            emptyState: _projects.isNotEmpty ? _buildPlaceholder() : null,
            onClosePanel: _selectedProject != null ? () => setState(() => _selectedProject = null) : null,
            sidePanel: _selectedProject != null ? _buildProjectPanel(_selectedProject!) : null,
            content: _projects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(context.tr('noProjectsYet'), style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _addProject, child: Text(context.tr('addProject'))),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (_, i) {
                      final p = _projects[i];
                      final isSelected = _selectedProject?.id == p.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
                        child: ListTile(
                          leading: Icon(_iconForStatus(p.status)),
                          title: Text(p.name),
                          subtitle: Text('${_typeLabel(p.type)} • ${p.classLevel} • ${_statusLabel(p.status)}'),
                          trailing: isWide ? const Icon(Icons.chevron_right) : null,
                          onTap: () {
                            if (isWide) {
                              setState(() => _selectedProject = p);
                            } else {
                              _showProjectPreview(p);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
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

  Widget _buildProjectPanel(ProjectModel p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${_typeLabel(p.type)} • ${_statusLabel(p.status)}'),
          const SizedBox(height: 16),
          _previewSection(context.tr('projectBasicInfo'), [
            _previewRow(context.tr('projectSubject'), p.subject),
            _previewRow(context.tr('projectClass'), p.classLevel),
            _previewRow(context.tr('projectStartDate'), '${p.startDate.day}/${p.startDate.month}/${p.startDate.year}'),
            _previewRow(context.tr('projectEndDate'), '${p.endDate.day}/${p.endDate.month}/${p.endDate.year}'),
          ]),
          if (p.purpose.isNotEmpty || p.outcomes.isNotEmpty || p.skills.isNotEmpty)
            _previewSection(context.tr('projectPurpose'), [
              _previewRow(context.tr('projectPurpose'), p.purpose),
              _previewRow(context.tr('projectOutcomes'), p.outcomes),
              _previewRow(context.tr('projectSkills'), p.skills),
            ]),
          if (p.shortDescription.isNotEmpty || p.scope.isNotEmpty || p.teacherNotes.isNotEmpty)
            _previewSection(context.tr('projectDescription'), [
              _previewRow(context.tr('projectShortDesc'), p.shortDescription),
              _previewRow(context.tr('projectScope'), p.scope),
              _previewRow(context.tr('projectTeacherNotes'), p.teacherNotes),
            ]),
          if (p.participants.isNotEmpty)
            _previewSection(context.tr('projectParticipants'), [
              Text('${p.participants.length} ${context.tr('studentsCountSuffix')}'),
            ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _copyProjectLink(p),
                icon: const Icon(Icons.link),
                label: Text(context.tr('copyLink')),
              ),
              FilledButton.icon(
                onPressed: () => _shareProjectAsPdf(p),
                icon: const Icon(Icons.share),
                label: Text(context.tr('shareProject')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _manageParticipants(p),
                icon: const Icon(Icons.people),
                label: Text(context.tr('projectParticipants')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _editProject(p),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final newStatus = await _showStatusDialog(p);
                  if (newStatus == null || !mounted) return;
                  await context.read<AppProvider>().repo.updateProject(
                    ProjectModel(
                      id: p.id,
                      name: p.name,
                      type: p.type,
                      subject: p.subject,
                      classLevel: p.classLevel,
                      startDate: p.startDate,
                      endDate: p.endDate,
                      purpose: p.purpose,
                      outcomes: p.outcomes,
                      skills: p.skills,
                      shortDescription: p.shortDescription,
                      scope: p.scope,
                      teacherNotes: p.teacherNotes,
                      steps: p.steps,
                      materials: p.materials,
                      contentCriteria: p.contentCriteria,
                      participationCriteria: p.participationCriteria,
                      presentationCriteria: p.presentationCriteria,
                      timeManagementCriteria: p.timeManagementCriteria,
                      processNotes: p.processNotes,
                      observations: p.observations,
                      developmentNotes: p.developmentNotes,
                      status: newStatus,
                      createdAt: p.createdAt,
                      participants: p.participants,
                    ),
                  );
                  _load();
                },
                icon: const Icon(Icons.sync_alt),
                label: Text(context.tr('changeStatus')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _deleteProject(p),
                icon: const Icon(Icons.delete),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForStatus(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.draft: return Icons.edit_note;
      case ProjectStatus.inProgress: return Icons.autorenew;
      case ProjectStatus.completed: return Icons.check_circle;
      case ProjectStatus.archived: return Icons.archive;
    }
  }

  void _showProjectPreview(ProjectModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(_iconForStatus(p.status)),
            const SizedBox(width: 8),
            Expanded(child: Text(p.name)),
          ],
        ),
        content: SizedBox(
          width: 500,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _previewSection(context.tr('projectBasicInfo'), [
                  _previewRow(context.tr('projectName'), p.name),
                  _previewRow(context.tr('projectType'), _typeLabel(p.type)),
                  _previewRow(context.tr('projectSubject'), p.subject),
                  _previewRow(context.tr('projectClass'), p.classLevel),
                  _previewRow(context.tr('projectStartDate'), '${p.startDate.day}/${p.startDate.month}/${p.startDate.year}'),
                  _previewRow(context.tr('projectEndDate'), '${p.endDate.day}/${p.endDate.month}/${p.endDate.year}'),
                  _previewRow(context.tr('projectStatus'), _statusLabel(p.status)),
                ]),
                if (p.purpose.isNotEmpty) _previewSection(context.tr('projectPurpose'), [
                  _previewRow(context.tr('projectPurpose'), p.purpose),
                  if (p.outcomes.isNotEmpty) _previewRow(context.tr('projectOutcomes'), p.outcomes),
                  if (p.skills.isNotEmpty) _previewRow(context.tr('projectSkills'), p.skills),
                ]),
                if (p.shortDescription.isNotEmpty) _previewSection(context.tr('projectDescription'), [
                  _previewRow(context.tr('projectShortDesc'), p.shortDescription),
                  if (p.scope.isNotEmpty) _previewRow(context.tr('projectScope'), p.scope),
                  if (p.teacherNotes.isNotEmpty) _previewRow(context.tr('projectTeacherNotes'), p.teacherNotes),
                ]),
                if (p.steps.isNotEmpty) _previewSection(context.tr('projectSteps'), [
                  ...p.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key + 1}. ${e.value.title}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (e.value.description.isNotEmpty) Text(e.value.description, style: Theme.of(context).textTheme.bodySmall),
                        if (e.value.estimatedDuration.isNotEmpty) Text('${context.tr('stepDuration')}: ${e.value.estimatedDuration}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  )),
                ]),
                if (p.materials.isNotEmpty) _previewSection(context.tr('projectMaterials'), [
                  Text(p.materials, style: Theme.of(context).textTheme.bodyMedium),
                ]),
                if (p.contentCriteria.isNotEmpty || p.participationCriteria.isNotEmpty) _previewSection(context.tr('projectEvaluation'), [
                  if (p.contentCriteria.isNotEmpty) _previewRow(context.tr('projectContentCriteria'), p.contentCriteria),
                  if (p.participationCriteria.isNotEmpty) _previewRow(context.tr('projectParticipationCriteria'), p.participationCriteria),
                  if (p.presentationCriteria.isNotEmpty) _previewRow(context.tr('projectPresentationCriteria'), p.presentationCriteria),
                  if (p.timeManagementCriteria.isNotEmpty) _previewRow(context.tr('projectTimeCriteria'), p.timeManagementCriteria),
                ]),
                if (p.processNotes.isNotEmpty || p.observations.isNotEmpty || p.developmentNotes.isNotEmpty) _previewSection(context.tr('projectNotes'), [
                  if (p.processNotes.isNotEmpty) _previewRow(context.tr('projectProcessNotes'), p.processNotes),
                  if (p.observations.isNotEmpty) _previewRow(context.tr('projectObservations'), p.observations),
                  if (p.developmentNotes.isNotEmpty) _previewRow(context.tr('projectDevNotes'), p.developmentNotes),
                ]),
                if (p.participants.isNotEmpty) _previewSection(context.tr('projectParticipants'), [
                  ...p.participants.map((pp) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${pp.studentName} (${pp.classId})'),
                  )),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
          OutlinedButton.icon(
            icon: const Icon(Icons.link),
            onPressed: () {
              Navigator.pop(ctx);
              _copyProjectLink(p);
            },
            label: Text(context.tr('copyLink')),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            onPressed: () {
              Navigator.pop(ctx);
              _shareProjectAsPdf(p);
            },
            label: Text(context.tr('shareProject')),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _manageParticipants(p);
            },
            child: Text(context.tr('projectParticipants')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _editProject(p);
            },
            child: Text(context.tr('edit')),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteProject(p);
            },
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _previewSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  void _copyProjectLink(ProjectModel p) {
    final text = ProjectPdfService.getContentAsText(p, _typeLabel(p.type), _statusLabel(p.status));
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('copiedToClipboard'))),
    );
  }

  Future<void> _shareProjectAsPdf(ProjectModel p) async {
    final path = await ProjectPdfService.exportToPdf(p, _typeLabel(p.type), _statusLabel(p.status));
    if (path != null && File(path).existsSync()) {
      await Share.shareXFiles([XFile(path)], text: p.name);
    }
  }

  Future<void> _manageParticipants(ProjectModel p) async {
    showDialog(
      context: context,
      builder: (ctx) => ProjectParticipantsDialog(
        project: p,
        onSave: (updated) async {
          await context.read<AppProvider>().repo.updateProject(updated);
          _load();
        },
      ),
    );
  }

  Future<ProjectStatus?> _showStatusDialog(ProjectModel p) async {
    return showDialog<ProjectStatus>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('changeStatus')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ProjectStatus.values.map((s) {
            return ListTile(
              title: Text(_statusLabel(s)),
              onTap: () => Navigator.pop(ctx, s),
            );
          }).toList(),
        ),
      ),
    );
  }
}
