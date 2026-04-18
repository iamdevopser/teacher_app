import 'not_defterim_models.dart';

class NotDefterimCalculator {
  NotDefterimCalculator._();

  static DateTime dateTimeFromDateStr(String dateStr) {
    // YYYY-MM-DD
    final parts = dateStr.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime(y, m, d);
  }

  /// Okul yili baslangic yili: Eylul'da baslayan yila aittir.
  /// Ornek: 2024-11-10 -> okul yil baslangici 2024
  /// 2025-01-05 -> okul yil baslangici 2024
  static int schoolYearStartYearForDate(DateTime date) {
    return date.month >= 9 ? date.year : date.year - 1;
  }

  static ({DateTime start, DateTime end, String key, String label}) periodForDate(
    DateTime date,
  ) {
    final startYear = schoolYearStartYearForDate(date);
    final m = date.month;

    // Sep-Oct
    if (m == 9 || m == 10) {
      return (
        start: DateTime(startYear, 9, 1),
        end: DateTime(startYear, 10, 31),
        key: '${startYear}_sep_oct',
        label: 'Eylul-Ekim',
      );
    }
    // Nov-Dec
    if (m == 11 || m == 12) {
      return (
        start: DateTime(startYear, 11, 1),
        end: DateTime(startYear, 12, 31),
        key: '${startYear}_nov_dec',
        label: 'Kasım-Aralık',
      );
    }
    final y2 = startYear + 1;
    // Jan-Feb (okul yılının takvimdeki ikinci yılı)
    if (m == 1 || m == 2) {
      return (
        start: DateTime(y2, 1, 1),
        end: DateTime(y2, 2, _daysInMonth(y2, 2)),
        key: '${startYear}_jan_feb',
        label: 'Ocak-Şubat',
      );
    }
    // Mar-Apr
    if (m == 3 || m == 4) {
      return (
        start: DateTime(y2, 3, 1),
        end: DateTime(y2, 4, 30),
        key: '${startYear}_mar_apr',
        label: 'Mart-Nisan',
      );
    }
    // May
    return (
      start: DateTime(y2, 5, 1),
      end: DateTime(y2, 5, 31),
      key: '${startYear}_may',
      label: 'Mayıs',
    );
  }

  static List<({DateTime start, DateTime end, String key, String label})> periodsForSchoolYearStart(
    int startYear,
  ) {
    final y2 = startYear + 1;
    return [
      (
        start: DateTime(startYear, 9, 1),
        end: DateTime(startYear, 10, 31),
        key: '${startYear}_sep_oct',
        label: 'Eylul-Ekim',
      ),
      (
        start: DateTime(startYear, 11, 1),
        end: DateTime(startYear, 12, 31),
        key: '${startYear}_nov_dec',
        label: 'Kasım-Aralık',
      ),
      (
        start: DateTime(y2, 1, 1),
        end: DateTime(y2, 2, _daysInMonth(y2, 2)),
        key: '${startYear}_jan_feb',
        label: 'Ocak-Şubat',
      ),
      (
        start: DateTime(y2, 3, 1),
        end: DateTime(y2, 4, 30),
        key: '${startYear}_mar_apr',
        label: 'Mart-Nisan',
      ),
      (
        start: DateTime(y2, 5, 1),
        end: DateTime(y2, 5, 31),
        key: '${startYear}_may',
        label: 'Mayıs',
      ),
    ];
  }

  static int _daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

