import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/tr_extension.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/repositories/app_repository.dart';

class LessonDocumentDialog extends StatefulWidget {
  const LessonDocumentDialog({super.key, this.hideClassSelector = false});

  final bool hideClassSelector;

  @override
  State<LessonDocumentDialog> createState() => _LessonDocumentDialogState();
}

class _LessonDocumentDialogState extends State<LessonDocumentDialog> {
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String _classId = '1A';
  String _format = 'PDF';
  String? _selectedFilePath;
  bool _addAsLink = false; // true = URL ile ekle, false = dosya seç

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _urlCtrl.text = _selectedFilePath ?? '';
      });
    }
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() => _urlCtrl.text = data.text!.trim());
    }
  }

  void _save() {
    final pathOrUrl = _addAsLink ? _urlCtrl.text.trim() : (_selectedFilePath ?? _urlCtrl.text.trim());
    final doc = LessonDocument(
      id: AppRepository.generateId(),
      classId: _classId,
      name: _nameCtrl.text.trim(),
      format: _format,
      pathOrUrl: pathOrUrl.isEmpty ? null : pathOrUrl,
    );
    Navigator.pop(context, doc);
  }

  @override
  Widget build(BuildContext context) {
    final classes = _buildClassList();

    return AlertDialog(
      title: Text(context.tr('addDocument')),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.hideClassSelector) ...[
              DropdownButtonFormField<String>(
                value: _classId,
                decoration: InputDecoration(labelText: context.tr('classLabel')),
                items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _classId = v ?? '1A'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: context.tr('documentName')),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(context.tr('selectFileButton')), icon: const Icon(Icons.folder_open, size: 18)),
                ButtonSegment(value: true, label: Text(context.tr('addAsLink')), icon: const Icon(Icons.link, size: 18)),
              ],
              selected: {_addAsLink},
              onSelectionChanged: (v) => setState(() {
                _addAsLink = v.first;
                if (_addAsLink) {
                  _format = 'Link';
                  _selectedFilePath = null;
                } else {
                  _format = 'PDF';
                }
              }),
            ),
            if (!_addAsLink) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _format,
                decoration: InputDecoration(labelText: context.tr('format')),
                items: AppConstants.documentFormats
                    .where((f) => f != 'Link')
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _format = v ?? 'PDF'),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      labelText: _addAsLink ? context.tr('pasteUrl') : context.tr('filePathOrUrl'),
                      hintText: _addAsLink ? 'https://...' : context.tr('filePathOrUrl'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_addAsLink)
                  FilledButton.icon(
                    onPressed: _pasteUrl,
                    icon: const Icon(Icons.content_paste, size: 20),
                    label: Text(context.tr('pasteUrl')),
                  )
                else
                  FilledButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open, size: 20),
                    label: Text(context.tr('selectFileButton')),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
        FilledButton(onPressed: _save, child: Text(context.tr('add'))),
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
