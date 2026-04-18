import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../data/models/attendance_record.dart';
import '../../data/models/guidance_student.dart';
import '../../data/services/student_report_service.dart';
import '../lesson_planner/planner_split_view.dart';
import 'report_progress_chart.dart';

/// Raporlar ekranı - Sadece Öğrenci Durum Raporu
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return const _ReportsHome();
  }
}

class _ReportsHome extends StatefulWidget {
  const _ReportsHome();

  @override
  State<_ReportsHome> createState() => _ReportsHomeState();
}

class _ReportsHomeState extends State<_ReportsHome> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final items = [
      _ReportHomeItem(
        keyName: 'student',
        icon: Icons.people,
        title: context.tr('studentStatusReport'),
        subtitle: context.tr('studentStatusReportSubtitle'),
        builder: () => const StudentStatusReportScreen(),
      ),
      _ReportHomeItem(
        keyName: 'parent',
        icon: Icons.family_restroom,
        title: context.tr('reportParentSummary'),
        subtitle: context.tr('reportParentSummarySubtitle'),
        builder: () => const ParentSummaryReportScreen(),
      ),
    ];
    final selected = items.where((item) => item.keyName == _selectedKey).cast<_ReportHomeItem?>().firstWhere((item) => item != null, orElse: () => null);

    return PlannerSplitView(
      emptyState: _buildPlaceholder(context),
      onClosePanel: selected != null ? () => setState(() => _selectedKey = null) : null,
      sidePanel: selected != null ? _buildPanel(context, selected) : null,
      content: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('reports')),
          actions: const [AppBarActions()],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: items.map((item) {
            final isSelected = item.keyName == _selectedKey;
            return Card(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35) : null,
              child: ListTile(
                leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: isWide ? const Icon(Icons.chevron_right) : const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  if (isWide) {
                    setState(() => _selectedKey = item.keyName);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => item.builder()));
                  }
                },
              ),
            );
          }).toList(),
        ),
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

  Widget _buildPanel(BuildContext context, _ReportHomeItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(item.subtitle),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.builder())),
            icon: const Icon(Icons.open_in_new),
            label: Text(context.tr('preview')),
          ),
        ],
      ),
    );
  }
}

