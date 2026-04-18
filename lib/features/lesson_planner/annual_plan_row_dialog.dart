import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/repositories/app_repository.dart';

class AnnualPlanRowDialog extends StatefulWidget {
  const AnnualPlanRowDialog({this.row, this.rowNo = 1, super.key});

  final AnnualPlanRow? row;
  final int rowNo;

  @override
  State<AnnualPlanRowDialog> createState() => _AnnualPlanRowDialogState();
}

class _AnnualPlanRowDialogState extends State<AnnualPlanRowDialog> {
  late final TextEditingController _rowNoCtrl, _weekCtrl, _lessonCtrl, _classCtrl;
  late final TextEditingController _topicCtrl, _outcomeCtrl, _homeworkCtrl;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    _rowNoCtrl = TextEditingController(text: '${r?.rowNo ?? widget.rowNo}');
    _weekCtrl = TextEditingController(text: r != null ? '${r.weekNo}' : '');
    _lessonCtrl = TextEditingController(text: r != null ? '${r.lessonNo}' : '');
    _classCtrl = TextEditingController(text: r?.classId ?? '');
    _topicCtrl = TextEditingController(text: r?.topic ?? '');
    _outcomeCtrl = TextEditingController(text: r?.outcome ?? '');
    _homeworkCtrl = TextEditingController(text: r?.homework ?? '');
    if (r != null) _date = r.date;
  }

  @override
  void dispose() {
    _rowNoCtrl.dispose();
    _weekCtrl.dispose();
    _lessonCtrl.dispose();
    _classCtrl.dispose();
    _topicCtrl.dispose();
    _outcomeCtrl.dispose();
    _homeworkCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final row = AnnualPlanRow(
      id: widget.row?.id ?? AppRepository.generateId(),
      rowNo: int.tryParse(_rowNoCtrl.text) ?? 1,
      weekNo: int.tryParse(_weekCtrl.text) ?? 0,
      lessonNo: int.tryParse(_lessonCtrl.text) ?? 0,
      date: _date,
      classId: _classCtrl.text.trim(),
      topic: _topicCtrl.text.trim(),
      outcome: _outcomeCtrl.text.trim(),
      homework: _homeworkCtrl.text.trim(),
    );
    Navigator.pop(context, row);
  }

  @override
  Widget build(BuildContext context) {
    final classes = _buildClassList();

    return AlertDialog(
      title: Text(widget.row != null ? context.tr('editRow') : context.tr('addRow')),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _rowNoCtrl,
                      decoration: InputDecoration(labelText: context.tr('rowNo')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _weekCtrl,
                      decoration: InputDecoration(labelText: context.tr('weekNo')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _lessonCtrl,
                      decoration: InputDecoration(labelText: context.tr('lessonNo')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('${context.tr('date')}: ${_date.day}/${_date.month}/${_date.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _classCtrl.text.isEmpty ? null : (classes.contains(_classCtrl.text) ? _classCtrl.text : null),
                decoration: InputDecoration(labelText: context.tr('classLabel')),
                items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  _classCtrl.text = v ?? '';
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _topicCtrl,
                decoration: InputDecoration(labelText: context.tr('topic')),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _outcomeCtrl,
                decoration: InputDecoration(labelText: context.tr('outcome')),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _homeworkCtrl,
                decoration: InputDecoration(labelText: context.tr('homeworkLabel')),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(onPressed: _save, child: Text(context.tr('save'))),
      ],
    );
  }

  List<String> _buildClassList() {
    final list = <String>[];
    for (final g in AppConstants.grades) {
      for (final b in AppConstants.branches) {
        list.add('$g$b');
      }
    }
    return list;
  }
}