  static double _mean(List<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  /// Hesap:
  /// - Ortalama puan (daily kind): gunluk toplamlarin ortalamasi
  /// - Ödev puanı (homework kind): gunluk odev toplamlarinin ortalamasi
  /// - Sınav puanı (exam kind): gunluk exam toplamlarinin ortalamasi
  /// - Final:
  ///   - Eger "affectsFinal" isaretli puan türleri varsa: her türün 1..10 ortalaması alinir ve final bu ortalamalarin ortalamasidir.
  ///   - Aksi halde legacy: (0.5*daily + 0.25*homework + 0.25*exam) / 100 * 10
  /// Degerler 0..100 varsayilir (legacy icin). affectsFinal türleri icin Degerler 1..10 varsayilir.
  static int computeFinalGrade1to10({
    required double dailyAverage,
    required double homeworkAverage,
    required double examAverage,
  }) {
    final raw = (dailyAverage * 0.5 + homeworkAverage * 0.25 + examAverage * 0.25);
    final grade = (raw / 100.0) * 10.0;
    final clamped = grade.clamp(0.0, 10.0);
    return clamped.round();
  }

  static List<NotDefterimPeriodSummary> computePeriodSummariesForClass({
    required List<NotDefterimClass> classes,
    required List<NotDefterimStudent> students,
    required List<NotDefterimPointType> pointTypes,
    required List<NotDefterimDailyEntry> dailyEntries,
    required NotDefterimClass classItem,
    required int schoolYearStart,
  }) {
    final periodDefs = periodsForSchoolYearStart(schoolYearStart);
    final dailyIds = pointTypes
        .where((p) => p.kind == NotDefterimPointKind.daily && !p.affectsFinal)
        .map((e) => e.id)
        .toSet();
    final homeworkIds = pointTypes
        .where((p) => p.kind == NotDefterimPointKind.homework && !p.affectsFinal)
        .map((e) => e.id)
        .toSet();
    final examIds = pointTypes
        .where((p) => p.kind == NotDefterimPointKind.exam && !p.affectsFinal)
        .map((e) => e.id)
        .toSet();

    final affectingTypeIds =
        pointTypes.where((p) => p.affectsFinal).map((e) => e.id).toSet();

    final nonHomeworkExamTypes = pointTypes
        .where(
          (p) =>
              p.kind != NotDefterimPointKind.homework &&
              p.kind != NotDefterimPointKind.exam,
        )
        .toList();

    final classStudents = students.where((s) => s.classId == classItem.id).toList();

    final classEntries = dailyEntries.where((e) => e.classId == classItem.id).toList();

    final result = <NotDefterimPeriodSummary>[];

    for (final period in periodDefs) {
      for (final student in classStudents) {
        final relevantDays = classEntries.where((e) {
          final dt = dateTimeFromDateStr(e.dateStr);
          return dt.isAfter(period.start.subtract(const Duration(days: 1))) &&
              dt.isBefore(period.end.add(const Duration(days: 1))) &&
              e.studentId == student.id;
        }).toList();

        final dailyTotals = <double>[];
        final homeworkTotals = <double>[];
        final examTotals = <double>[];

        for (final day in relevantDays) {
          double sumDaily = 0;
          for (final id in dailyIds) {
            sumDaily += day.values[id] ?? 0;
          }
          double sumHomework = 0;
          for (final id in homeworkIds) {
            sumHomework += day.values[id] ?? 0;
          }
          double sumExam = 0;
          for (final id in examIds) {
            sumExam += day.values[id] ?? 0;
          }
          dailyTotals.add(sumDaily);
          homeworkTotals.add(sumHomework);
          examTotals.add(sumExam);
        }

        final dailyAvg = _mean(dailyTotals);
        final homeworkAvg = _mean(homeworkTotals);
        final examAvg = _mean(examTotals);

        final finalGrade = affectingTypeIds.isNotEmpty
            ? _computeAffectingFinalGrade(
                affectingTypeIds: affectingTypeIds,
                relevantDays: relevantDays,
              )
            : computeFinalGrade1to10(
                dailyAverage: dailyAvg,
                homeworkAverage: homeworkAvg,
                examAverage: examAvg,
              );

        final periodSumByPointTypeId = <String, double>{
          for (final t in nonHomeworkExamTypes) t.id: 0.0,
        };
        for (final day in relevantDays) {
          for (final t in nonHomeworkExamTypes) {
            periodSumByPointTypeId[t.id] =
                periodSumByPointTypeId[t.id]! + (day.values[t.id] ?? 0);
          }
        }

        result.add(
          NotDefterimPeriodSummary(
            classItem: classItem,
            student: student,
            periodKey: period.key,
            dailyAverage: dailyAvg,
            homeworkAverage: homeworkAvg,
            examAverage: examAvg,
            finalGrade1to10: finalGrade,
            periodSumByPointTypeId: periodSumByPointTypeId,
          ),
        );
      }
    }

    return result;
  }

  static int _computeAffectingFinalGrade({
    required Set<String> affectingTypeIds,
    required List<NotDefterimDailyEntry> relevantDays,
  }) {
    if (affectingTypeIds.isEmpty) return 0;

    final typeAverages = <double>[];
    for (final typeId in affectingTypeIds) {
      final values = <double>[];
      for (final day in relevantDays) {
        final v = day.values[typeId];
        if (v == null) continue;
        // UI bos birakildiginda 0 saklanir; finale dahil etmeyelim.
        if (v <= 0) continue;
        values.add(v);
      }
      // hic veri yoksa o ture dahil etme.
      if (values.isEmpty) continue;
      typeAverages.add(_mean(values));
    }

    if (typeAverages.isEmpty) return 0;

    final avg = _mean(typeAverages);
    return avg.clamp(0.0, 10.0).round();
  }
}