class _ReportHomeItem {
  const _ReportHomeItem({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() builder;
}

class StudentStatusReportScreen extends StatefulWidget {
  const StudentStatusReportScreen({super.key});

  @override
  State<StudentStatusReportScreen> createState() => _StudentStatusReportScreenState();
}

class _StudentStatusReportScreenState extends State<StudentStatusReportScreen> {
  List<GuidanceStudent> _students = [];
  final Map<String, String?> _reportPaths = {};
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _teacherComment = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<AppProvider>().repo;
    _students = repo.getGuidanceStudents();
    setState(() {});
  }

  List<T> _filterByDate<T>(List<T> items, DateTime? from, DateTime? to, DateTime Function(T) getDate) {
    if (from == null && to == null) return items;
    return items.where((e) {
      final d = getDate(e);
      if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) return false;
      if (to != null && d.isAfter(DateTime(to.year, to.month, to.day).add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  Future<String?> _generateReport(GuidanceStudent s) async {
    final repo = context.read<AppProvider>().repo;
    var assessments = repo.getAssessmentsByClass(s.classId)
        .where((a) => a.studentId == s.id)
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      assessments = _filterByDate(assessments, _dateFrom, _dateTo, (a) => a.date);
    }
    assessments.sort((a, b) => b.date.compareTo(a.date));

    final attendance = repo.getAttendanceByStudentId(s.id);
    final absentCount = attendance.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount = attendance.where((r) => r.status == AttendanceStatus.late).length;

    var activities = repo.getGuidanceActivities()
        .where((a) => a.participantIds.contains(s.id))
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      activities = _filterByDate(activities, _dateFrom, _dateTo, (a) => a.date);
    }
    activities.sort((a, b) => b.date.compareTo(a.date));

    var meetings = repo.getGuidanceMeetings()
        .where((m) => m.participantIds.contains(s.id))
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      meetings = _filterByDate(meetings, _dateFrom, _dateTo, (m) => m.date);
    }
    meetings.sort((a, b) => b.date.compareTo(a.date));

    final profile = FeatureFlags.reportsAutoMetadata ? context.read<AppProvider>().profile : null;
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('              ÖĞRENCİ DURUM RAPORU');
    buffer.writeln('═══════════════════════════════════════════════════');
    if (profile != null) {
      buffer.writeln('${profile.schoolName} • ${profile.teacherName}');
      buffer.writeln();
    }
    if (FeatureFlags.reportsDateRangeFilter && (_dateFrom != null || _dateTo != null)) {
      buffer.writeln('Tarih: ${_dateFrom != null ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}' : '...'} - ${_dateTo != null ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}' : '...'}');
      buffer.writeln();
    }
    buffer.writeln('Öğrenci: ${s.fullName}');
    buffer.writeln('Sınıf: ${s.classId}');
    buffer.writeln('Numara: ${s.studentNumber}');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('PERFORMANS');
    buffer.writeln('───────────────────────────────────────────────────');
    if (assessments.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final a in assessments.take(10)) {
        buffer.writeln('• ${a.title} (${a.subject}): ${a.score} - ${a.date.day}/${a.date.month}/${a.date.year}');
        if (a.comments.isNotEmpty) buffer.writeln('  ${a.comments}');
      }
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('DEVAMSIZLIK');
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('Yok: $absentCount | Geç: $lateCount');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('AKTİVİTELER');
    buffer.writeln('───────────────────────────────────────────────────');
    if (activities.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final a in activities.take(10)) {
        buffer.writeln('• ${a.activityName} - ${a.date.day}/${a.date.month}/${a.date.year}');
        if (a.evaluationNote.isNotEmpty) buffer.writeln('  Değerlendirme: ${a.evaluationNote}');
      }
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('GÖRÜŞMELER');
    buffer.writeln('───────────────────────────────────────────────────');
    if (meetings.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final m in meetings.take(10)) {
        buffer.writeln('• ${m.date.day}/${m.date.month}/${m.date.year} - ${m.participantCount} kişi');
        if (m.evaluationNote.isNotEmpty) buffer.writeln('  Değerlendirme: ${m.evaluationNote}');
      }
    }
    if (FeatureFlags.reportsTeacherComment && _teacherComment.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('───────────────────────────────────────────────────');
      buffer.writeln('ÖĞRETMEN YORUMU');
      buffer.writeln('───────────────────────────────────────────────────');
      buffer.writeln(_teacherComment);
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════');

    try {
      final dir = await _getReportsDir();
      if (dir == null) return null;
      final safeName = '${s.fullName.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${s.id.substring(0, 8)}.txt';
      final file = File('${dir.path}/$safeName');
      await file.writeAsString(buffer.toString());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _getReportsDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/student_reports');
      if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
      return reportsDir;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getReportContent(GuidanceStudent s) async {
    final repo = context.read<AppProvider>().repo;
    var assessments = repo.getAssessmentsByClass(s.classId)
        .where((a) => a.studentId == s.id)
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      assessments = _filterByDate(assessments, _dateFrom, _dateTo, (a) => a.date);
    }
    assessments.sort((a, b) => b.date.compareTo(a.date));
    final attendance = repo.getAttendanceByStudentId(s.id);
    final absentCount = attendance.where((r) => r.status == AttendanceStatus.absent).length;
    final lateCount = attendance.where((r) => r.status == AttendanceStatus.late).length;
    var activities = repo.getGuidanceActivities()
        .where((a) => a.participantIds.contains(s.id))
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      activities = _filterByDate(activities, _dateFrom, _dateTo, (a) => a.date);
    }
    activities.sort((a, b) => b.date.compareTo(a.date));
    var meetings = repo.getGuidanceMeetings()
        .where((m) => m.participantIds.contains(s.id))
        .toList();
    if (FeatureFlags.reportsDateRangeFilter) {
      meetings = _filterByDate(meetings, _dateFrom, _dateTo, (m) => m.date);
    }
    meetings.sort((a, b) => b.date.compareTo(a.date));

    final profile = FeatureFlags.reportsAutoMetadata ? context.read<AppProvider>().profile : null;
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('              ÖĞRENCİ DURUM RAPORU');
    buffer.writeln('═══════════════════════════════════════════════════');
    if (profile != null) {
      buffer.writeln('${profile.schoolName} • ${profile.teacherName}');
      buffer.writeln();
    }
    if (FeatureFlags.reportsDateRangeFilter && (_dateFrom != null || _dateTo != null)) {
      buffer.writeln('Tarih: ${_dateFrom != null ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}' : '...'} - ${_dateTo != null ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}' : '...'}');
      buffer.writeln();
    }
    buffer.writeln('Öğrenci: ${s.fullName}');
    buffer.writeln('Sınıf: ${s.classId}');
    buffer.writeln('Numara: ${s.studentNumber}');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('PERFORMANS');
    buffer.writeln('───────────────────────────────────────────────────');
    if (assessments.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final a in assessments.take(10)) {
        buffer.writeln('• ${a.title} (${a.subject}): ${a.score} - ${a.date.day}/${a.date.month}/${a.date.year}');
        if (a.comments.isNotEmpty) buffer.writeln('  ${a.comments}');
      }
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('DEVAMSIZLIK');
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('Yok: $absentCount | Geç: $lateCount');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('AKTİVİTELER');
    buffer.writeln('───────────────────────────────────────────────────');
    if (activities.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final a in activities.take(10)) {
        buffer.writeln('• ${a.activityName} - ${a.date.day}/${a.date.month}/${a.date.year}');
        if (a.evaluationNote.isNotEmpty) buffer.writeln('  Değerlendirme: ${a.evaluationNote}');
      }
    }
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('GÖRÜŞMELER');
    buffer.writeln('───────────────────────────────────────────────────');
    if (meetings.isEmpty) {
      buffer.writeln('Kayıt yok.');
    } else {
      for (final m in meetings.take(10)) {
        buffer.writeln('• ${m.date.day}/${m.date.month}/${m.date.year} - ${m.participantCount} kişi');
        if (m.evaluationNote.isNotEmpty) buffer.writeln('  Değerlendirme: ${m.evaluationNote}');
      }
    }
    if (FeatureFlags.reportsTeacherComment && _teacherComment.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('───────────────────────────────────────────────────');
      buffer.writeln('ÖĞRETMEN YORUMU');
      buffer.writeln('───────────────────────────────────────────────────');
      buffer.writeln(_teacherComment);
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════');
    return buffer.toString();
  }

