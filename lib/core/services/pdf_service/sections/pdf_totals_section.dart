import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../utils/payment_verification_utils.dart';
import 'pdf_helpers.dart';

/// Builds the notes, totals, and payment summary section.
abstract final class PdfTotalsSection {
  static pw.Widget buildNotesAndTotals(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> payments, {
    required String repaymentDate,
    bool isSoIndirectPdf = false,
    /// Detail baris item — dipakai untuk menghitung Subtotal yang bisa diverifikasi
    /// oleh user dengan menjumlahkan kolom HARGA TOTAL di tabel item.
    List<Map<String, dynamic>> details = const [],
  }) {
    final note = (order['note']?.toString() ?? '').trim();
    final grandTotal = PdfHelpers.dbl(order['extended_amount']).roundToDouble();
    // DPP = Dasar Pengenaan Pajak (grandTotal sudah inklusif PPN 11%).
    final dpp = (grandTotal / 1.11).roundToDouble();
    final ppn = grandTotal - dpp;
    // Subtotal = jumlah harga baris item (net_price × qty), dapat diverifikasi
    // dari kolom HARGA TOTAL di tabel item di atas.
    final itemsSubtotal = details.fold<double>(0.0, (sum, d) {
      final qty = PdfHelpers.intFrom(d['qty']);
      final net = PdfHelpers.dbl(d['net_price'] ?? d['customer_price']);
      return sum + net * (qty > 0 ? qty : 1);
    }).roundToDouble();
    // Baris `verified == false` (ditolak/duplikat/invalid) dikeluarkan dari
    // Total Dibayar & daftar cicilan supaya tidak dobel-hitung.
    final countedPayments =
        payments.where((p) => paymentCountsTowardTotal(p['verified'])).toList();
    final totalPaid = countedPayments.fold<double>(
        0, (s, p) => s + PdfHelpers.dbl(p['payment_amount']));
    final remaining = grandTotal - totalPaid;
    final paymentRows = <pw.Widget>[];
    if (countedPayments.isNotEmpty) {
      for (var i = 0; i < countedPayments.length; i++) {
        final p = countedPayments[i];
        final amount = PdfHelpers.dbl(p['payment_amount']);
        final bank = p['payment_bank']?.toString() ?? '';
        final method = p['payment_method']?.toString() ?? '';
        final methodBank = _composePaymentLabel(method, bank);
        final paymentLabel = i == 0 && methodBank.isNotEmpty
            ? '($methodBank)'
            : '(${_paymentOrdinalLabel(i + 1)})';

        final payDate = p['payment_date']?.toString();
        final createdAt = p['created_at']?.toString();
        final dateSource =
            (payDate != null && payDate.isNotEmpty) ? payDate : createdAt;
        final prettyDate = PdfHelpers.prettyDate(dateSource);
        final time = PdfHelpers.extractTime(createdAt);
        final paymentDateLine = prettyDate != null
            ? 'Tgl $prettyDate${time != null ? ' $time' : ''}'
            : null;

        paymentRows
            .add(_paymentEntryRow(paymentLabel, amount, paymentDateLine));
      }
    } else {
      paymentRows.add(_totalCurrencyRow('Sudah Dibayar', totalPaid));
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.85),
        1: pw.FlexColumnWidth(1)
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Keterangan:',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(note.isNotEmpty ? note : '-',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.justify),
                ],
              ),
            ),
            pw.Column(
              children: [
                if (itemsSubtotal > 0)
                  _totalCurrencyRow('Subtotal', itemsSubtotal),
                _totalCurrencyRow('DPP', dpp),
                _totalCurrencyRow('PPN 11%', ppn),
                _totalCurrencyRow('Total', grandTotal, isBold: true),
                if (!isSoIndirectPdf) ...[
                  ...paymentRows,
                  _totalCurrencyRow('Sisa Pembayaran', remaining, isBold: true),
                  _totalRow('Tgl Pelunasan', repaymentDate),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Matches the HARGA TOTAL column content width from the items table.
  static const double _currencyColWidth = 82;

  static pw.Widget _totalRow(String label, String value,
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
            width: _currencyColWidth,
            child: pw.Text(
              value.isNotEmpty ? value : '-',
              style: style,
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _paymentEntryRow(
      String label, double value, String? dateLine) {
    const textStyle = pw.TextStyle(fontSize: 8);
    return pw.Container(
      decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.5))),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Dibayar', style: textStyle),
                pw.Text(label,
                    style: const pw.TextStyle(fontSize: 7), maxLines: 2),
                if (dateLine != null)
                  pw.Text(dateLine,
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey700,
                        fontStyle: pw.FontStyle.italic,
                      )),
              ],
            ),
          ),
          pw.SizedBox(
            width: _currencyColWidth,
            child: PdfHelpers.buildCurrencyCell(value),
          ),
        ],
      ),
    );
  }

  static String _paymentOrdinalLabel(int index) {
    switch (index) {
      case 1:
        return 'Pembayaran Pertama';
      case 2:
        return 'Pembayaran Kedua';
      case 3:
        return 'Pembayaran Ketiga';
      default:
        return 'Pembayaran Ke-$index';
    }
  }

  static String _composePaymentLabel(String method, String bank) {
    final methodUpper = method.trim().toUpperCase();
    final bankUpper = bank.trim().toUpperCase();

    final validMethod = methodUpper.isNotEmpty && methodUpper != '-';
    final validBank = bankUpper.isNotEmpty && bankUpper != '-';

    if (!validMethod && !validBank) return '';
    if (validMethod && !validBank) return methodUpper;
    if (!validMethod && validBank) return bankUpper;

    if (methodUpper == bankUpper) return methodUpper;
    if (bankUpper.contains(methodUpper)) return bankUpper;
    if (methodUpper.contains(bankUpper)) return methodUpper;
    return '$methodUpper $bankUpper';
  }

  static pw.Widget _totalCurrencyRow(String label, double amount,
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
            width: _currencyColWidth,
            child: PdfHelpers.buildCurrencyCell(amount, isBold: isBold),
          ),
        ],
      ),
    );
  }
}
