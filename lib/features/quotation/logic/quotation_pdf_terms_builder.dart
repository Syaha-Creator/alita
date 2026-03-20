import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/quotation_model.dart';

/// Builds the terms & conditions + signature section of the quotation PDF.
///
/// Extracted from [QuotationPdfGenerator] to reduce file size.
class QuotationPdfTermsBuilder {
  QuotationPdfTermsBuilder._();

  static const _terms = [
    'Pembayaran dianggap SAH hanya apabila sudah diterima di rekening perusahaan atas nama:\nPT MASSINDO KARYA PRIMA\nBANK BCA 066-328-8871\nPembayaran ke rekening lain tidak akan diakui sebagai pembayaran yang sah.',
    'Barang yang sudah dipesan / dibeli, tidak dapat ditukar atau dikembalikan.',
    'Uang muka yang telah dibayarkan tidak dapat dikembalikan.',
    'Sleep Center berhak mengubah tanggal pengiriman dengan sebelumnya memberitahukan kepada konsumen.',
    'Surat Pesanan yang sudah lewat 3 (Tiga) bulan namun belum dikirim harus dilunasi jika tidak akan dianggap batal dan uang muka tidak dapat dikembalikan',
    'Apabila konsumen menunda pengiriman selama lebih dari 2 (Dua) Bulan dari tanggal kirim awal, SP dianggap batal dan uang muka tidak dapat dikembalikan',
    'Pembeli akan dikenakan biaya tambahan untuk pengiriman, pembongkaran, pengambilan furnitur dll yang disebabkan adanya kesulitan/ketidakcocokan penempatan furnitur di tempat atau ruangan yang dikehendaki oleh pembeli.',
    'Jika pengiriman dilakukan lebih dari 1 (Satu) kali, konsumen wajib melunasi pembelian sebelum pengiriman pertama.',
    'Untuk tipe dan ukuran khusus, pelunasan harus dilakukan saat pemesanan dan tidak dapat dibatalkan/diganti.',
  ];

  static pw.Widget build(QuotationModel q) {
    final salesName =
        q.salesName.isNotEmpty ? q.salesName : 'SLEEP CONSULTANT';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Syarat - Syarat Pembelian :',
            style:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.SizedBox(height: 3),
        ..._terms.asMap().entries.map((e) {
          final idx = e.key;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                    width: 12,
                    child: pw.Text('${idx + 1}.',
                        style: const pw.TextStyle(fontSize: 7))),
                pw.Expanded(
                  child: idx == 0
                      ? _buildFirstTermWithBoldBank()
                      : pw.Text(e.value,
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.justify),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 10),
        _buildSignatureSection(q.customerName, salesName, q.scCode),
      ],
    );
  }

  static pw.Widget _buildFirstTermWithBoldBank() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pembayaran dianggap SAH hanya apabila sudah diterima di rekening perusahaan atas nama:',
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.SizedBox(height: 2),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('PT MASSINDO KARYA PRIMA',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 1),
              pw.Text('BANK BCA 066-328-8871',
                  style: pw.TextStyle(
                      fontSize: 7, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Pembayaran ke rekening lain tidak akan diakui sebagai pembayaran yang sah.',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection(
      String customerName, String salesName, String scCode) {
    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      child: pw.Row(
        children: [
          _sigBox('PEMBELI', customerName),
          _sigBoxWithCode('SLEEP CONSULTANT', salesName, scCode,
              borderLeft: true),
        ],
      ),
    );
  }

  static pw.Widget _sigBox(String title, String name,
      {bool borderLeft = false}) {
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: borderLeft
            ? const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(width: 0.5)))
            : const pw.BoxDecoration(),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
            pw.Text('($name)', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _sigBoxWithCode(
      String title, String name, String? spgCode,
      {bool borderLeft = false}) {
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: borderLeft
            ? const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(width: 0.5)))
            : const pw.BoxDecoration(),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9)),
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text('($name)', style: const pw.TextStyle(fontSize: 9)),
                if (spgCode != null && spgCode.isNotEmpty) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(spgCode,
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey700)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
