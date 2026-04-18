import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/feature_flags.dart';
import '../../core/localization/tr_extension.dart';
import '../../core/utils/app_provider.dart';
import '../../data/models/lesson_planner_models.dart';
import '../../data/services/annual_plan_export_service.dart';
import 'annual_plan_metadata_dialog.dart';
import 'annual_plan_row_dialog.dart';

class AnnualPlanTab extends StatefulWidget {
  const AnnualPlanTab({super.key});

  @override
  State<AnnualPlanTab> createState() => _AnnualPlanTabState();
}

class _AnnualPlanTabState extends State<AnnualPlanTab> {
  List<AnnualPlanRow> _rows = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  void _load() {
    if (!mounted) return;
    final list = context.read<AppProvider>().repo.getAnnualPlan();
    list.sort((a, b) {
      if (a.rowNo == 1 && b.rowNo != 1) return -1;
      if (a.rowNo != 1 && b.rowNo == 1) return 1;
      final rowCmp = a.rowNo.compareTo(b.rowNo);
      if (rowCmp != 0) return rowCmp;
      return a.lessonNo.compareTo(b.lessonNo);
    });
    _rows = list;
    setState(() {});
  }

  Future<void> _addRow() async {
    final nextNo = _rows.isEmpty ? 1 : (_rows.map((r) => r.rowNo).reduce((a, b) => a > b ? a : b) + 1);
    final row = await showDialog<AnnualPlanRow>(
      context: context,
      builder: (_) => AnnualPlanRowDialog(rowNo: nextNo),
    );
    if (row != null && mounted) {
      await context.read<AppProvider>().repo.addAnnualPlanRow(row);
      _load();
    }
  }

  Future<void> _editRow(AnnualPlanRow r) async {
    final updated = await showDialog<AnnualPlanRow>(
      context: context,
      builder: (_) => AnnualPlanRowDialog(row: r),
    );
    if (updated != null && mounted) {
      await context.read<AppProvider>().repo.updateAnnualPlanRow(updated);
      _load();
    }
  }

  Future<void> _shareAsPdf() async {
    if (_rows.isEmpty) return;
    final metadata = await showDialog<AnnualPlanMetadata>(
      context: context,
      builder: (_) => AnnualPlanMetadataDialog(initial: const AnnualPlanMetadata()),
    );
    if (metadata == null || !mounted) return;
    String? path;
    try {
      path = await AnnualPlanExportService.exportToPdf(_rows, metadata: metadata);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('exportError')}: $e')),
        );
      }
      return;
    }
    if (path == null || !File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('exportError')), duration: const Duration(seconds: 4)),
        );
      }
      return;
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _showShareOptions(path, isPdf: true);
  }

  Future<void> _shareAsExcel() async {
    if (_rows.isEmpty) return;
    final metadata = await showDialog<AnnualPlanMetadata>(
      context: context,
      builder: (_) => AnnualPlanMetadataDialog(initial: const AnnualPlanMetadata()),
    );
    if (metadata == null || !mounted) return;
    String? path;
    try {
      path = await AnnualPlanExportService.exportToExcel(_rows, metadata: metadata);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel oluşturulamadı: $e')),
        );
      }
      return;
    }
    if (path == null || !File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('exportError'))),
        );
      }
      return;
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _showShareOptions(path, isPdf: false);
  }

  Future<void> _shareYearSummary() async {
    if (_rows.isEmpty) return;
    final metadata = await showDialog<AnnualPlanMetadata>(
      context: context,
      builder: (_) => AnnualPlanMetadataDialog(initial: const AnnualPlanMetadata()),
    );
    if (!mounted) return;
    final path = await AnnualPlanExportService.exportYearSummary(_rows, metadata: metadata);
    if (path == null || !File(path).existsSync()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('exportError'))));
      return;
    }
    if (!mounted) return;
    await _showShareOptions(path, isPdf: true);
  }

  Future<void> _showShareOptions(String path, {required bool isPdf}) async {
    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('annualPlan')),
        content: Text(context.tr('fileReadyShare')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'open'),
            child: Text(context.tr('openFile')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'share'),
            child: Text(context.tr('shareAnnualPlan')),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    if (result == 'share') {
      if (isPdf) {
        await Share.shareXFiles(
          [XFile(path, name: 'yillik_plan.pdf', mimeType: 'application/pdf')],
        );
      } else {
        await Share.shareXFiles(
          [XFile(path, name: 'yillik_plan.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        );
      }
    } else if (result == 'open') {
      await OpenFile.open(path);
    }
  }

  void _copyToClipboard() {
    final metadata = const AnnualPlanMetadata();
    final text = AnnualPlanExportService.getContentAsText(_rows, metadata: metadata);
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('copiedToClipboard'))),
      );
    }
  }

  Future<void> _deleteRow(AnnualPlanRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('deleteRow')),
        content: Text(context.tr('deleteRowConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('delete'))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().repo.deleteAnnualPlanRow(r.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(context.tr('annualPlan')),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.link),
                tooltip: context.tr('copyLink'),
                onPressed: _rows.isEmpty ? null : _copyToClipboard,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.share),
                tooltip: context.tr('shareAnnualPlan'),
                onSelected: (v) {
                  if (v == 'excel') _shareAsExcel();
                  else if (v == 'pdf') _shareAsPdf();
                  else if (v == 'summary') _shareYearSummary();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'excel', child: Row(children: [Icon(Icons.table_chart, size: 20, color: Colors.green[700]), const SizedBox(width: 8), Text('${context.tr('annualPlan')} (.xlsx)')])),
                  PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf, size: 20, color: Colors.red[700]), const SizedBox(width: 8), Text('${context.tr('annualPlan')} (.pdf)')])),
                  if (FeatureFlags.yearlySummaryExport)
                    PopupMenuItem(value: 'summary', child: Row(children: [const Icon(Icons.summarize, size: 20), const SizedBox(width: 8), Text('${context.tr('annualPlan')} (Özet)')])),
                ],
              ),
              IconButton.filled(
                icon: const Icon(Icons.add),
                onPressed: _addRow,
                tooltip: context.tr('addRow'),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth.isFinite ? constraints.maxWidth : 800,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columnSpacing: 16,
                        columns: [
                          DataColumn(label: Text(context.tr('rowNo'))),
                          DataColumn(label: Text(context.tr('weekNo'))),
                          DataColumn(label: Text(context.tr('lessonNo'))),
                          DataColumn(label: Text(context.tr('date'))),
                          DataColumn(label: Text(context.tr('classLabel'))),
                          DataColumn(label: Text(context.tr('topic'))),
                          DataColumn(label: Text(context.tr('outcome'))),
                          DataColumn(label: Text(context.tr('homeworkLabel'))),
                          const DataColumn(label: Text('')),
                        ],
                        rows: _rows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text('${r.rowNo}')),
                              DataCell(Text('${r.weekNo}')),
                              DataCell(Text('${r.lessonNo}')),
                              DataCell(Text('${r.date.day}/${r.date.month}/${r.date.year}')),
                              DataCell(Text(r.classId)),
                              DataCell(Text(r.topic, maxLines: 2, overflow: TextOverflow.ellipsis)),
                              DataCell(Text(r.outcome, maxLines: 2, overflow: TextOverflow.ellipsis)),
                              DataCell(Text(r.homework, maxLines: 2, overflow: TextOverflow.ellipsis)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editRow(r),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    onPressed: () => _deleteRow(r),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
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
}