  Future<void> _showPreviewAndShare(GuidanceStudent s) async {
    final content = await _getReportContent(s);
    if (!mounted) return;
    String? path;
    if (FeatureFlags.reportsWordExport) {
      path = await _generatePdfReport(s);
    }
    path ??= await _generateReport(s);
    if (path == null || !mounted) return;
    setState(() => _reportPaths[s.id] = path);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${s.fullName} - ${context.tr('studentStatusReport')}'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SelectableText(content),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('close'))),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(context.tr('copiedToClipboard'))));
            },
            icon: const Icon(Icons.copy),
            label: Text(context.tr('copyReport')),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            tooltip: context.tr('shareReport'),
            onSelected: (app) async {
              if (app == 'gmail') {
                final subject = Uri.encodeComponent('${s.fullName} - ${context.tr('studentStatusReport')}');
                final body = Uri.encodeComponent(content);
                await launchUrl(Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&su=$subject&body=$body'));
              } else if (app == 'drive') {
                Clipboard.setData(ClipboardData(text: content));
                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(context.tr('copiedToClipboard'))));
                await launchUrl(Uri.parse('https://drive.google.com/drive/my-drive'), mode: LaunchMode.externalApplication);
              } else if (app == 'viber') {
                Clipboard.setData(ClipboardData(text: content));
                try {
                  final text = Uri.encodeComponent('${s.fullName}\n\n$content');
                  await launchUrl(Uri.parse('viber://forward?text=$text'), mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(context.tr('copiedToClipboard'))));
                }
              } else if (path != null) {
                final file = XFile(path);
                await Share.shareXFiles([file], text: '${s.fullName} - ${context.tr('studentStatusReport')}');
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'gmail', child: Row(children: [Icon(Icons.mail, size: 20, color: Colors.red[700]), const SizedBox(width: 8), Text(context.tr('shareViaGmail'))])),
              PopupMenuItem(value: 'drive', child: Row(children: [Icon(Icons.cloud, size: 20, color: Colors.blue[700]), const SizedBox(width: 8), Text(context.tr('shareViaDrive'))])),
              PopupMenuItem(value: 'viber', child: Row(children: [Icon(Icons.chat_bubble, size: 20, color: Colors.purple[700]), const SizedBox(width: 8), Text(context.tr('shareViaViber'))])),
              PopupMenuItem(value: 'other', child: Row(children: [const Icon(Icons.share, size: 20), const SizedBox(width: 8), Text(context.tr('shareOther'))])),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    DateTime? from = _dateFrom;
    DateTime? to = _dateTo;
    final commentCtrl = TextEditingController(text: _teacherComment);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setState) => AlertDialog(
          title: Text(context.tr('date')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (FeatureFlags.reportsDateRangeFilter) ...[
                  ListTile(
                    title: Text(from != null ? '${from!.day}/${from!.month}/${from!.year}' : context.tr('date')),
                    onTap: () async {
                      final d = await showDatePicker(context: ctx2, initialDate: from ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => from = d);
                    },
                  ),
                  ListTile(
                    title: Text(to != null ? '${to!.day}/${to!.month}/${to!.year}' : context.tr('date')),
                    onTap: () async {
                      final d = await showDatePicker(context: ctx2, initialDate: to ?? DateTime.now(), firstDate: from ?? DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => to = d);
                    },
                  ),
                ],
                if (FeatureFlags.reportsTeacherComment) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    decoration: InputDecoration(labelText: context.tr('teacherGuidance')),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
            FilledButton(
              onPressed: () {
                _dateFrom = from;
                _dateTo = to;
                _teacherComment = commentCtrl.text.trim();
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetail(BuildContext context, GuidanceStudent s) {
    if (FeatureFlags.reportsProgressCharts) {
      final repo = context.read<AppProvider>().repo;
      final assessments = repo.getAssessmentsByClass(s.classId)
          .where((a) => a.studentId == s.id)
          .toList();
      assessments.sort((a, b) => b.date.compareTo(a.date));
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          expand: false,
          builder: (_, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.fullName, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (FeatureFlags.reportsProgressCharts && assessments.isNotEmpty)
                  ReportProgressChart(assessments: assessments),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showPreviewAndShare(s);
                        },
                        icon: const Icon(Icons.preview),
                        label: Text(context.tr('preview')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _generateAndShare(s);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.share, size: 20),
                            const SizedBox(width: 8),
                            Text(context.tr('shareReport')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      _showPreviewAndShare(s);
    }
  }

  Future<void> _generateAndShare(GuidanceStudent s) async {
    String? path;
    if (FeatureFlags.reportsWordExport) {
      path = await _generatePdfReport(s);
    }
    path ??= await _generateReport(s);
    if (path != null && mounted) {
      setState(() => _reportPaths[s.id] = path);
      final file = XFile(path);
      await Share.shareXFiles(
        [file],
        text: '${s.fullName} - ${context.tr('studentStatusReport')}',
        subject: '${s.fullName} ${context.tr('studentStatusReport')}',
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('error'))),
      );
    }
  }

  Future<String?> _generatePdfReport(GuidanceStudent s) async {
    final repo = context.read<AppProvider>().repo;
    final profile = context.read<AppProvider>().profile;
    final assessments = repo.getAssessmentsByClass(s.classId).where((a) => a.studentId == s.id).toList();
    assessments.sort((a, b) => b.date.compareTo(a.date));
    final attendance = repo.getAttendanceByStudentId(s.id);
    final activities = repo.getGuidanceActivities().where((a) => a.participantIds.contains(s.id)).toList();
    activities.sort((a, b) => b.date.compareTo(a.date));
    final meetings = repo.getGuidanceMeetings().where((m) => m.participantIds.contains(s.id)).toList();
    meetings.sort((a, b) => b.date.compareTo(a.date));
    return StudentReportService.exportToPdf(
      student: s,
      assessments: assessments,
      attendance: attendance,
      activities: activities,
      meetings: meetings,
      profile: profile,
      teacherComment: _teacherComment.isNotEmpty ? _teacherComment : null,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('studentStatusReport')),
        actions: [
          if (FeatureFlags.reportsDateRangeFilter || FeatureFlags.reportsTeacherComment)
            IconButton(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('date'),
              onPressed: () => _showFilterDialog(context),
            ),
        ],
      ),
      body: _students.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(context.tr('noStudents'), style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (FeatureFlags.reportsDateRangeFilter && (_dateFrom != null || _dateTo != null))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Chip(
                      label: Text(
                        '${_dateFrom != null ? '${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}' : '...'} - ${_dateTo != null ? '${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}' : '...'}',
                      ),
                      onDeleted: () => setState(() {
                        _dateFrom = null;
                        _dateTo = null;
                      }),
                    ),
                  ),
                ...List.generate(_students.length, (i) {
                  final s = _students[i];
                  return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(s.fullName),
                    subtitle: Text('${s.classId} • ${s.studentNumber}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.preview),
                          tooltip: context.tr('preview'),
                          onPressed: () => _showPreviewAndShare(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          tooltip: context.tr('shareReport'),
                          onPressed: () => _generateAndShare(s),
                        ),
                      ],
                    ),
                    onTap: () => _showStudentDetail(context, s),
                  ),
                );
                }),
              ],
            ),
    );
  }
}

