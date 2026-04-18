import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/app_translations.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../core/utils/locale_provider.dart';
import '../lesson_planner/planner_split_view.dart';

/// Rapor & Çıktılar: Zümre toplantı katılım özeti, Kişisel faaliyet raporu, Görev tamamlanma listesi
class ZumreReportsScreen extends StatelessWidget {
  const ZumreReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    return _ZumreReportsHome(
      onGenerateAnnualSummary: () => _generateAnnualSummary(context),
      onGenerateAttendanceReport: () => _generateAttendanceReport(context),
      onGenerateActivityReport: () => _generateActivityReport(context),
      onGenerateTasksReport: () => _generateTasksReport(context),
    );
  }

  Future<void> _generateAnnualSummary(BuildContext context) async {
    final repo = context.read<AppProvider>().repo;
    final localeCode = context.read<LocaleProvider>().effectiveLocale.languageCode;
    final isTr = localeCode == 'tr';
    final meetings = repo.getZumreMeetings()..sort((a, b) => a.meetingDate.compareTo(b.meetingDate));
    final tasks = repo.getZumreTasks();
    final decisions = repo.getZumreDecisions();
    final contributions = repo.getZumreContributions();
    final notes = repo.getZumreNotes();
    final doneTasks = tasks.where((t) => t.status == 'tamamlandi').length;

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln(isTr ? '       ZÜMRE YILLIK ÖZET' : '       DEPARTMENT ANNUAL SUMMARY');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('${isTr ? 'Toplantı sayısı' : 'Meetings'}: ${meetings.length}');
    buffer.writeln('${isTr ? 'Görevler (toplam / tamamlanan)' : 'Tasks (total / done)'}: ${tasks.length} / $doneTasks');
    buffer.writeln('${isTr ? 'Karar sayısı' : 'Decisions'}: ${decisions.length}');
    buffer.writeln('${isTr ? 'Katkı sayısı' : 'Contributions'}: ${contributions.length}');
    buffer.writeln('${isTr ? 'Not sayısı' : 'Notes'}: ${notes.length}');
    buffer.writeln();
    if (meetings.isNotEmpty) {
      buffer.writeln('${isTr ? 'Toplantı tarihleri' : 'Meeting dates'}:');
      for (final m in meetings.take(20)) {
        buffer.writeln('  • ${m.meetingDate.day}/${m.meetingDate.month}/${m.meetingDate.year}');
      }
      if (meetings.length > 20) buffer.writeln('  ... +${meetings.length - 20}');
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════');

    await _saveAndShare(context, buffer.toString(), 'zumre_annual_summary');
  }

  Future<void> _generateAttendanceReport(BuildContext context) async {
    final repo = context.read<AppProvider>().repo;
    final localeCode = context.read<LocaleProvider>().effectiveLocale.languageCode;
    final meetings = repo.getZumreMeetings()..sort((a, b) => b.meetingDate.compareTo(a.meetingDate));
    final isTr = localeCode == 'tr';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln(isTr ? '       ZÜMRE TOPLANTI KATILIM ÖZETİ' : '       DEPARTMENT MEETING ATTENDANCE SUMMARY');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    for (final m in meetings) {
      final typeKey = m.meetingType == 'donem_basi' ? 'zumre_meeting_type_start' : m.meetingType == 'donem_sonu' ? 'zumre_meeting_type_end' : 'zumre_meeting_type_mid';
      buffer.writeln('• ${m.meetingDate.day}/${m.meetingDate.month}/${m.meetingDate.year} - ${AppTranslations.tr(localeCode, typeKey)}');
      if (m.agendaItems.isNotEmpty) buffer.writeln('  ${isTr ? 'Gündem' : 'Agenda'}: ${m.agendaItems}');
      if (m.nextMeetingDate != null) buffer.writeln('  ${isTr ? 'Sonraki toplantı' : 'Next meeting'}: ${m.nextMeetingDate!.day}/${m.nextMeetingDate!.month}/${m.nextMeetingDate!.year}');
      buffer.writeln();
    }
    buffer.writeln('═══════════════════════════════════════════════════');

    await _saveAndShare(context, buffer.toString(), 'zumre_attendance');
  }

  Future<void> _generateActivityReport(BuildContext context) async {
    final repo = context.read<AppProvider>().repo;
    final contributions = repo.getZumreContributions()..sort((a, b) => b.date.compareTo(a.date));
    final notes = repo.getZumreNotes()..sort((a, b) => b.date.compareTo(a.date));
    final localeCode = context.read<LocaleProvider>().effectiveLocale.languageCode;
    final isTr = localeCode == 'tr';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln(isTr ? '       KİŞİSEL ZÜMRE FAALİYET RAPORU' : '       PERSONAL DEPARTMENT ACTIVITY REPORT');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln(isTr ? 'Katkılarım:' : 'My contributions:');
    for (final c in contributions) {
      buffer.writeln('• ${AppTranslations.tr(localeCode, 'zumre_contribution_type_' + c.contributionType)} - ${c.date.day}/${c.date.month}/${c.date.year}');
      if (c.description.isNotEmpty) buffer.writeln('  ${c.description}');
    }
    buffer.writeln();
    buffer.writeln(isTr ? 'Notlar & Gözlemler:' : 'Notes & observations:');
    for (final n in notes) {
      buffer.writeln('• ${n.title} - ${n.date.day}/${n.date.month}/${n.date.year}');
      if (n.description.isNotEmpty) buffer.writeln('  ${n.description}');
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════');

    await _saveAndShare(context, buffer.toString(), 'zumre_activity');
  }

  Future<void> _generateTasksReport(BuildContext context) async {
    final repo = context.read<AppProvider>().repo;
    final tasks = repo.getZumreTasks();
    final done = tasks.where((t) => t.status == 'tamamlandi').toList();
    final pending = tasks.where((t) => t.status != 'tamamlandi').toList();
    final localeCode = context.read<LocaleProvider>().effectiveLocale.languageCode;
    final isTr = localeCode == 'tr';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln(isTr ? '       GÖREV TAMAMLANMA LİSTESİ' : '       TASK COMPLETION LIST');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('${isTr ? 'Tamamlanan' : 'Completed'}: ${done.length}');
    for (final t in done) {
      buffer.writeln('✓ ${t.title}');
      if (t.dueDate != null) buffer.writeln('  ${isTr ? 'Tarih' : 'Date'}: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}');
    }
    buffer.writeln();
    buffer.writeln('${isTr ? 'Bekleyen / Devam eden' : 'Pending / In progress'}: ${pending.length}');
    for (final t in pending) {
      buffer.writeln('○ ${t.title}');
      if (t.dueDate != null) buffer.writeln('  ${isTr ? 'Tarih' : 'Date'}: ${t.dueDate!.day}/${t.dueDate!.month}/${t.dueDate!.year}');
    }
    buffer.writeln();
    buffer.writeln('═══════════════════════════════════════════════════');

    await _saveAndShare(context, buffer.toString(), 'zumre_tasks');
  }

  Future<void> _saveAndShare(BuildContext context, String content, String filename) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/zumre_reports');
      if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
      final file = File('${reportsDir.path}/$filename.txt');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('exportError')}: $e')),
        );
      }
    }
  }
}

