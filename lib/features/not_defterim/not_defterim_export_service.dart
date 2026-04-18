import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'not_defterim_calculator.dart';
import 'not_defterim_models.dart';

class NotDefterimExportService {
  NotDefterimExportService._();

  static String _sanitizeForPdf(String text) {
    const Map<String, String> trToAscii = {
      'ğ': 'g',
      'Ğ': 'G',
      'ü': 'u',
      'Ü': 'U',
      'ş': 's',
      'Ş': 'S',
      'ı': 'i',
      'İ': 'I',
      'ö': 'o',
      'Ö': 'O',
      'ç': 'c',
      'Ç': 'C',
    };
    var result = text;
    for (final e in trToAscii.entries) {
      result = result.replaceAll(e.key, e.value);
    }
    return result;
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        _sanitizeForPdf(text),
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static List<NotDefterimPointType> _reportPointTypes(
    List<NotDefterimPointType> pointTypes,
  ) {
    return pointTypes
        .where(
          (p) =>
              p.kind != NotDefterimPointKind.homework &&
              p.kind != NotDefterimPointKind.exam,
        )
        .toList();
  }

  static String _periodTypeSumText(NotDefterimPointType t, double v) {
    if (v == 0) return '-';
    return t.affectsFinal ? v.toStringAsFixed(1) : v.round().toString();
  }

  static Future<String?> exportStudentPdf({
    required NotDefterimStudent student,
    required NotDefterimClass classItem,
    required int schoolYearStart,
    required List<NotDefterimClass> classes,
    required List<NotDefterimStudent> students,
    required List<NotDefterimPointType> pointTypes,
    required List<NotDefterimDailyEntry> dailyEntries,
  }) async {
    try {
      final summaries = NotDefterimCalculator.computePeriodSummariesForClass(
        classes: classes,
        students: students,
        pointTypes: pointTypes,
        dailyEntries: dailyEntries,
        classItem: classItem,
        schoolYearStart: schoolYearStart,
      ).where((s) => s.student.id == student.id).toList();

      final rpt = _reportPointTypes(pointTypes);
      final colCount = 1 + rpt.length + 3;
      final columnWidths = <int, pw.TableColumnWidth>{
        for (var i = 0; i < colCount; i++) i: const pw.FlexColumnWidth(1),
      };

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) => [
            pw.Text(
              _sanitizeForPdf('Ogrenci Not Raporu'),
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              _sanitizeForPdf('${classItem.name} / ${student.name}'),
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(width: 0.4),
              columnWidths: columnWidths,
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _SimpleHeader('Donem'),
                    ...rpt.map((t) => _SimpleHeader(_sanitizeForPdf(t.name))),
                    _SimpleHeader('Odev'),
                    _SimpleHeader('Sinav'),
                    _SimpleHeader('Final (1-10)'),
                  ],
                ),
                ...summaries.map(
                  (s) => pw.TableRow(
                    children: [
                      _cell(s.periodKey),
                      ...rpt.map(
                        (t) => _cell(
                          _periodTypeSumText(
                            t,
                            s.periodSumByPointTypeId[t.id] ?? 0,
                          ),
                        ),
                      ),
                      _cell(s.homeworkAverage.toStringAsFixed(2)),
                      _cell(s.examAverage.toStringAsFixed(2)),
                      _cell('${s.finalGrade1to10}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/not_defterim_${classItem.id}_${student.id}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      debugPrint('NotDefterim exportStudentPdf error: $e\n$st');
      return null;
    }
  }

  static Future<String?> exportClassExcel({
    required NotDefterimClass classItem,
    required int schoolYearStart,
    required List<NotDefterimClass> classes,
    required List<NotDefterimStudent> students,
    required List<NotDefterimPointType> pointTypes,
    required List<NotDefterimDailyEntry> dailyEntries,
  }) async {
    try {
      final summaries = NotDefterimCalculator.computePeriodSummariesForClass(
        classes: classes,
        students: students,
        pointTypes: pointTypes,
        dailyEntries: dailyEntries,
        classItem: classItem,
        schoolYearStart: schoolYearStart,
      );

      final rpt = _reportPointTypes(pointTypes);

      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? excel.tables.keys.first;
      final sheet = excel[sheetName];

      sheet.appendRow(<CellValue?>[
        TextCellValue('Donem'),
        TextCellValue('Ogrenci'),
        ...rpt.map((t) => TextCellValue(t.name)),
        TextCellValue('Odev'),
        TextCellValue('Sinav'),
        TextCellValue('Final (1-10)'),
      ]);

      for (final s in summaries) {
        sheet.appendRow(<CellValue?>[
          TextCellValue(s.periodKey),
          TextCellValue(s.student.name),
          ...rpt.map(
            (t) => DoubleCellValue(s.periodSumByPointTypeId[t.id] ?? 0),
          ),
          DoubleCellValue(s.homeworkAverage),
          DoubleCellValue(s.examAverage),
          IntCellValue(s.finalGrade1to10),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/not_defterim_${classItem.id}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      debugPrint('NotDefterim exportClassExcel error: $e\n$st');
      return null;
    }
  }
}

class _SimpleHeader extends pw.StatelessWidget {
  final String text;
  _SimpleHeader(this.text);

  @override
  pw.Widget build(pw.Context context) {
    return pw.Text(
      NotDefterimExportService._sanitizeForPdf(text),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }
}

