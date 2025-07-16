import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateExpenseReportPdf(
  List<Map<String, dynamic>> expenses,
  String userEmail,
) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final formattedDate = DateFormat.yMMMMEEEEd().add_jm().format(now);

  double totalAmount = 0;
  double totalWithTax = 0;
  double totalTax = 0;

  for (var exp in expenses) {
    final amount =
        double.tryParse('${exp['total_amount'] ?? exp['total'] ?? 0}') ?? 0;
    final withTax = double.tryParse('${exp['totalAmountWithTax'] ?? 0}') ?? 0;

    final gst = double.tryParse('${exp['gst'] ?? 0}') ?? 0;
    final pst = double.tryParse('${exp['pst'] ?? 0}') ?? 0;
    final tip = double.tryParse('${exp['tip'] ?? 0}') ?? 0;

    totalAmount += amount;
    totalWithTax += withTax;
    totalTax += gst + pst + tip;
  }

  const purple = PdfColor.fromInt(0xFF6A0DAD);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          color: purple,
          child: pw.Text(
            'Chronotrack Expense Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Printed on: $formattedDate',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Printed by: $userEmail',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: purple,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total Amount: \$${totalAmount.toStringAsFixed(2)}',
                style: const pw.TextStyle(color: PdfColors.white),
              ),
              pw.Text(
                'Total Tax + Tip: \$${totalTax.toStringAsFixed(2)}',
                style: const pw.TextStyle(color: PdfColors.white),
              ),
              pw.Text(
                'Total with Tax: \$${totalWithTax.toStringAsFixed(2)}',
                style: const pw.TextStyle(color: PdfColors.white),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        ...expenses.map((exp) {
          final amount =
              double.tryParse('${exp['total_amount'] ?? exp['total'] ?? 0}') ??
              0;
          final withTax =
              double.tryParse('${exp['totalAmountWithTax'] ?? 0}') ?? 0;
          final gst = double.tryParse('${exp['gst'] ?? 0}') ?? 0;
          final pst = double.tryParse('${exp['pst'] ?? 0}') ?? 0;
          final tip = double.tryParse('${exp['tip'] ?? 0}') ?? 0;

          final expenseId = exp['expenseId'] ?? 'Unknown ID';

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: purple,
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(8),
                      topRight: pw.Radius.circular(8),
                    ),
                  ),
                  child: pw.Text(
                    '$expenseId - \$${amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Email: ${exp['email'] ?? ''}'),
                      pw.Text('Vendor: ${exp['vendor'] ?? ''}'),
                      pw.Text('Location: ${exp['location'] ?? ''}'),
                      pw.Text('Category: ${exp['category'] ?? ''}'),
                      pw.Text('GST: \$${gst.toStringAsFixed(2)}'),
                      pw.Text('PST: \$${pst.toStringAsFixed(2)}'),
                      pw.Text('Tip: \$${tip.toStringAsFixed(2)}'),
                      pw.Text(
                        'Total with Tax: \$${withTax.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}
