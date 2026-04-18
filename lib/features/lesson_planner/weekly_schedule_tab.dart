import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/feature_flags.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';

class WeeklyScheduleTab extends StatefulWidget {
  const WeeklyScheduleTab({super.key});

  @override
  State<WeeklyScheduleTab> createState() => _WeeklyScheduleTabState();
}

class _WeeklyScheduleTabState extends State<WeeklyScheduleTab> {
  Map<String, String> _schedule = {};
  DateTime _selectedWeekStart = _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static int _getWeekNumber(DateTime date) {
    final weekStart = _getWeekStart(date);
    final jan1 = DateTime(weekStart.year, 1, 1);
    final days = weekStart.difference(jan1).inDays;
    return (days / 7).floor() + 1;
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final locale = Localizations.localeOf(context).toString();
    final fmt = intl.DateFormat('d MMM', locale);
    final fmtEnd = intl.DateFormat('d MMM yyyy', locale);
    return '${context.tr('week')} ${_getWeekNumber(weekStart)}: '
        '${fmt.format(weekStart)} - ${fmtEnd.format(weekEnd)}';
  }

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  void _loadSchedule() {
    final repo = context.read<AppProvider>().repo;
    _schedule = FeatureFlags.weeklyCopyWeek
        ? repo.getWeeklyScheduleForWeek(_selectedWeekStart)
        : repo.getWeeklySchedule();
    setState(() {});
  }

