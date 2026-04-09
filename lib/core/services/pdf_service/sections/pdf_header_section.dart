import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_helpers.dart';

/// Holds pre-loaded logo image providers.
class PdfLogos {
  final pw.ImageProvider? sleepCenter;
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
  /// Lebar kolom label (pt): cukup untuk label terpanjang + titik dua tetap sejajar; jangan
  /// terlalu lebar agar jarak teks–`:` tidak berlebihan.
  static const double _labelColLeft = 104;
  static const double _labelColRight = 108;
  static pw.Widget buildHeader(
    PdfLogos logos,
    Map<String, dynamic> order, {
    bool isSoIndirectPdf = false,
  }) {
    final workPlace = order['work_place_name']?.toString() ?? 'SLEEP CENTER';
    final orderDate = PdfHelpers.prettyDate(order['order_date']) ??
        PdfHelpers.fmtDate(DateTime.now());

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
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
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
                  : 'TOKO / PAMERAN: $workPlace',
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

    final pemesanPhones = order['pdf_phones_pemesan']?.toString().trim() ?? '';
    final penerimaPhones =
        order['pdf_phones_penerima']?.toString().trim() ?? '';
    final teleponPenerimaDisplay = penerimaPhones.isNotEmpty
        ? penerimaPhones
        : (order['phone']?.toString() ?? '-');

    if (isSoIndirectPdf) {
      // Dua band: (1) toko ↔ SP/PO/tgl kirim — (2) penerima ↔ telepon/email
      // sehingga baris pertama kontak kanan sejajar dengan "Nama Penerima".
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _infoTable(
                  [
                    _infoRow(
                      'Nama pelanggan',
                      order['customer_name']?.toString() ?? '-',
                    ),
                    _infoRow(
                      'Alamat pelanggan',
                      order['address']?.toString() ?? '-',
                    ),
                  ],
                  labelColumnWidth: _labelColLeft,
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: _infoTable(
                  [
                    _infoRow('No. SP.', order['no_sp']?.toString() ?? '-'),
                    _infoRow('No. PO', noPoText),
                    _infoRow(
                      'Tgl Kirim',
                      PdfHelpers.prettyDate(order['request_date']) ?? '-',
                    ),
                  ],
                  labelColumnWidth: _labelColRight,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _infoTable(
                  [
                    _infoRow(
                      'Nama penerima',
                      order['ship_to_name']?.toString() ??
                          order['customer_name']?.toString() ??
                          '-',
                    ),
                    _infoRow(
                      'Alamat penerima',
                      order['address_ship_to']?.toString() ?? '-',
                    ),
                  ],
                  labelColumnWidth: _labelColLeft,
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                child: _infoTable(
                  [
                    _infoRow(
                      'Telepon penerima',
                      teleponPenerimaDisplay,
                    ),
                    _infoRow(
                      'E-mail penerima',
                      order['email']?.toString() ?? '-',
                    ),
                  ],
                  labelColumnWidth: _labelColRight,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final leftRows = <pw.TableRow>[
      _infoRow('Nama pelanggan', order['customer_name']?.toString() ?? '-'),
      _infoRow('Alamat pelanggan', order['address']?.toString() ?? '-'),
      _infoRow(
        'Nama penerima',
        order['ship_to_name']?.toString() ??
            order['customer_name']?.toString() ??
            '-',
      ),
      _infoRow(
          'Alamat Pengiriman', order['address_ship_to']?.toString() ?? '-'),
    ];
    final hasPemisahTelepon =
        pemesanPhones.isNotEmpty && penerimaPhones.isNotEmpty;
    final rightRows = <pw.TableRow>[
      _infoRow('No. SP.', order['no_sp']?.toString() ?? '-'),
      _infoRow(
        'Tgl Kirim',
        PdfHelpers.prettyDate(order['request_date']) ?? '-',
      ),
      if (hasPemisahTelepon) ...[
        _infoRow('Telepon pemesan', pemesanPhones),
        _infoRow('Telepon penerima', penerimaPhones),
      ] else
        _infoRow('Telepon', order['phone']?.toString() ?? '-'),
      _infoRow('E-mail', order['email']?.toString() ?? '-'),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _infoTable(leftRows, labelColumnWidth: _labelColLeft),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: _infoTable(rightRows, labelColumnWidth: _labelColRight),
        ),
      ],
    );
  }

  static pw.Widget _infoTable(
    List<pw.TableRow> rows, {
    required double labelColumnWidth,
  }) {
    return pw.Table(
      columnWidths: {
        0: pw.FixedColumnWidth(labelColumnWidth),
        1: const pw.FixedColumnWidth(6),
        2: const pw.FlexColumnWidth(),
      },
      children: rows,
    );
  }

  static pw.TableRow _infoRow(String label, String value) {
    return pw.TableRow(
      verticalAlignment: pw.TableCellVerticalAlignment.top,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1, bottom: 1, right: 2),
          child: pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.left,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          child: pw.Text(':', style: const pw.TextStyle(fontSize: 9)),
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
