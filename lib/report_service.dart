import 'dart:io';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'group_model.dart';

class ReportService {
  static Future<void> generateMonthlyReport(
    Group group,
    String monthYear,
    List<Map<String, dynamic>> data,
  ) async {
    final pdf = pw.Document();

    // Ma'lumotlarni o'quvchilar bo'yicha guruhlash
    final Map<String, Map<String, bool>> studentData = {};
    final Set<String> allDates = {};

    for (var row in data) {
      final name = row['name'] as String;
      final date = row['date'] as String;
      final isPresent = row['is_present'] == 1;

      allDates.add(date);
      studentData.putIfAbsent(name, () => {});
      studentData[name]![date] = isPresent;
    }

    final sortedDates = allDates.toList()..sort();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              '${group.name} - Davomat Hisoboti ($monthYear)',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: [
              'O\'quvchi',
              ...sortedDates.map((d) => d.split('-').last),
            ],
            data: studentData.entries.map((entry) {
              return [
                entry.key,
                ...sortedDates.map((date) {
                  final status = entry.value[date];
                  if (status == null) return '';
                  return status ? '+' : '-';
                }),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 25,
            columnWidths: {0: const pw.FixedColumnWidth(100)},
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Izoh: (+) Keldi, (-) Kelmadi',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${group.name}_$monthYear.pdf',
    );
  }

  static Future<String> generateMonthlyExcelReport(
    Group group,
    String monthYear,
    List<Map<String, dynamic>> data,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    final Map<String, Map<String, bool>> studentData = {};
    final Set<String> allDates = {};

    for (var row in data) {
      final name = row['name'] as String;
      final date = row['date'] as String;
      final isPresent = row['is_present'] == 1;

      allDates.add(date);
      studentData.putIfAbsent(name, () => {});
      studentData[name]![date] = isPresent;
    }

    final sortedDates = allDates.toList()..sort();

    // Sarlavha qatorini (Header) qo'shish
    sheetObject.appendRow([
      TextCellValue('O\'quvchi'),
      ...sortedDates.map((d) => TextCellValue(d.split('-').last)),
      TextCellValue('Qolgan darslar'),
    ]);

    // Ma'lumotlarni qatorlar bo'yicha to'ldirish
    studentData.forEach((name, attendance) {
      final row = <CellValue?>[
        TextCellValue(name),
      ];
      var absentCount = 0;
      for (var date in sortedDates) {
        final status = attendance[date];
        if (status == false) {
          absentCount++;
        }
        row.add(TextCellValue(status == null ? '' : (status ? '+' : '-')));
      }
      row.add(TextCellValue(absentCount.toString()));
      sheetObject.appendRow(row);
    });

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${group.name}_$monthYear.xlsx";
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);
    return filePath;
  }
}