/// extra.md: Veli Özeti – sade dil, öğretmen yorumu, PDF / paylaşım
class ParentSummaryReportScreen extends StatefulWidget {
  const ParentSummaryReportScreen({super.key});

  @override
  State<ParentSummaryReportScreen> createState() => _ParentSummaryReportScreenState();
}

class _ParentSummaryReportScreenState extends State<ParentSummaryReportScreen> {
  List<GuidanceStudent> _students = [];
  GuidanceStudent? _selectedStudent;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final repo = context.read<AppProvider>().repo;
    _students = repo.getGuidanceStudents();
    setState(() {});
  }

  Future<void> _generateAndShare() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('studentLabel'))));
      return;
    }
    final s = _selectedStudent!;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/veli_ozeti_${s.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(context.tr('reportParentSummary'), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('${context.tr('studentLabel')}: ${s.fullName}'),
                pw.Text('${context.tr('classLabel')}: ${s.classId}'),
                pw.SizedBox(height: 16),
                pw.Text(context.tr('teacherComment'), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(_commentCtrl.text.trim().isEmpty ? '-' : _commentCtrl.text.trim()),
              ],
            ),
          ),
        ),
      );
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) {
        await Share.shareXFiles([XFile(path)], text: '${s.fullName} - ${context.tr('reportParentSummary')}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reportParentSummary')),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<GuidanceStudent>(
            value: _selectedStudent,
            decoration: InputDecoration(labelText: context.tr('studentLabel')),
            items: _students.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
            onChanged: (s) => setState(() => _selectedStudent = s),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            decoration: InputDecoration(
              labelText: context.tr('teacherComment'),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _generateAndShare,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(context.tr('shareReport')),
          ),
        ],
      ),
    );
  }
}

