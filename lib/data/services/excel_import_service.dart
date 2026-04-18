import 'package:excel/excel.dart';
import '../models/guidance_student.dart';
import '../repositories/app_repository.dart';

String _cellToString(dynamic cell) {
  if (cell == null) return '';
  if (cell is CellValue) {
    return switch (cell) {
      TextCellValue(:final value) => value.toString(),
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value.toString(),
      DateCellValue() => cell.toString(),
      DateTimeCellValue() => cell.toString(),
      TimeCellValue() => cell.toString(),
      FormulaCellValue(:final formula) => formula,
    };
  }
  return cell.toString();
}

/// Excel dosyasından GuidanceStudent listesi oluşturur.
/// İlk satır başlık olmalı (Soyadı, Adı, ...).
List<GuidanceStudent> parseGuidanceStudentsFromExcel(List<int> bytes) {
  final excel = Excel.decodeBytes(bytes);
  final sheet = excel.tables.keys.isNotEmpty
      ? excel.tables[excel.tables.keys.first]!
      : null;
  if (sheet == null || sheet.rows.isEmpty) return [];

  final rows = sheet.rows;
  if (rows.length < 2) return []; // en az başlık + 1 veri satırı

  // Başlık satırından sütun indekslerini bul (0: Soyadı, 1: Adı, ...)
  final headerRow = rows[0];
  final colMap = <String, int>{};
  for (var i = 0; i < headerRow.length; i++) {
    final h = _cellToString(headerRow[i]).trim();
    if (h.isNotEmpty) colMap[h] = i;
  }

  // Alternatif başlık eşlemesi (İngilizce vb.)
  final altMap = {
    'Last Name': 'Soyadı', 'First Name': 'Adı', 'Student No': 'Öğrenci Numarası',
    'Class': 'Sınıf', 'Email': 'E-posta', 'Phone': 'Telefon Numarası',
    'Nationality': 'Uyruk', 'Gender': 'Cinsiyet', 'Address': 'Ev Adresi',
    'Mother Name': 'Anne Adı', 'Mother Phone': 'Anne Telefonu',
    'Mother Email': 'Anne E-postası', 'Father Name': 'Baba Adı',
    'Father Phone': 'Baba Telefonu', 'Father Email': 'Baba E-postası',
  };

  int col(String trKey) {
    if (colMap.containsKey(trKey)) return colMap[trKey]!;
    // Alternatif: İngilizce başlık (altMap: trKey -> en key)
    final altKey = altMap.entries.where((e) => e.value == trKey).map((e) => e.key).firstOrNull;
    if (altKey != null && colMap.containsKey(altKey)) return colMap[altKey]!;
    return -1;
  }

  final result = <GuidanceStudent>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    String getVal(String key) {
      final c = col(key);
      if (c < 0 || c >= row.length) return '';
      return _cellToString(row[c]).trim();
    }

    final lastName = getVal('Soyadı');
    final firstName = getVal('Adı');
    final studentNumber = getVal('Öğrenci Numarası');
    final classId = getVal('Sınıf');

    // Ad ve soyad zorunlu (en az biri dolu olmalı)
    if (lastName.isEmpty && firstName.isEmpty) continue;

    result.add(GuidanceStudent(
      id: AppRepository.generateId(),
      lastName: lastName,
      firstName: firstName,
      studentNumber: studentNumber,
      classId: classId,
      email: getVal('E-posta'),
      phone: getVal('Telefon Numarası'),
      nationality: getVal('Uyruk'),
      gender: getVal('Cinsiyet'),
      address: getVal('Ev Adresi'),
      motherName: getVal('Anne Adı'),
      motherPhone: getVal('Anne Telefonu'),
      motherEmail: getVal('Anne E-postası'),
      fatherName: getVal('Baba Adı'),
      fatherPhone: getVal('Baba Telefonu'),
      fatherEmail: getVal('Baba E-postası'),
      createdAt: DateTime.now(),
    ));
  }
  return result;
}
