import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/lesson_planner_models.dart';

class AnnualPlanMetadataDialog extends StatefulWidget {
  const AnnualPlanMetadataDialog({
    required this.initial,
    super.key,
  });

  final AnnualPlanMetadata initial;

  @override
  State<AnnualPlanMetadataDialog> createState() =>
      _AnnualPlanMetadataDialogState();
}

class _AnnualPlanMetadataDialogState extends State<AnnualPlanMetadataDialog> {
  late final TextEditingController _institutionCtrl;
  late final TextEditingController _academicCalendarCtrl;
  late final TextEditingController _courseCtrl;
  late final TextEditingController _classesCtrl;
  late final TextEditingController _annualHoursCtrl;
  late final TextEditingController _weeklyHoursCtrl;
  late final TextEditingController _totalWeeksCtrl;
  late final TextEditingController _examCountCtrl;
  late final TextEditingController _booksCtrl;
  late final TextEditingController _courseTeacherCtrl;
  late final TextEditingController _departmentHeadCtrl;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    final profile = context.read<AppProvider>().profile;
    _institutionCtrl = TextEditingController(text: m.institutionName.isNotEmpty ? m.institutionName : profile?.schoolName ?? '');
    _academicCalendarCtrl = TextEditingController(text: m.academicCalendar);
    _courseCtrl = TextEditingController(text: m.courseName);
    _classesCtrl = TextEditingController(text: m.classes.isNotEmpty ? m.classes : (profile?.classesTaught.join(', ') ?? ''));
    _annualHoursCtrl = TextEditingController(text: m.annualHours);
    _weeklyHoursCtrl = TextEditingController(text: m.weeklyHours);
    _totalWeeksCtrl = TextEditingController(text: m.totalWeeks);
    _examCountCtrl = TextEditingController(text: m.examCount);
    _booksCtrl = TextEditingController(text: m.books);
    _courseTeacherCtrl = TextEditingController(text: m.courseTeacherNameSignature);
    _departmentHeadCtrl = TextEditingController(text: m.departmentHeadNameSignature);
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _academicCalendarCtrl.dispose();
    _courseCtrl.dispose();
    _classesCtrl.dispose();
    _annualHoursCtrl.dispose();
    _weeklyHoursCtrl.dispose();
    _totalWeeksCtrl.dispose();
    _examCountCtrl.dispose();
    _booksCtrl.dispose();
    _courseTeacherCtrl.dispose();
    _departmentHeadCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final m = AnnualPlanMetadata(
      institutionName: _institutionCtrl.text.trim(),
      academicCalendar: _academicCalendarCtrl.text.trim(),
      courseName: _courseCtrl.text.trim(),
      classes: _classesCtrl.text.trim(),
      annualHours: _annualHoursCtrl.text.trim(),
      weeklyHours: _weeklyHoursCtrl.text.trim(),
      totalWeeks: _totalWeeksCtrl.text.trim(),
      examCount: _examCountCtrl.text.trim(),
      books: _booksCtrl.text.trim(),
      courseTeacherNameSignature: _courseTeacherCtrl.text.trim(),
      departmentHeadNameSignature: _departmentHeadCtrl.text.trim(),
    );
    Navigator.pop(context, m);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('annualPlanInfo')),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _institutionCtrl,
                decoration: InputDecoration(labelText: context.tr('institutionName')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _academicCalendarCtrl,
                decoration: InputDecoration(labelText: context.tr('academicCalendar')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseCtrl,
                decoration: InputDecoration(labelText: context.tr('courseName')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _classesCtrl,
                decoration: InputDecoration(labelText: context.tr('classesLabel')),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _annualHoursCtrl,
                      decoration: InputDecoration(labelText: context.tr('annualHours')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weeklyHoursCtrl,
                      decoration: InputDecoration(labelText: context.tr('weeklyHours')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _totalWeeksCtrl,
                      decoration: InputDecoration(labelText: context.tr('totalWeeks')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _examCountCtrl,
                      decoration: InputDecoration(labelText: context.tr('examCount')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _booksCtrl,
                decoration: InputDecoration(labelText: context.tr('books')),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseTeacherCtrl,
                decoration: InputDecoration(labelText: context.tr('courseTeacherNameSignature')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _departmentHeadCtrl,
                decoration: InputDecoration(labelText: context.tr('departmentHeadNameSignature')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
