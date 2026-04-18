import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/project_model.dart';

/// Projeyi PDF olarak dışa aktarır
class ProjectPdfService {
  static String getContentAsText(ProjectModel p, String typeLabel, String statusLabel) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln('                    PROJE');
    buffer.writeln('═══════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln(p.name);
    buffer.writeln('$typeLabel | $statusLabel');
    buffer.writeln('${p.startDate.day}/${p.startDate.month}/${p.startDate.year} - ${p.endDate.day}/${p.endDate.month}/${p.endDate.year}');
    if (p.subject.isNotEmpty) buffer.writeln('Ders/Alan: ${p.subject}');
    if (p.classLevel.isNotEmpty) buffer.writeln('Sınıf: ${p.classLevel}');
    buffer.writeln();
    if (p.purpose.isNotEmpty) { buffer.writeln('Amaç ve Hedefler:'); buffer.writeln(p.purpose); buffer.writeln(); }
    if (p.outcomes.isNotEmpty) { buffer.writeln('Kazanımlar:'); buffer.writeln(p.outcomes); buffer.writeln(); }
    if (p.skills.isNotEmpty) { buffer.writeln('Beceriler:'); buffer.writeln(p.skills); buffer.writeln(); }
    if (p.shortDescription.isNotEmpty) { buffer.writeln('Kısa Tanım:'); buffer.writeln(p.shortDescription); buffer.writeln(); }
    if (p.scope.isNotEmpty) { buffer.writeln('Kapsam:'); buffer.writeln(p.scope); buffer.writeln(); }
    if (p.teacherNotes.isNotEmpty) { buffer.writeln('Öğretmen Notları:'); buffer.writeln(p.teacherNotes); buffer.writeln(); }
    if (p.steps.isNotEmpty) {
      buffer.writeln('Proje Adımları:');
      for (var i = 0; i < p.steps.length; i++) {
        final s = p.steps[i];
        buffer.writeln('${i + 1}. ${s.title}${s.description.isNotEmpty ? ': ${s.description}' : ''}');
      }
      buffer.writeln();
    }
    if (p.materials.isNotEmpty) { buffer.writeln('Materyaller:'); buffer.writeln(p.materials); buffer.writeln(); }
    if (p.contentCriteria.isNotEmpty || p.participationCriteria.isNotEmpty) {
      buffer.writeln('Değerlendirme Kriterleri:');
      if (p.contentCriteria.isNotEmpty) buffer.writeln('İçerik: ${p.contentCriteria}');
      if (p.participationCriteria.isNotEmpty) buffer.writeln('Katılım: ${p.participationCriteria}');
      if (p.presentationCriteria.isNotEmpty) buffer.writeln('Sunum: ${p.presentationCriteria}');
      if (p.timeManagementCriteria.isNotEmpty) buffer.writeln('Zaman: ${p.timeManagementCriteria}');
      buffer.writeln();
    }
    if (p.processNotes.isNotEmpty) { buffer.writeln('Süreç Notları:'); buffer.writeln(p.processNotes); buffer.writeln(); }
    if (p.observations.isNotEmpty) { buffer.writeln('Gözlemler:'); buffer.writeln(p.observations); buffer.writeln(); }
    if (p.developmentNotes.isNotEmpty) { buffer.writeln('Geliştirme Notları:'); buffer.writeln(p.developmentNotes); buffer.writeln(); }
    if (p.participants.isNotEmpty) {
      buffer.writeln('Katılımcılar:');
      for (final pp in p.participants) buffer.writeln('• ${pp.studentName} (${pp.classId})');
    }
    buffer.writeln('═══════════════════════════════════════════════════');
    return buffer.toString();
  }

  static Future<String?> exportToPdf(ProjectModel p, String typeLabel, String statusLabel) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'proje_${p.id}_${p.name.replaceAll(RegExp(r'[^\w\s-]'), '')}.pdf';
      final file = File('${dir.path}/$fileName');

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => [
            pw.Text(p.name, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('$typeLabel | $statusLabel'),
            pw.Text('${p.startDate.day}/${p.startDate.month}/${p.startDate.year} - ${p.endDate.day}/${p.endDate.month}/${p.endDate.year}'),
            if (p.subject.isNotEmpty) pw.Text('Ders/Alan: ${p.subject}'),
            if (p.classLevel.isNotEmpty) pw.Text('Sınıf: ${p.classLevel}'),
            pw.SizedBox(height: 16),
            if (p.purpose.isNotEmpty) _section('Amaç ve Hedefler', p.purpose),
            if (p.outcomes.isNotEmpty) _section('Kazanımlar', p.outcomes),
            if (p.skills.isNotEmpty) _section('Beceriler', p.skills),
            if (p.shortDescription.isNotEmpty) _section('Kısa Tanım', p.shortDescription),
            if (p.scope.isNotEmpty) _section('Kapsam', p.scope),
            if (p.teacherNotes.isNotEmpty) _section('Öğretmen Notları', p.teacherNotes),
            if (p.steps.isNotEmpty) ...[
              pw.Text('Proje Adımları', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...p.steps.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('${e.key + 1}. ${e.value.title}${e.value.description.isNotEmpty ? ': ${e.value.description}' : ''}'),
              )),
              pw.SizedBox(height: 12),
            ],
            if (p.materials.isNotEmpty) _section('Materyaller', p.materials),
            if (p.contentCriteria.isNotEmpty || p.participationCriteria.isNotEmpty) ...[
              pw.Text('Değerlendirme Kriterleri', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              if (p.contentCriteria.isNotEmpty) pw.Text('İçerik: ${p.contentCriteria}'),
              if (p.participationCriteria.isNotEmpty) pw.Text('Katılım: ${p.participationCriteria}'),
              if (p.presentationCriteria.isNotEmpty) pw.Text('Sunum: ${p.presentationCriteria}'),
              if (p.timeManagementCriteria.isNotEmpty) pw.Text('Zaman: ${p.timeManagementCriteria}'),
              pw.SizedBox(height: 12),
            ],
            if (p.processNotes.isNotEmpty) _section('Süreç Notları', p.processNotes),
            if (p.observations.isNotEmpty) _section('Gözlemler', p.observations),
            if (p.developmentNotes.isNotEmpty) _section('Geliştirme Notları', p.developmentNotes),
            if (p.participants.isNotEmpty) ...[
              pw.Text('Katılımcılar', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              ...p.participants.map((pp) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text('• ${pp.studentName} (${pp.classId})'),
              )),
            ],
          ],
        ),
      );
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      return null;
    }
  }

  static pw.Widget _section(String title, String content) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(content),
        ],
      ),
    );
  }
}
