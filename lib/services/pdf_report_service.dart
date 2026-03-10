import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/inspection_model.dart';

class PdfReportService {
  static Future<pw.Document> generateInspectionReport(
      Inspection inspection) async {
    final pdf = pw.Document();
    final isPassed = inspection.status == InspectionStatus.passed;
    final dateStr =
        DateFormat('dd MMM yyyy, HH:mm').format(inspection.date);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(inspection, dateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Status banner
          _buildStatusBanner(isPassed),
          pw.SizedBox(height: 20),

          // Details section
          _buildDetailsSection(inspection, dateStr),
          pw.SizedBox(height: 20),

          // Checklist table
          _buildChecklistTable(inspection),
          pw.SizedBox(height: 20),

          // Notes
          if (inspection.generalNotes != null &&
              inspection.generalNotes!.isNotEmpty)
            _buildNotesSection(inspection.generalNotes!),

          // Failed items detail
          ..._buildFailedItemsDetail(inspection),

          pw.SizedBox(height: 20),

          // Summary
          _buildSummary(inspection),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Inspection inspection, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Fleet Checker',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800)),
              pw.Text('Vehicle Inspection Report',
                  style: const pw.TextStyle(
                      fontSize: 12, color: PdfColors.grey700)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(inspection.vanRegistration,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(dateStr,
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Fleet Checker - Vehicle Inspection Report',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style:
                  const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBanner(bool isPassed) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: isPassed
            ? const PdfColor.fromInt(0xFFE8F5E9)
            : const PdfColor.fromInt(0xFFFFEBEE),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: isPassed ? PdfColors.green : PdfColors.red,
          width: 1.5,
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          isPassed ? 'INSPECTION PASSED' : 'INSPECTION FAILED',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: isPassed ? PdfColors.green800 : PdfColors.red800,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildDetailsSection(
      Inspection inspection, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F5F5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _detailRow('Vehicle Registration', inspection.vanRegistration),
          _detailRow('Driver', inspection.driverName),
          _detailRow('Date & Time', dateStr),
          _detailRow('Mileage', '${inspection.mileage} miles'),
          _detailRow('Items Checked', '${inspection.checklist.length}'),
          _detailRow('Passed', '${inspection.passCount}'),
          _detailRow('Failed', '${inspection.failCount}'),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildChecklistTable(Inspection inspection) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Checklist Results',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE3F2FD)),
              children: [
                _tableCell('#', isHeader: true),
                _tableCell('Item', isHeader: true),
                _tableCell('Result', isHeader: true),
              ],
            ),
            // Data rows
            ...inspection.checklist.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final bgColor = item.status == CheckStatus.fail
                  ? const PdfColor.fromInt(0xFFFFEBEE)
                  : null;
              return pw.TableRow(
                decoration:
                    bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
                children: [
                  _tableCell('${idx + 1}'),
                  _tableCell(item.name),
                  _statusCell(item.status),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: isHeader ? 11 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : null,
          )),
    );
  }

  static pw.Widget _statusCell(CheckStatus status) {
    final color = status == CheckStatus.pass
        ? PdfColors.green700
        : status == CheckStatus.fail
            ? PdfColors.red700
            : PdfColors.grey600;
    final text = status.name.toUpperCase();

    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: color,
          )),
    );
  }

  static pw.Widget _buildNotesSection(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('General Notes',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFFF8E1),
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.amber200),
          ),
          child: pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static List<pw.Widget> _buildFailedItemsDetail(Inspection inspection) {
    final failedItems =
        inspection.checklist.where((c) => c.status == CheckStatus.fail);
    if (failedItems.isEmpty) return [];

    return [
      pw.SizedBox(height: 10),
      pw.Text('Failed Items Detail',
          style: pw.TextStyle(
              fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...failedItems.map((item) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFEBEE),
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.red200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(item.name,
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800)),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Notes: ${item.notes}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ],
            ),
          )),
    ];
  }

  static pw.Widget _buildSummary(Inspection inspection) {
    final total = inspection.checklist.length;
    final passed = inspection.passCount;
    final failed = inspection.failCount;
    final na =
        inspection.checklist.where((c) => c.status == CheckStatus.na).length;
    final passRate =
        total > 0 ? ((passed / (total - na)) * 100).round() : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        children: [
          pw.Text('Inspection Summary',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryBox('Passed', '$passed', PdfColors.green700),
              _summaryBox('Failed', '$failed', PdfColors.red700),
              _summaryBox('N/A', '$na', PdfColors.grey600),
              _summaryBox('Pass Rate', '$passRate%', PdfColors.blue700),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      ],
    );
  }
}
