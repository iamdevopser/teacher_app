import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/assessment.dart';
import '../models/teacher_profile.dart';
import '../models/attendance_record.dart';
import '../models/guidance_models.dart';
import '../models/guidance_student.dart';

/// ADDITIVE: Enhanced student report with date range, PDF, teacher comment, auto metadata.
class StudentReportService {
  static Future<String?> exportToPdf({
    required GuidanceStudent student,
    required List<Assessment> assessments,
    required List<AttendanceRecord> attendance,
    required List<GuidanceActivity> activities,
    required List<GuidanceMeeting> meetings,
    required TeacherProfile? profile,
    String? teacherComment,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    assessments = _filterByDateRange(assessments, dateFrom, dateTo, (a) => a.date);
    activities = _filterByDateRange(activities, dateFrom, dateTo, (a) => a.date);
    meetings = _filterByDateRange(meetings, dateFrom, dateTo, (m) => m.date);

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÖĞRENCİ DURUM RAPORU', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            if (profile != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('${profile.schoolName} • ${profile.teacherName}', style: const pw.TextStyle(fontSize: 10)),
            ],
            if (dateFrom != null || dateTo != null)
              pw.Text(
                '${dateFrom != null ? '${dateFrom.day}/${dateFrom.month}/${dateFrom.year}' : '...'} - ${dateTo != null ? '${dateTo.day}/${dateTo.month}/${dateTo.year}' : '...'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.SizedBox(height: 12),
            pw.Text('Öğrenci: ${student.fullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Sınıf: ${student.classId} • No: ${student.studentNumber}'),
            pw.SizedBox(height: 8),
            pw.Text('Performans', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (assessments.isEmpty)
            pw.Text('Kayıt yok.')
          else
            ...assessments.take(15).map((a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('• ${a.title} (${a.subject}): ${a.score} - ${a.date.day}/${a.date.month}/${a.date.year}'),
                )),
          pw.SizedBox(height: 8),
          pw.Text('Devamsızlık', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('Yok: ${attendance.where((r) => r.status == AttendanceStatus.absent).length} | Geç: ${attendance.where((r) => r.status == AttendanceStatus.late).length}'),
          pw.SizedBox(height: 8),
          pw.Text('Aktiviteler', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (activities.isEmpty)
            pw.Text('Kayıt yok.')
          else
            ...activities.take(10).map((a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('• ${a.activityName} - ${a.date.day}/${a.date.month}/${a.date.year}'),
                )),
          pw.SizedBox(height: 8),
          pw.Text('Görüşmeler', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (meetings.isEmpty)
            pw.Text('Kayıt yok.')
          else
            ...meetings.take(10).map((m) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('• ${m.date.day}/${m.date.month}/${m.date.year} - ${m.participantCount} kişi'),
                )),
          if (teacherComment != null && teacherComment.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Öğretmen Yorumu', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(teacherComment),
          ],
          ],
        ),
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/student_reports');
      if (!await reportsDir.exists()) await reportsDir.create(recursive: true);
      final safeName = '${student.fullName.replaceAll(RegExp(r'[^\w\s-]'), '_')}_${student.id.substring(0, 8)}.pdf';
      final file = File('${reportsDir.path}/$safeName');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static List<T> _filterByDateRange<T>(List<T> items, DateTime? from, DateTime? to, DateTime Function(T) getDate) {
    if (from == null && to == null) return items;
    return items.where((e) {
      final d = getDate(e);
      if (from != null && d.isBefore(DateTime(from.year, from.month, from.day))) return false;
      if (to != null && d.isAfter(DateTime(to.year, to.month, to.day).add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }
}
