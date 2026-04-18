import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../data/models/guidance_student.dart';
import '../../data/repositories/app_repository.dart';
import '../../data/services/excel_import_service.dart';
import '../lesson_planner/planner_split_view.dart';

/// Rehberlik Sınıfı: Öğrenci listesi, form ve Excel toplu içe aktarma
class GuidanceClassScreen extends StatefulWidget {
  const GuidanceClassScreen({super.key});

  @override
  State<GuidanceClassScreen> createState() => _GuidanceClassScreenState();
}

class _GuidanceClassScreenState extends State<GuidanceClassScreen> {
  GuidanceStudent? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final repo = context.watch<AppProvider>().repo;
    final students = repo.getGuidanceStudents();
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    if (_selectedStudent != null) {
      final id = _selectedStudent!.id;
      try {
        _selectedStudent = students.firstWhere((student) => student.id == id);
      } catch (_) {
        _selectedStudent = students.isNotEmpty ? students.first : null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('guidanceClassTab')),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: context.tr('excelImport'),
            onPressed: () => _importFromExcel(context),
          ),
        ],
      ),
      body: PlannerSplitView(
        emptyState: students.isNotEmpty ? _buildPlaceholder(context) : null,
        onClosePanel: _selectedStudent != null
            ? () => setState(() => _selectedStudent = null)
            : null,
        sidePanel: _selectedStudent != null
            ? _buildStudentPanel(context, _selectedStudent!)
            : null,
        content: students.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('noStudentsYet'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _importFromExcel(context),
                            icon: const Icon(Icons.upload_file),
                            label: Text(context.tr('excelImport')),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _showStudentForm(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add),
                                const SizedBox(width: 8),
                                Text(context.tr('add')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s = students[i];
                  final isSelected = _selectedStudent?.id == s.id;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(s.fullName),
                      subtitle: Text(
                        [
                          if (s.studentNumber.isNotEmpty)
                            'No: ${s.studentNumber}',
                          if (s.classId.isNotEmpty) s.classId,
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isWide ? const Icon(Icons.chevron_right) : null,
                      onTap: () {
                        if (isWide) {
                          setState(() => _selectedStudent = s);
                        } else {
                          _showMobileStudentDetails(context, s);
                        }
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: students.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: 'guidance_class_add_fab',
              onPressed: () => _showStudentForm(context),
              icon: const Icon(Icons.add),
              label: Text(context.tr('add')),
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

  Widget _buildStudentPanel(
    BuildContext context,
    GuidanceStudent student, {
    bool showHeader = true,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Text(student.fullName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(student.classId),
            const SizedBox(height: 16),
          ],
          _detailRow(
            context,
            context.tr('studentNumber'),
            student.studentNumber,
          ),
          _detailRow(context, context.tr('email'), student.email),
          _detailRow(context, context.tr('phone'), student.phone),
          _detailRow(context, context.tr('nationality'), student.nationality),
          _detailRow(context, context.tr('gender'), student.gender),
          _detailRow(context, context.tr('address'), student.address),
          _detailRow(context, context.tr('motherName'), student.motherName),
          _detailRow(context, context.tr('motherPhone'), student.motherPhone),
          _detailRow(context, context.tr('fatherName'), student.fatherName),
          _detailRow(context, context.tr('fatherPhone'), student.fatherPhone),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _showStudentForm(context, student: student),
                icon: const Icon(Icons.edit),
                label: Text(context.tr('edit')),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _confirmDelete(context, student),
                icon: const Icon(Icons.delete),
                label: Text(context.tr('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMobileStudentDetails(BuildContext context, GuidanceStudent student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.fullName,
                        style: Theme.of(ctx).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildStudentPanel(context, student, showHeader: false),
              ),
            ],
          ),
        ),
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

  Future<void> _importFromExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null || path.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('selectFile'))));
      }
      return;
    }

    try {
      final bytes = await File(path).readAsBytes();
      final students = parseGuidanceStudentsFromExcel(bytes);
      if (students.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.tr('excelNoData'))));
        }
        return;
      }

      await context.read<AppProvider>().repo.addGuidanceStudents(students);
      if (!context.mounted) return;
      context.read<AppProvider>().refresh();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('importSuccess')} (${students.length})'),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${context.tr('error')}: $e')));
      }
    }
  }

  void _showStudentForm(BuildContext context, {GuidanceStudent? student}) {
    final profile = context.read<AppProvider>().profile;
    final classes = profile?.classesTaught ?? [];

    final lastNameCtrl = TextEditingController(text: student?.lastName ?? '');
    final firstNameCtrl = TextEditingController(text: student?.firstName ?? '');
    final studentNoCtrl = TextEditingController(
      text: student?.studentNumber ?? '',
    );
    final classCtrl = TextEditingController(text: student?.classId ?? '');
    final emailCtrl = TextEditingController(text: student?.email ?? '');
    final phoneCtrl = TextEditingController(text: student?.phone ?? '');
    final nationalityCtrl = TextEditingController(
      text: student?.nationality ?? '',
    );
    final addressCtrl = TextEditingController(text: student?.address ?? '');
    final motherNameCtrl = TextEditingController(
      text: student?.motherName ?? '',
    );
    final motherPhoneCtrl = TextEditingController(
      text: student?.motherPhone ?? '',
    );
    final motherEmailCtrl = TextEditingController(
      text: student?.motherEmail ?? '',
    );
    final fatherNameCtrl = TextEditingController(
      text: student?.fatherName ?? '',
    );
    final fatherPhoneCtrl = TextEditingController(
      text: student?.fatherPhone ?? '',
    );
    final fatherEmailCtrl = TextEditingController(
      text: student?.fatherEmail ?? '',
    );

    var genderVal = student?.gender ?? '';

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
                  student == null ? context.tr('add') : context.tr('edit'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildRow(ctx, [
                  _field(ctx, context.tr('lastName'), lastNameCtrl),
                  _field(ctx, context.tr('firstName'), firstNameCtrl),
                ]),
                _buildRow(ctx, [
                  _field(ctx, context.tr('studentNumber'), studentNoCtrl),
                  classes.isEmpty
                      ? _field(ctx, context.tr('classLabel'), classCtrl)
                      : DropdownButtonFormField<String>(
                          value: classCtrl.text.isEmpty
                              ? null
                              : (classes.contains(classCtrl.text)
                                    ? classCtrl.text
                                    : null),
                          decoration: InputDecoration(
                            labelText: context.tr('classLabel'),
                          ),
                          items: classes
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setModalState(() => classCtrl.text = v ?? ''),
                        ),
                ]),
                _field(ctx, context.tr('email'), emailCtrl),
                _field(ctx, context.tr('phone'), phoneCtrl),
                _buildRow(ctx, [
                  _field(ctx, context.tr('nationality'), nationalityCtrl),
                  DropdownButtonFormField<String>(
                    value: genderVal.isEmpty ? null : genderVal,
                    decoration: InputDecoration(
                      labelText: context.tr('gender'),
                    ),
                    items:
                        [
                              context.tr('male'),
                              context.tr('female'),
                              context.tr('preferNotToSay'),
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => setModalState(() => genderVal = v ?? ''),
                  ),
                ]),
                _field(ctx, context.tr('address'), addressCtrl, maxLines: 2),
                const Divider(),
                Text(
                  context.tr('motherInfo'),
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                _buildRow(ctx, [
                  _field(ctx, context.tr('motherName'), motherNameCtrl),
                  _field(ctx, context.tr('motherPhone'), motherPhoneCtrl),
                ]),
                _field(ctx, context.tr('motherEmail'), motherEmailCtrl),
                const SizedBox(height: 8),
                Text(
                  context.tr('fatherInfo'),
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                _buildRow(ctx, [
                  _field(ctx, context.tr('fatherName'), fatherNameCtrl),
                  _field(ctx, context.tr('fatherPhone'), fatherPhoneCtrl),
                ]),
                _field(ctx, context.tr('fatherEmail'), fatherEmailCtrl),
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
                        final lastName = lastNameCtrl.text.trim();
                        final firstName = firstNameCtrl.text.trim();
                        if (lastName.isEmpty && firstName.isEmpty) return;

                        final gs = GuidanceStudent(
                          id: student?.id ?? AppRepository.generateId(),
                          lastName: lastName,
                          firstName: firstName,
                          studentNumber: studentNoCtrl.text.trim(),
                          classId: classCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          nationality: nationalityCtrl.text.trim(),
                          gender: genderVal,
                          address: addressCtrl.text.trim(),
                          motherName: motherNameCtrl.text.trim(),
                          motherPhone: motherPhoneCtrl.text.trim(),
                          motherEmail: motherEmailCtrl.text.trim(),
                          fatherName: fatherNameCtrl.text.trim(),
                          fatherPhone: fatherPhoneCtrl.text.trim(),
                          fatherEmail: fatherEmailCtrl.text.trim(),
                          createdAt: student?.createdAt ?? DateTime.now(),
                        );

                        if (student != null) {
                          await context
                              .read<AppProvider>()
                              .repo
                              .updateGuidanceStudent(gs);
                        } else {
                          await context
                              .read<AppProvider>()
                              .repo
                              .addGuidanceStudent(gs);
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

  Widget _field(
    BuildContext ctx,
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      maxLines: maxLines,
    );
  }

  Widget _buildRow(BuildContext ctx, List<Widget> children) {
    final isCompact = MediaQuery.sizeOf(ctx).shortestSide < 600;
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: children
              .map(
                (child) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: child,
                ),
              )
              .toList(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: children.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: e.key < children.length - 1 ? 8 : 0,
              ),
              child: e.value,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmDelete(BuildContext context, GuidanceStudent s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('confirmDeleteRecord')),
        content: Text('${s.fullName} ${context.tr('confirmDelete')}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              await context.read<AppProvider>().repo.deleteGuidanceStudent(
                s.id,
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