class _ZumreReportsHome extends StatefulWidget {
  const _ZumreReportsHome({
    required this.onGenerateAnnualSummary,
    required this.onGenerateAttendanceReport,
    required this.onGenerateActivityReport,
    required this.onGenerateTasksReport,
  });

  final VoidCallback onGenerateAnnualSummary;
  final VoidCallback onGenerateAttendanceReport;
  final VoidCallback onGenerateActivityReport;
  final VoidCallback onGenerateTasksReport;

  @override
  State<_ZumreReportsHome> createState() => _ZumreReportsHomeState();
}

class _ZumreReportsHomeState extends State<_ZumreReportsHome> {
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 1100;
    final items = [
      if (FeatureFlags.zumreAnnualSummary)
        _ZumreReportItem(
          keyName: 'annual',
          icon: Icons.summarize,
          title: context.tr('zumre_annual_summary'),
          subtitle: context.tr('zumre_annual_summary_subtitle'),
          onTap: widget.onGenerateAnnualSummary,
        ),
      _ZumreReportItem(
        keyName: 'attendance',
        icon: Icons.groups,
        title: context.tr('zumre_report_attendance'),
        subtitle: context.tr('zumre_report_attendance_subtitle'),
        onTap: widget.onGenerateAttendanceReport,
      ),
      _ZumreReportItem(
        keyName: 'activity',
        icon: Icons.person_pin,
        title: context.tr('zumre_report_activity'),
        subtitle: context.tr('zumre_report_activity_subtitle'),
        onTap: widget.onGenerateActivityReport,
      ),
      _ZumreReportItem(
        keyName: 'tasks',
        icon: Icons.task_alt,
        title: context.tr('zumre_report_tasks'),
        subtitle: context.tr('zumre_report_tasks_subtitle'),
        onTap: widget.onGenerateTasksReport,
      ),
    ];
    final selected = items.where((item) => item.keyName == _selectedKey).cast<_ZumreReportItem?>().firstWhere((item) => item != null, orElse: () => null);

    return PlannerSplitView(
      emptyState: _buildPlaceholder(context),
      onClosePanel: selected != null ? () => setState(() => _selectedKey = null) : null,
      sidePanel: selected != null ? _buildPanel(context, selected) : null,
      content: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, i) {
          final item = items[i];
          return Card(
            color: item.keyName == _selectedKey
                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
                : null,
            child: ListTile(
              leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: isWide ? const Icon(Icons.chevron_right) : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (isWide) {
                  setState(() => _selectedKey = item.keyName);
                } else {
                  item.onTap();
                }
              },
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.tr('selectItemToOpenSidebar'), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, _ZumreReportItem item) {
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
            onPressed: item.onTap,
            icon: Icon(item.icon),
            label: Text(item.title),
          ),
        ],
      ),
    );
  }
}

class _ZumreReportItem {
  const _ZumreReportItem({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