  void _showClassPicker(int day, int hour) {
    final classes = <String>[];
    for (final g in AppConstants.grades) {
      for (final b in AppConstants.branches) {
        classes.add('$g$b');
      }
    }

    final key = '${day}_$hour';
    final currentVal = _schedule[key] ?? '';
    final isOnline = currentVal.contains('|online');
    final currentClass = isOnline ? currentVal.replaceAll('|online', '') : currentVal;

    String? selectedClass = currentClass.isNotEmpty && classes.contains(currentClass) ? currentClass : null;
    bool online = isOnline;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('selectClass'), style: Theme.of(ctx).textTheme.titleLarge),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClass,
                  decoration: InputDecoration(labelText: context.tr('classLabel')),
                  items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => selectedClass = v),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(context.tr('onlineLesson')),
                  value: online,
                  onChanged: (v) => setModalState(() => online = v ?? false),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (currentVal.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          final repo = context.read<AppProvider>().repo;
                          if (FeatureFlags.weeklyCopyWeek) {
                            repo.saveWeeklyScheduleCellForWeek(day, hour, '', _selectedWeekStart);
                          } else {
                            repo.saveWeeklyScheduleCell(day, hour, '');
                          }
                          _loadSchedule();
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete),
                        label: Text(context.tr('delete')),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        if (selectedClass != null) {
                          final val = online ? '$selectedClass|online' : selectedClass!;
                          final repo = context.read<AppProvider>().repo;
                          if (FeatureFlags.weeklyCopyWeek) {
                            repo.saveWeeklyScheduleCellForWeek(day, hour, val, _selectedWeekStart);
                          } else {
                            repo.saveWeeklyScheduleCell(day, hour, val);
                          }
                          _loadSchedule();
                          Navigator.pop(ctx);
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

  Future<void> _copyWeekToWeek() async {
    final target = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart.add(const Duration(days: 7)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (target == null || !mounted) return;
    final targetWeekStart = _getWeekStart(target);
    if (targetWeekStart.year == _selectedWeekStart.year &&
        targetWeekStart.month == _selectedWeekStart.month &&
        targetWeekStart.day == _selectedWeekStart.day) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a different week')),
        );
      }
      return;
    }
    await context.read<AppProvider>().repo.copyWeeklySchedule(_selectedWeekStart, targetWeekStart);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('weeklyCopyWeekTo')}: ${_formatWeekRange(targetWeekStart)}')),
      );
    }
  }

  void _copyScheduleLink() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('              HAFTALIK DERS PROGRAMI');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    final days = [context.tr('weekDay0'), context.tr('weekDay1'), context.tr('weekDay2'), context.tr('weekDay3'), context.tr('weekDay4'), context.tr('weekDay5'), context.tr('weekDay6')];
    for (int h = 0; h < AppConstants.lessonCount; h++) {
      buffer.write('${h + 1}. ${context.tr('lesson')} (${AppConstants.formatLessonTime(h)}): ');
      for (int d = 0; d < 7; d++) {
        final key = '${d}_$h';
        final raw = _schedule[key];
        final isOnline = raw != null && raw.contains('|online');
        final classId = raw != null ? raw.replaceAll('|online', '') : '';
        buffer.write('${days[d]}: ${classId.isNotEmpty ? (isOnline ? '$classId (${context.tr("online")})' : classId) : '-'}  ');
      }
      buffer.writeln();
    }
    buffer.writeln('═══════════════════════════════════════════════════');
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('copiedToClipboard'))),
    );
  }

  Future<void> _shareSchedule() async {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('              HAFTALIK DERS PROGRAMI');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    final days = [context.tr('weekDay0'), context.tr('weekDay1'), context.tr('weekDay2'), context.tr('weekDay3'), context.tr('weekDay4'), context.tr('weekDay5'), context.tr('weekDay6')];
    for (int h = 0; h < AppConstants.lessonCount; h++) {
      buffer.write('${h + 1}. ${context.tr('lesson')} (${AppConstants.formatLessonTime(h)}): ');
      for (int d = 0; d < 7; d++) {
        final key = '${d}_$h';
        final raw = _schedule[key];
        final isOnline = raw != null && raw.contains('|online');
        final classId = raw != null ? raw.replaceAll('|online', '') : '';
        buffer.write('${days[d]}: ${classId.isNotEmpty ? (isOnline ? '$classId (${context.tr("online")})' : classId) : '-'}  ');
      }
      buffer.writeln();
    }
    buffer.writeln('═══════════════════════════════════════════════════');
    await Share.share(buffer.toString(), subject: context.tr('weeklySchedule'));
  }

  Future<void> _pickWeek() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedWeekStart.add(const Duration(days: 3)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d != null) {
      setState(() => _selectedWeekStart = _getWeekStart(d));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentWeekStart = _getWeekStart(now);
    final isCurrentWeek = _selectedWeekStart.year == currentWeekStart.year &&
        _selectedWeekStart.month == currentWeekStart.month &&
        _selectedWeekStart.day == currentWeekStart.day;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(context.tr('weeklySchedule'), style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (FeatureFlags.weeklyCopyWeek)
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: context.tr('weeklyCopyWeek'),
                  onPressed: _schedule.isNotEmpty ? _copyWeekToWeek : null,
                ),
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: context.tr('copyLink'),
                onPressed: _schedule.isNotEmpty ? _copyScheduleLink : null,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: context.tr('shareWeeklyPlan'),
                onPressed: _schedule.isNotEmpty ? _shareSchedule : null,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                InkWell(
                onTap: _pickWeek,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatWeekRange(_selectedWeekStart)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurface),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () => setState(() => _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chevron_left, size: 20),
                    const SizedBox(width: 4),
                    Text(context.tr('prevWeek')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isCurrentWeek
                    ? null
                    : () => setState(() => _selectedWeekStart = currentWeekStart),
                style: FilledButton.styleFrom(
                  backgroundColor: isCurrentWeek ? Colors.green : null,
                  foregroundColor: isCurrentWeek ? Colors.white : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.today, size: 20),
                    const SizedBox(width: 4),
                    Text(context.tr('currentWeek')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () => setState(() => _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.tr('nextWeek')),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        Expanded(
          child: LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 800.0;
        final tableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 600.0;
        final colWidth = (tableWidth - 32) / 8;
        final rowHeight = (tableHeight - 32) / (AppConstants.lessonCount + 1);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tableWidth,
                minHeight: tableHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Table(
                  border: TableBorder.all(color: Theme.of(context).dividerColor),
                  columnWidths: {
                    for (int i = 0; i < 8; i++) i: FixedColumnWidth(colWidth),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                      children: [
                        SizedBox(height: rowHeight, child: _headerCell('')),
                        for (int d = 0; d < 7; d++) SizedBox(height: rowHeight, child: _headerCell(context.tr('weekDay$d'))),
                      ],
                    ),
                    for (int h = 0; h < AppConstants.lessonCount; h++)
                      TableRow(
                        children: [
                          SizedBox(
                            height: rowHeight,
                            child: _headerCell(
                              '${h + 1}. ${context.tr('lesson')}\n${AppConstants.formatLessonTime(h)}',
                            ),
                          ),
                          for (int d = 0; d < 7; d++) SizedBox(height: rowHeight, child: _scheduleCell(d, h)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
        ),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _scheduleCell(int day, int hour) {
    final key = '${day}_$hour';
    final raw = _schedule[key];
    final isOnline = raw?.contains('|online') ?? false;
    final classId = raw?.replaceAll('|online', '') ?? '';
    final display = classId.isNotEmpty
        ? (isOnline ? '$classId (${context.tr('online')})' : classId)
        : null;

    return InkWell(
      onTap: () => _showClassPicker(day, hour),
      child: Container(
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Center(
          child: display != null
              ? Text(display, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center)
              : const Icon(Icons.add, size: 20),
        ),
      ),
    );
  }
}
