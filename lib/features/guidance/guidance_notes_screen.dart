import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/guidance_models.dart';
import '../../data/models/guidance_student.dart';
import '../../data/repositories/app_repository.dart';

/// Rehberlik Notları: Aktiviteler ve Görüşmeler
class GuidanceNotesScreen extends StatefulWidget {
  const GuidanceNotesScreen({super.key});

  @override
  State<GuidanceNotesScreen> createState() => _GuidanceNotesScreenState();
}

class _GuidanceNotesScreenState extends State<GuidanceNotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('guidanceNotesTab')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.celebration),
              text: context.tr('activities'),
            ),
            Tab(icon: const Icon(Icons.people), text: context.tr('meetings')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_ActivitiesTab(), _MeetingsTab()],
      ),
    );
  }
}

String _participantNames(List<String> ids, List<GuidanceStudent> students) {
  if (ids.isEmpty || students.isEmpty) return '-';
  final names = ids.map((id) {
    try {
      final s = students.firstWhere((x) => x.id == id);
      return s.fullName;
    } catch (_) {
      return id;
    }
  }).toList();
  return names.join(', ');
}

String _participantClasses(List<String> ids, List<GuidanceStudent> students) {
  if (ids.isEmpty || students.isEmpty) return '-';
  final classes = ids
      .map((id) {
        try {
          final s = students.firstWhere((x) => x.id == id);
          return s.classId;
        } catch (_) {
          return '';
        }
      })
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();
  return classes.join(', ');
}

class _ActivitiesTab extends StatefulWidget {
  @override
  State<_ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<_ActivitiesTab> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    var activities = repo.getGuidanceActivities().toList();
    activities.sort((a, b) => b.date.compareTo(a.date));
    final students = repo.getGuidanceStudents();

