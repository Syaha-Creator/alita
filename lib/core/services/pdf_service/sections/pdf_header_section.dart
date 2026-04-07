import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_helpers.dart';

/// Holds pre-loaded logo image providers.
class PdfLogos {
  final pw.ImageProvider? sleepCenter;
  /// Channel S0/SO: ganti logo Sleep Center dengan teks perusahaan.
  final String? sleepCenterReplacementText;
  final List<pw.ImageProvider?> others;
  const PdfLogos({
    this.sleepCenter,
    this.sleepCenterReplacementText,
    this.others = const [],
  });
}

/// Builds the PDF header and customer/order info rows.
abstract final class PdfHeaderSection {
  static pw.Widget buildHeader(
    PdfLogos logos,
    Map<String, dynamic> order, {
    bool isSoIndirectPdf = false,
  }) {
    final workPlace = order['work_place_name']?.toString() ?? 'SLEEP CENTER';
    final orderDate =
        PdfHelpers.prettyDate(order['order_date']) ?? PdfHelpers.fmtDate(DateTime.now());

    final validOtherLogos = logos.others.whereType<pw.ImageProvider>().toList();

    final replacement = logos.sleepCenterReplacementText?.trim() ?? '';
    return pw.Column(
      children: [
        if (replacement.isNotEmpty)
          pw.Container(
            height: 70,
            alignment: pw.Alignment.center,
            child: pw.Text(
              replacement,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              textAlign: pw.TextAlign.center,
            ),
          )
        else if (logos.sleepCenter case final sc?)
          pw.Container(
            height: 70,
            alignment: pw.Alignment.center,
            child: pw.Image(sc, fit: pw.BoxFit.contain),
          ),
        if (validOtherLogos.isNotEmpty)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: validOtherLogos
                .map((l) => pw.Expanded(
                      child: pw.Container(
                        height: 45,
                        padding:
                            const pw.EdgeInsets.symmetric(horizontal: 4),
                        child: pw.Image(l, fit: pw.BoxFit.contain),
                      ),
                    ))
                .toList(),
          ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              isSoIndirectPdf
                  ? 'SURAT PESANAN INDIRECT'
                  : 'SHOWROOM/PAMERAN: $workPlace',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              isSoIndirectPdf
                  ? 'Tanggal: $orderDate'
                  : 'TANGGAL PEMBELIAN: $orderDate',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        pw.Divider(color: PdfColors.black, thickness: 1.5),
        pw.SizedBox(height: 5),
      ],
    );
  }

  static pw.Widget buildCustomerAndOrderInfo(
    Map<String, dynamic> order, {
    bool isSoIndirectPdf = false,
  }) {
    final noPoRaw = order['no_po'];
    final noPoText = noPoRaw == null
        ? '-'
        : (noPoRaw.toString().trim().isEmpty ? '-' : noPoRaw.toString().trim());

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Table(
            columnWidths: {
              0: const pw.IntrinsicColumnWidth(),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              _infoRow(
                  'Nama Customer', order['customer_name']?.toString() ?? '-'),
              _infoRow('Alamat Customer', order['address']?.toString() ?? '-'),
              _infoRow(
                  'Nama Penerima',
                  order['ship_to_name']?.toString() ??
                      order['customer_name']?.toString() ??
                      '-'),
              _infoRow('Alamat Pengiriman',
                  order['address_ship_to']?.toString() ?? '-'),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Table(
            columnWidths: {
              0: const pw.IntrinsicColumnWidth(),
              1: const pw.FixedColumnWidth(10),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              _infoRow('No. SP.', order['no_sp']?.toString() ?? '-'),
              if (isSoIndirectPdf) _infoRow('No. PO', noPoText),
              _infoRow(
                  'Tgl Kirim', PdfHelpers.prettyDate(order['request_date']) ?? '-'),
              _infoRow('Telepon', order['phone']?.toString() ?? '-'),
              _infoRow('Email', order['email']?.toString() ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _infoRow(String label, String value) {
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
}
