import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/lesson_planner_models.dart';

/// Günlük planı PDF olarak oluşturur ve dosya yolunu döndürür.
class DailyPlanFileService {
  static Future<String?> generatePlanFile(DailyLessonPlan plan) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final plansDir = Directory('${dir.path}/daily_plans');
      if (!await plansDir.exists()) {
        await plansDir.create(recursive: true);
      }
      final fileName = 'gunluk_plan_${plan.id}_${plan.date.year}${plan.date.month.toString().padLeft(2, '0')}${plan.date.day.toString().padLeft(2, '0')}.pdf';
      final file = File('${plansDir.path}/$fileName');

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('GÜNLÜK DERS PLANI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Tarih: ${plan.date.day}/${plan.date.month}/${plan.date.year}'),
              pw.Text('Ders: ${plan.subjectName}'),
              pw.Text('Sınıf: ${plan.classId}'),
              pw.Text('Öğretmen: ${plan.teacherName}'),
              if (plan.weekNo > 0) pw.Text('Hafta No: ${plan.weekNo}'),
              if (plan.lessonNo > 0) pw.Text('Ders No: ${plan.lessonNo}'),
              pw.Text('Ders Saati: ${plan.lessonHour}'),
              pw.SizedBox(height: 12),
              pw.Divider(),
              _section('KONU', plan.topic),
              _section('KAZANIM', plan.outcome),
              _section('GİRİŞ (10 dk)', plan.intro),
              _section('GELİŞME (25 dk)', plan.development),
              _section('SONUÇ (10 dk)', plan.evaluation),
              _section('YÖNTEM', plan.method),
              _section('MATERYAL', plan.material),
              _section('NOTLAR', plan.lessonNote),
              pw.SizedBox(height: 8),
              pw.Text('Durum: ${plan.completed ? "Tamamlandı" : "Beklemede"}'),
              if (plan.needsMakeup) pw.Text('Telafi gerektirir'),
            ],
          ),
        ),
      );
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static pw.Widget _section(String title, String content) {
    if (content.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(content),
        ],
      ),
    );
  }

  /// Plan içeriğini plain text olarak döndürür (görüntüleme için)
  static String getPlanContentAsText(DailyLessonPlan plan) {
    return _buildPlanContent(plan);
  }

  static String _buildPlanContent(DailyLessonPlan plan) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('                    GÜNLÜK DERS PLANI');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Tarih: ${plan.date.day}/${plan.date.month}/${plan.date.year}');
    buffer.writeln('Ders: ${plan.subjectName}');
    buffer.writeln('Sınıf: ${plan.classId}');
    buffer.writeln('Öğretmen: ${plan.teacherName}');
    if (plan.weekNo > 0) buffer.writeln('Hafta No: ${plan.weekNo}');
    if (plan.lessonNo > 0) buffer.writeln('Ders No: ${plan.lessonNo}');
    buffer.writeln('Ders Saati: ${plan.lessonHour}');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────');
    buffer.writeln('KONU:');
    buffer.writeln(plan.topic);
    buffer.writeln();
    buffer.writeln('KAZANIM:');
    buffer.writeln(plan.outcome);
    buffer.writeln();
    buffer.writeln('GİRİŞ (10 dk):');
    buffer.writeln(plan.intro);
    buffer.writeln();
    buffer.writeln('GELİŞME (25 dk):');
    buffer.writeln(plan.development);
    buffer.writeln();
    buffer.writeln('SONUÇ (10 dk):');
    buffer.writeln(plan.evaluation);
    buffer.writeln();
    buffer.writeln('YÖNTEM:');
    buffer.writeln(plan.method);
    buffer.writeln();
    buffer.writeln('MATERYAL:');
    buffer.writeln(plan.material);
    buffer.writeln();
    buffer.writeln('NOTLAR:');
    buffer.writeln(plan.lessonNote);
    buffer.writeln();
    buffer.writeln('Durum: ${plan.completed ? "Tamamlandı" : "Beklemede"}');
    if (plan.needsMakeup) buffer.writeln('Telafi gerektirir');
    buffer.writeln('═══════════════════════════════════════════════════');
    return buffer.toString();
  }
}