/// extra.md: Online Ders Katılım Özeti – ders bazlı ve öğrenci bazlı
class OnlineAttendanceReportScreen extends StatefulWidget {
  const OnlineAttendanceReportScreen({super.key});

  @override
  State<OnlineAttendanceReportScreen> createState() => _OnlineAttendanceReportScreenState();
}

class _OnlineAttendanceReportScreenState extends State<OnlineAttendanceReportScreen> {
  List<Map<String, dynamic>> _sessions = [];
  Map<String, String> _courseNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = context.read<AppProvider>().repo;
    _sessions = repo.getAllTeachOnlineSessionNotes();
    _courseNames = {
      for (final course in repo.getCourses()) course.id: course.displayName,
    };
    setState(() {});
  }

  List<_OnlineSessionViewModel> _parsedSessions() {
    return _sessions.map((session) {
      final raw = session['attendanceRecords']?.toString() ?? '';
      final records = <_OnlineAttendanceRecord>[];
      if (raw.isNotEmpty) {
        try {
          final decoded = List<Map<String, dynamic>>.from(
            (jsonDecode(raw) as List<dynamic>).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
          for (final item in decoded) {
            records.add(
              _OnlineAttendanceRecord(
                studentId: item['studentId']?.toString() ?? '',
                studentName: item['studentName']?.toString() ?? '-',
                attended: item['attended'] == true,
              ),
            );
          }
        } catch (_) {}
      }
      final courseId = session['courseId']?.toString() ?? '';
      return _OnlineSessionViewModel(
        courseName: _courseNames[courseId] ?? courseId,
        dateText: session['date']?.toString() ?? '',
        attendanceSummary: session['attendance']?.toString() ?? '',
        attendanceNote: session['attendanceNote']?.toString() ?? '',
        technicalNote: session['technical']?.toString() ?? '',
        reflection: session['reflection']?.toString() ?? '',
        recordingLink: session['recordingLink']?.toString() ?? '',
        records: records,
      );
    }).toList();
  }

  List<_OnlineStudentSummary> _studentSummaries(List<_OnlineSessionViewModel> sessions) {
    final map = <String, _OnlineStudentSummary>{};
    for (final session in sessions) {
      for (final record in session.records) {
        final key = record.studentId.isNotEmpty ? record.studentId : record.studentName;
        final existing = map[key];
        if (existing == null) {
          map[key] = _OnlineStudentSummary(
            studentName: record.studentName,
            attendedCount: record.attended ? 1 : 0,
            absentCount: record.attended ? 0 : 1,
            lessonCount: 1,
            latestDate: session.dateText,
          );
        } else {
          map[key] = existing.copyWith(
            attendedCount: existing.attendedCount + (record.attended ? 1 : 0),
            absentCount: existing.absentCount + (record.attended ? 0 : 1),
            lessonCount: existing.lessonCount + 1,
            latestDate: session.dateText.compareTo(existing.latestDate) > 0
                ? session.dateText
                : existing.latestDate,
          );
        }
      }
    }
    final result = map.values.toList()
      ..sort((a, b) => b.lessonCount.compareTo(a.lessonCount));
    return result;
  }

  Widget _buildLessonTab(List<_OnlineSessionViewModel> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (_, i) {
        final session = sessions[i];
        final attendedCount = session.records.where((e) => e.attended).length;
        final absentCount = session.records.length - attendedCount;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.videocam),
            title: Text(session.courseName),
            subtitle: Text(
              session.dateText.isEmpty
                  ? session.attendanceSummary
                  : '${session.dateText} • ${session.attendanceSummary}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${context.tr('present')}: $attendedCount')),
                  Chip(label: Text('${context.tr('absent')}: $absentCount')),
                  if (session.records.isEmpty)
                    Chip(label: Text(context.tr('reportNoStructuredAttendance'))),
                ],
              ),
              if (session.records.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...session.records.map(
                  (record) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      record.attended ? Icons.check_circle : Icons.cancel_outlined,
                      color: record.attended ? Colors.green : Colors.red,
                    ),
                    title: Text(record.studentName),
                    subtitle: Text(
                      record.attended ? context.tr('present') : context.tr('absent'),
                    ),
                  ),
                ),
              ],
              if (session.attendanceNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${context.tr('notes')}: ${session.attendanceNote}'),
              ],
              if (session.technicalNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${context.tr('teachTechnicalNote')}: ${session.technicalNote}'),
              ],
              if (session.reflection.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${context.tr('teachReflectionNote')}: ${session.reflection}'),
              ],
              if (session.recordingLink.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${context.tr('teachRecordingLink')}: ${session.recordingLink}'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTab(List<_OnlineStudentSummary> summaries) {
    if (summaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.tr('reportNoStructuredAttendance'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: summaries.length,
      itemBuilder: (_, i) {
        final summary = summaries[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(summary.studentName),
            subtitle: Text(
              '${context.tr('present')}: ${summary.attendedCount} • '
              '${context.tr('absent')}: ${summary.absentCount} • '
              '${context.tr('lessons')}: ${summary.lessonCount}',
            ),
            trailing: summary.latestDate.isEmpty
                ? null
                : Text(
                    summary.latestDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final sessions = _parsedSessions();
    final studentSummaries = _studentSummaries(sessions);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('reportOnlineAttendance')),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          actions: const [AppBarActions()],
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('reportPerLesson')),
              Tab(text: context.tr('reportPerStudent')),
            ],
          ),
        ),
        body: _sessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.tr('groupOnlineEmpty'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : TabBarView(
                children: [
                  _buildLessonTab(sessions),
                  _buildStudentTab(studentSummaries),
                ],
              ),
      ),
    );
  }
}

