import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/lesson_planner_models.dart';

/// Yıllık planı Excel veya PDF olarak dışa aktarır
class AnnualPlanExportService {
  /// PDF varsayılan fontu Türkçe karakterleri desteklemediği için ASCII'ye çevirir
  static String _sanitizeForPdf(String text) {
    const Map<String, String> trToAscii = {
      'ğ': 'g', 'Ğ': 'G', 'ü': 'u', 'Ü': 'U', 'ş': 's', 'Ş': 'S',
      'ı': 'i', 'İ': 'I', 'ö': 'o', 'Ö': 'O', 'ç': 'c', 'Ç': 'C',
    };
    String result = text;
    for (final e in trToAscii.entries) {
      result = result.replaceAll(e.key, e.value);
    }
    return result;
  }

  static String getContentAsText(
    List<AnnualPlanRow> rows, {
    AnnualPlanMetadata? metadata,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('                    YILLIK PLAN');
    buffer.writeln('═══════════════════════════════════════════════════');
    if (metadata != null) {
      _appendMetadata(buffer, metadata);
      buffer.writeln('───────────────────────────────────────────────────');
    }
    for (final r in rows) {
      buffer.writeln('${r.rowNo} | ${r.weekNo} | ${r.lessonNo} | ${r.date.day}/${r.date.month}/${r.date.year} | ${r.classId}');
      buffer.writeln('  Konu: ${r.topic}');
      buffer.writeln('  Kazanım: ${r.outcome}');
      buffer.writeln('  Ödev: ${r.homework}');
      buffer.writeln('───────────────────────────────────────────────────');
    }
    return buffer.toString();
  }

  static void _appendMetadata(StringBuffer b, AnnualPlanMetadata m) {
    if (m.institutionName.isNotEmpty) b.writeln('Kurum: ${m.institutionName}');
    if (m.academicCalendar.isNotEmpty) b.writeln('Akademik Takvim: ${m.academicCalendar}');
    if (m.courseName.isNotEmpty) b.writeln('Ders: ${m.courseName}');
    if (m.teacherName.isNotEmpty) b.writeln('Öğretmen: ${m.teacherName}');
    if (m.classes.isNotEmpty) b.writeln('Sınıflar: ${m.classes}');
    if (m.annualHours.isNotEmpty) b.writeln('Yıllık Ders Saati: ${m.annualHours}');
    if (m.weeklyHours.isNotEmpty) b.writeln('Haftalık Ders Saati: ${m.weeklyHours}');
    if (m.totalWeeks.isNotEmpty) b.writeln('Toplam Hafta: ${m.totalWeeks}');
    if (m.examCount.isNotEmpty) b.writeln('Sınav Sayısı: ${m.examCount}');
    if (m.books.isNotEmpty) b.writeln('Kitaplar: ${m.books}');
    if (m.courseTeacherNameSignature.isNotEmpty) b.writeln('Ders Öğretmeni (ismi ve imzası): ${m.courseTeacherNameSignature}');
    if (m.departmentHeadNameSignature.isNotEmpty) b.writeln('Zümre Başkanı (isim ve imzası): ${m.departmentHeadNameSignature}');
  }

  static Future<String?> exportToExcel(
    List<AnnualPlanRow> rows, {
    AnnualPlanMetadata? metadata,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = excel.getDefaultSheet() ?? excel.tables.keys.first;
      final sheet = excel[sheetName];

      if (metadata != null) {
        _appendMetadataToExcel(sheet, metadata);
      }

      // Başlık satırı
      sheet.appendRow(<CellValue?>[
        TextCellValue('Satır No'),
        TextCellValue('Hafta No'),
        TextCellValue('Ders No'),
        TextCellValue('Tarih'),
        TextCellValue('Sınıf'),
        TextCellValue('Konu'),
        TextCellValue('Kazanım'),
        TextCellValue('Ödev'),
      ]);

      for (final r in rows) {
        sheet.appendRow(<CellValue?>[
          IntCellValue(r.rowNo),
          IntCellValue(r.weekNo),
          IntCellValue(r.lessonNo),
          TextCellValue('${r.date.day}/${r.date.month}/${r.date.year}'),
          TextCellValue(r.classId),
          TextCellValue(r.topic),
          TextCellValue(r.outcome),
          TextCellValue(r.homework),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Excel encode failed');

      Directory dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/yillik_plan_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      debugPrint('Excel export error: $e\n$st');
      rethrow;
    }
  }

  static void _appendMetadataToExcel(dynamic sheet, AnnualPlanMetadata m) {
    if (m.institutionName.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Kurum'), TextCellValue(m.institutionName)]);
    if (m.academicCalendar.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Akademik Takvim'), TextCellValue(m.academicCalendar)]);
    if (m.courseName.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Ders'), TextCellValue(m.courseName)]);
    if (m.teacherName.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Öğretmen'), TextCellValue(m.teacherName)]);
    if (m.classes.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Sınıflar'), TextCellValue(m.classes)]);
    if (m.annualHours.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Yıllık Ders Saati'), TextCellValue(m.annualHours)]);
    if (m.weeklyHours.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Haftalık Ders Saati'), TextCellValue(m.weeklyHours)]);
    if (m.totalWeeks.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Toplam Hafta'), TextCellValue(m.totalWeeks)]);
    if (m.examCount.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Sınav Sayısı'), TextCellValue(m.examCount)]);
    if (m.books.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Kitaplar'), TextCellValue(m.books)]);
    if (m.courseTeacherNameSignature.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Ders Öğretmeni (ismi ve imzası)'), TextCellValue(m.courseTeacherNameSignature)]);
    if (m.departmentHeadNameSignature.isNotEmpty) sheet.appendRow(<CellValue?>[TextCellValue('Zümre Başkanı (isim ve imzası)'), TextCellValue(m.departmentHeadNameSignature)]);
    sheet.appendRow(<CellValue?>[]);
  }

  static Future<String?> exportToPdf(
    List<AnnualPlanRow> rows, {
    AnnualPlanMetadata? metadata,
  }) async {
    try {
      final pdf = pw.Document();
      final meta = metadata;
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) => [
            pw.Text('YILLIK PLAN', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (meta != null) ...[
              pw.SizedBox(height: 8),
              _metadataPdf(meta),
            ],
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(3),
                6: const pw.FlexColumnWidth(3),
                7: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Satır No'),
                    _cell('Hafta'),
                    _cell('Ders'),
                    _cell('Tarih'),
                    _cell('Sınıf'),
                    _cell('Konu'),
                    _cell('Kazanım'),
                    _cell('Ödev'),
                  ],
                ),
                ...rows.map((r) => pw.TableRow(
                  children: [
                    _cell('${r.rowNo}'),
                    _cell('${r.weekNo}'),
                    _cell('${r.lessonNo}'),
                    _cell('${r.date.day}/${r.date.month}/${r.date.year}'),
                    _cell(r.classId),
                    _cell(r.topic),
                    _cell(r.outcome),
                    _cell(r.homework),
                  ],
                )),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      Directory dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/yillik_plan_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      debugPrint('PDF export error: $e\n$st');
      rethrow;
    }
  }

  static pw.Widget _metadataPdf(AnnualPlanMetadata m) {
    final items = <pw.Widget>[];
    if (m.institutionName.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Kurum: ${m.institutionName}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.academicCalendar.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Akademik Takvim: ${m.academicCalendar}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.courseName.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Ders: ${m.courseName}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.teacherName.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Öğretmen: ${m.teacherName}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.classes.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Sınıflar: ${m.classes}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.annualHours.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Yıllık Ders Saati: ${m.annualHours}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.weeklyHours.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Haftalık Ders Saati: ${m.weeklyHours}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.totalWeeks.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Toplam Hafta: ${m.totalWeeks}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.examCount.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Sınav Sayısı: ${m.examCount}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.books.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Kitaplar: ${m.books}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.courseTeacherNameSignature.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Ders Öğretmeni (ismi ve imzası): ${m.courseTeacherNameSignature}'), style: const pw.TextStyle(fontSize: 8)));
    if (m.departmentHeadNameSignature.isNotEmpty) items.add(pw.Text(_sanitizeForPdf('Zümre Başkanı (isim ve imzası): ${m.departmentHeadNameSignature}'), style: const pw.TextStyle(fontSize: 8)));
    if (items.isEmpty) return pw.SizedBox.shrink();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: items);
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(_sanitizeForPdf(text), style: const pw.TextStyle(fontSize: 8)),
    );
  }

  /// ADDITIVE: Year-end summary export (single page).
  static Future<String?> exportYearSummary(
    List<AnnualPlanRow> rows, {
    AnnualPlanMetadata? metadata,
  }) async {
    if (rows.isEmpty) return null;
    try {
      final pdf = pw.Document();
      final first = rows.first.date;
      final last = rows.last.date;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('YILLIK PLAN OZETI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              if (metadata != null) _metadataPdf(metadata),
              pw.SizedBox(height: 16),
              pw.Text('Toplam kayit: ${rows.length}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Tarih araligi: ${first.day}/${first.month}/${first.year} - ${last.day}/${last.month}/${last.year}', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 12),
              pw.Text('Konular:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...rows.take(50).map((r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('${r.weekNo}. hafta | ${r.topic}', style: const pw.TextStyle(fontSize: 9)),
              )),
              if (rows.length > 50) pw.Text('... ve ${rows.length - 50} kayit daha', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      );
      final bytes = await pdf.save();
      Directory dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/yillik_plan_ozet_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e, st) {
      debugPrint('Year summary export error: $e\n$st');
      return null;
    }
  }
}
