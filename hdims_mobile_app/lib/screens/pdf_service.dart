// import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<dynamic> chartData,
    required List<dynamic> patientData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 10),
          pw.Text("Report Generated on: ${DateTime.now().toString().split('.')[0]}"),
          pw.Divider(),

          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 10), child: pw.Text("1. Aggregate Performance Summary", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
          
          // Table for Aggregate Data
          pw.TableHelper.fromTextArray(
            headers: ['Scheme Name', 'Target Population', 'Beneficiaries Reached', 'Performance %'],
            data: chartData.map((item) {
              double target = (item['totalTarget'] ?? 0).toDouble();
              double reached = (item['totalReached'] ?? 0).toDouble();
              String percent = target > 0 ? "${((reached / target) * 100).toStringAsFixed(1)}%" : "0%";
              return [item['_id'], target.toInt(), reached.toInt(), percent];
            }).toList(),
          ),

          pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 20), child: pw.Text("2. Recent Patient Entries", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),

          // Table for Patient Data
          pw.TableHelper.fromTextArray(
            headers: ['Patient Name', 'Age/Gender', 'Health Scheme', 'Diagnosis'],
            data: patientData.map((p) {
              return [
                p['patientName'],
                "${p['age']} / ${p['gender']}",
                p['healthScheme'],
                p['diagnosis'] ?? 'N/A'
              ];
            }).toList(),
          ),
        ],
      ),
    );

    // This opens the native print/save dialog on Android/iOS
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}