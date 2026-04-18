import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/locale_provider.dart';
import '../../core/widgets/app_bar_actions.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/attendance_record.dart';
import '../../data/repositories/app_repository.dart';

/// Daily attendance per class, one-tap absent/late
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClass;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleProvider>();
    final profile = context.watch<AppProvider>().profile;
    final classes = profile?.classesTaught ?? [];
    _selectedClass ??= classes.isNotEmpty ? classes.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('attendance')),
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
          ListTile(
            title: Text(context.tr('date')),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
          ),
          Expanded(
            child: _selectedClass == null
                ? Center(child: Text(context.tr('noStudents')))
                : _AttendanceList(
                    classId: _selectedClass!,
                    date: _selectedDate,
                  ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceList extends StatelessWidget {
  const _AttendanceList({required this.classId, required this.date});

  final String classId;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppProvider>().repo;
    final students = repo.getStudentsByClass(classId);
    final records = repo.getAttendanceByDateAndClass(date, classId);
    final recordMap = {for (var r in records) r.studentId: r};

    if (students.isEmpty) {
      return Center(child: Text(context.tr('noStudents')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (_, i) {
        final s = students[i];
        final rec = recordMap[s.id];
        final status = rec?.status ?? AttendanceStatus.present;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(s.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(
                  label: context.tr('present'),
                  selected: status == AttendanceStatus.present,
                  color: Colors.green,
                  onTap: () => _setStatus(context, s.id, AttendanceStatus.present),
                ),
                const SizedBox(width: 4),
                _StatusChip(
                  label: context.tr('late'),
                  selected: status == AttendanceStatus.late,
                  color: Colors.orange,
                  onTap: () => _setStatus(context, s.id, AttendanceStatus.late),
                ),
                const SizedBox(width: 4),
                _StatusChip(
                  label: context.tr('absent'),
                  selected: status == AttendanceStatus.absent,
                  color: Colors.red,
                  onTap: () => _setStatus(context, s.id, AttendanceStatus.absent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    String studentId,
    AttendanceStatus status,
  ) async {
    final repo = context.read<AppProvider>().repo;
    final record = AttendanceRecord(
      id: AppRepository.generateId(),
      studentId: studentId,
      classId: classId,
      date: date,
      status: status,
      createdAt: DateTime.now(),
    );
    await repo.saveAttendance(record);
    if (context.mounted) {
      context.read<AppProvider>().refresh();
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : color,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