class _OnlineSessionViewModel {
  const _OnlineSessionViewModel({
    required this.courseName,
    required this.dateText,
    required this.attendanceSummary,
    required this.attendanceNote,
    required this.technicalNote,
    required this.reflection,
    required this.recordingLink,
    required this.records,
  });

  final String courseName;
  final String dateText;
  final String attendanceSummary;
  final String attendanceNote;
  final String technicalNote;
  final String reflection;
  final String recordingLink;
  final List<_OnlineAttendanceRecord> records;
}

class _OnlineAttendanceRecord {
  const _OnlineAttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.attended,
  });

  final String studentId;
  final String studentName;
  final bool attended;
}

class _OnlineStudentSummary {
  const _OnlineStudentSummary({
    required this.studentName,
    required this.attendedCount,
    required this.absentCount,
    required this.lessonCount,
    required this.latestDate,
  });

  final String studentName;
  final int attendedCount;
  final int absentCount;
  final int lessonCount;
  final String latestDate;

  _OnlineStudentSummary copyWith({
    String? studentName,
    int? attendedCount,
    int? absentCount,
    int? lessonCount,
    String? latestDate,
  }) {
    return _OnlineStudentSummary(
      studentName: studentName ?? this.studentName,
      attendedCount: attendedCount ?? this.attendedCount,
      absentCount: absentCount ?? this.absentCount,
      lessonCount: lessonCount ?? this.lessonCount,
      latestDate: latestDate ?? this.latestDate,
    );
  }
}