    return Scaffold(
      body: activities.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noActivitiesYet'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(context.tr('activityTitle'))),
                    DataColumn(label: Text(context.tr('studentName'))),
                    DataColumn(label: Text(context.tr('classLabel'))),
                    DataColumn(label: Text(context.tr('activityDate'))),
                    DataColumn(
                      label: Text('${context.tr('participantCount')}'),
                    ),
                    DataColumn(label: Text(context.tr('evaluation'))),
                    const DataColumn(label: Text('')),
                  ],
                  rows: activities.map((a) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            a.activityName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(_participantNames(a.participantIds, students)),
                        ),
                        DataCell(
                          Text(_participantClasses(a.participantIds, students)),
                        ),
                        DataCell(
                          Text('${a.date.day}/${a.date.month}/${a.date.year}'),
                        ),
                        DataCell(Text('${a.participantCount}')),
                        DataCell(
                          Text(
                            a.evaluationNote.isEmpty
                                ? context.tr('noEvaluation')
                                : a.evaluationNote,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showActivityForm(context, activity: a),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _confirmDelete(context, a),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelectChanged: (_) =>
                          _showActivityForm(context, activity: a),
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'guidance_notes_activity_add_fab',
        onPressed: () => _showActivityForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addActivity')),
      ),
    );
  }

  void _showActivityForm(BuildContext context, {GuidanceActivity? activity}) {
    final repo = context.read<AppProvider>().repo;
    final students = repo.getGuidanceStudents();
    if (students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('addStudentFirst'))));
      return;
    }

    final nameCtrl = TextEditingController(text: activity?.activityName ?? '');
    var selectedIds = activity?.participantIds.toList() ?? <String>[];
    final evalCtrl = TextEditingController(
      text: activity?.evaluationNote ?? '',
    );
    var date = activity?.date ?? DateTime.now();
    var isInSchool = activity?.isInSchool ?? true;

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
                  activity == null
                      ? context.tr('addActivity')
                      : context.tr('edit'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('activityName'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  value: isInSchool,
                  decoration: InputDecoration(
                    labelText: context.tr('activityType'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(context.tr('inSchool')),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(context.tr('outSchool')),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => isInSchool = v ?? true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(context.tr('activityDate')),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModalState(() => date = d);
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('participants'),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await showDialog(
                        context: ctx,
                        builder: (dCtx) => StatefulBuilder(
                          builder: (_, setDlg) => AlertDialog(
                            title: Text(context.tr('participants')),
                            content: SizedBox(
                              width: 300,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: students.length,
                                itemBuilder: (_, i) {
                                  final s = students[i];
                                  final sel = selectedIds.contains(s.id);
                                  return CheckboxListTile(
                                    title: Text(s.fullName),
                                    value: sel,
                                    onChanged: (v) {
                                      setDlg(() {
                                        if (v == true)
                                          selectedIds.add(s.id);
                                        else
                                          selectedIds.remove(s.id);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: Text(context.tr('ok')),
                              ),
                            ],
                          ),
                        ),
                      );
                      setModalState(() {});
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedIds.length} ${context.tr('studentsCountSuffix')} ${context.tr('select')}',
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: evalCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('evaluationNote'),
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
                        final ga = GuidanceActivity(
                          id: activity?.id ?? AppRepository.generateId(),
                          activityName: nameCtrl.text.trim(),
                          participantIds: selectedIds,
                          participantCount: selectedIds.length,
                          evaluationNote: evalCtrl.text.trim(),
                          date: date,
                          createdAt: activity?.createdAt ?? DateTime.now(),
                          isInSchool: isInSchool,
                        );
                        if (activity != null) {
                          await repo.updateGuidanceActivity(ga);
                        } else {
                          await repo.addGuidanceActivity(ga);
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

  void _confirmDelete(BuildContext context, GuidanceActivity a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text('"${a.activityName}" ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteGuidanceActivity(
                a.id,
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

class _MeetingsTab extends StatefulWidget {
  @override
  State<_MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<_MeetingsTab> {
  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    var meetings = repo.getGuidanceMeetings().toList();
    meetings.sort((a, b) => b.date.compareTo(a.date));
    final students = repo.getGuidanceStudents();

    return Scaffold(
      body: meetings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noMeetingsYet'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(context.tr('meetingTitle'))),
                    DataColumn(label: Text(context.tr('studentName'))),
                    DataColumn(label: Text(context.tr('classLabel'))),
                    DataColumn(label: Text(context.tr('meetingDate'))),
                    DataColumn(
                      label: Text('${context.tr('participantCount')}'),
                    ),
                    DataColumn(label: Text(context.tr('evaluation'))),
                    const DataColumn(label: Text('')),
                  ],
                  rows: meetings.map((m) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            m.meetingTitle.isEmpty ? '-' : m.meetingTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(_participantNames(m.participantIds, students)),
                        ),
                        DataCell(
                          Text(_participantClasses(m.participantIds, students)),
                        ),
                        DataCell(
                          Text('${m.date.day}/${m.date.month}/${m.date.year}'),
                        ),
                        DataCell(Text('${m.participantCount}')),
                        DataCell(
                          Text(
                            m.evaluationNote.isEmpty
                                ? context.tr('noEvaluation')
                                : m.evaluationNote,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () =>
                                    _showMeetingForm(context, meeting: m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _confirmDelete(context, m),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelectChanged: (_) =>
                          _showMeetingForm(context, meeting: m),
                    );
                  }).toList(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'guidance_notes_meeting_add_fab',
        onPressed: () => _showMeetingForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addMeeting')),
      ),
    );
  }

  void _showMeetingForm(BuildContext context, {GuidanceMeeting? meeting}) {
    final repo = context.read<AppProvider>().repo;
    final students = repo.getGuidanceStudents();
    if (students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('addStudentFirst'))));
      return;
    }

    final titleCtrl = TextEditingController(text: meeting?.meetingTitle ?? '');
    var selectedIds = meeting?.participantIds.toList() ?? <String>[];
    final evalCtrl = TextEditingController(text: meeting?.evaluationNote ?? '');
    var date = meeting?.date ?? DateTime.now();
    var isIndividual = meeting?.isIndividual ?? true;

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
                  meeting == null
                      ? context.tr('addMeeting')
                      : context.tr('edit'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('meetingTitle'),
                    hintText: context.tr('meetingTitleHint'),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  value: isIndividual,
                  decoration: InputDecoration(
                    labelText: context.tr('meetingType'),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(context.tr('individual')),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(context.tr('group')),
                    ),
                  ],
                  onChanged: (v) =>
                      setModalState(() => isIndividual = v ?? true),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(context.tr('meetingDate')),
                  subtitle: Text('${date.day}/${date.month}/${date.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setModalState(() => date = d);
                  },
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: context.tr('participants'),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await showDialog(
                        context: ctx,
                        builder: (dCtx) => StatefulBuilder(
                          builder: (_, setDlg) => AlertDialog(
                            title: Text(context.tr('participants')),
                            content: SizedBox(
                              width: 300,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: students.length,
                                itemBuilder: (_, i) {
                                  final s = students[i];
                                  final sel = selectedIds.contains(s.id);
                                  return CheckboxListTile(
                                    title: Text(s.fullName),
                                    value: sel,
                                    onChanged: (v) {
                                      setDlg(() {
                                        if (v == true)
                                          selectedIds.add(s.id);
                                        else
                                          selectedIds.remove(s.id);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx),
                                child: Text(context.tr('ok')),
                              ),
                            ],
                          ),
                        ),
                      );
                      setModalState(() {});
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${selectedIds.length} ${context.tr('studentsCountSuffix')} ${context.tr('select')}',
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: evalCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('evaluationNote'),
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
                        final gm = GuidanceMeeting(
                          id: meeting?.id ?? AppRepository.generateId(),
                          meetingTitle: titleCtrl.text.trim(),
                          participantIds: selectedIds,
                          participantCount: selectedIds.length,
                          evaluationNote: evalCtrl.text.trim(),
                          date: date,
                          createdAt: meeting?.createdAt ?? DateTime.now(),
                          isIndividual: isIndividual,
                        );
                        if (meeting != null) {
                          await repo.updateGuidanceMeeting(gm);
                        } else {
                          await repo.addGuidanceMeeting(gm);
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

  void _confirmDelete(BuildContext context, GuidanceMeeting m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text(context.tr('confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteGuidanceMeeting(
                m.id,
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
