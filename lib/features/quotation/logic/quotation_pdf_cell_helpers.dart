import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:alitapricelist/core/utils/log.dart';

/// Shared PDF cell/formatting helpers for quotation PDF generation.
///
/// Extracted from [QuotationPdfGenerator] to reduce file size.
class QuotationPdfCellHelpers {
  QuotationPdfCellHelpers._();

  static final curFmt = NumberFormat('#,##0', 'id_ID');
  static final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

  static pw.Widget tc(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: const pw.TextStyle(fontSize: 8), textAlign: align),
    );
  }

  static pw.Widget currencyTc(double amount, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: buildCurrencyCell(amount, isBold: isBold),
    );
  }

  static pw.Widget buildCurrencyCell(double amount, {bool isBold = false}) {
    final textStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Rp', style: textStyle),
        pw.Text(curFmt.format(amount.round()),
            style: textStyle, textAlign: pw.TextAlign.right),
      ],
    );
  }

  static pw.Widget totalCurrencyRow(String label, double amount,
      {bool isBold = false}) {
    final style = pw.TextStyle(
        fontSize: 8,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.2),
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.black))),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(
            width: 82,
            child: buildCurrencyCell(amount, isBold: isBold),
          ),
        ],
      ),
    );
  }

  static pw.TableRow infoRow(String label, String value) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text('  :', style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text(
            value.isNotEmpty ? value : '-',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  static String? prettyDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty || raw == '-') return null;
    try {
      return dateFmt.format(DateTime.parse(raw));
    } catch (_) {
      Log.warning('QuotationPdf prettyDate parse failed: $raw', tag: 'PDF');
      return raw;
    }
  }

  static String buildFullAddress(
    String street,
    String kecamatan,
    String kota,
    String provinsi,
  ) {
    final parts = [street, kecamatan, kota, provinsi]
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : '-';
  }

  static String brandAbbr(String brand) {
    final b = brand.toLowerCase();
    if (b.contains('spring air')) return 'SA';
    if (b.contains('therapedic')) return 'TH';
    if (b.contains('comforta')) return 'CF';
    if (b.contains('sleep spa')) return 'SS';
    if (b.contains('superfit')) return 'SF';
    if (b.contains('isleep')) return 'isleep';
    return brand.length >= 2
        ? brand.substring(0, 2).toUpperCase()
        : brand.toUpperCase();
  }

  static double parsePostage(String raw) {
    if (raw.isEmpty) return 0;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digits) ?? 0;
  }

  static String appendSizeIfMissing(String name, String size) {
    final trimmedName = name.trim();
    final trimmedSize = size.trim();
    if (trimmedSize.isEmpty || trimmedSize.toLowerCase() == 'bonus') {
      return trimmedName;
    }
    if (trimmedName.toLowerCase().contains(trimmedSize.toLowerCase())) {
      return trimmedName;
    }
    return '$trimmedName $trimmedSize';
  }

  static String cleanComponentName(String originalName, String size) {
    if (size.isEmpty) return originalName.trim();
    var cleaned = originalName.replaceAll(size, '').trim();
    if (cleaned.endsWith('-')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    if (cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    return '$cleaned $size';
  }
}
