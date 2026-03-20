import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:alitapricelist/core/enums/order_status.dart';
import 'package:alitapricelist/core/utils/log.dart';

import 'pdf_helpers.dart';

/// Builds the approval table, terms & conditions, and signature section.
abstract final class PdfApprovalSignature {
  static pw.Widget buildApprovalTable(
    List<Map<String, dynamic>> approvals,
    pw.ImageProvider? stamp,
    String? createdAt,
  ) {
    if (approvals.isEmpty) return pw.SizedBox.shrink();

    final byLevel = <String, List<Map<String, dynamic>>>{};
    for (final a in approvals) {
      final level = a['approver_level']?.toString() ?? 'Unknown';
      byLevel.putIfAbsent(level, () => []).add(a);
    }

    final cols = <pw.Widget>[];
    for (final entry in byLevel.entries) {
      final level = entry.key;
      final list = entry.value;
      final approved = list.firstWhere(
          (a) => PdfHelpers.isApprovedStatus(a['approved']),
          orElse: () => {});
      final isApproved = approved.isNotEmpty;
      final name = isApproved
          ? (approved['approver_name']?.toString() ?? 'Unknown')
          : (list.first['approver_name']?.toString() ??
              OrderStatus.pending.apiValue);
      final displayLevel = _mapLevel(level);
      final isUser = level.toLowerCase() == 'user';

      String dateText = '';
      if (isApproved) {
        final rawApprovedAt = approved['approved_at']?.toString();
        dateText = _formatApprovalDate(rawApprovedAt);
      }
      if (dateText.isEmpty && isUser && createdAt != null) {
        dateText = _formatApprovalDate(createdAt);
      }

      cols.add(
        pw.Container(
          width: 80,
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(displayLevel,
                  style:
                      pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 4),
              pw.SizedBox(
                width: 32,
                height: 32,
                child: isApproved
                    ? (stamp != null
                        ? pw.Image(stamp)
                        : pw.Container(
                            decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                    color: PdfColors.green, width: 1.5),
                                borderRadius: pw.BorderRadius.circular(4)),
                            child: pw.Center(
                                child: pw.Text('APPROVED',
                                    style: pw.TextStyle(
                                        fontSize: 4.5,
                                        color: PdfColors.green,
                                        fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.center)),
                          ))
                    : pw.Container(
                        decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                                color: PdfColors.orange, width: 1),
                            borderRadius: pw.BorderRadius.circular(4)),
                        child: pw.Center(
                            child: pw.Text('PENDING',
                                style: pw.TextStyle(
                                    fontSize: 5,
                                    color: PdfColors.orange,
                                    fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.center)),
                      ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(name,
                  style: pw.TextStyle(
                      fontSize: 7,
                      color: isApproved ? PdfColors.black : PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2),
              if (dateText.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(dateText,
                    style: const pw.TextStyle(
                        fontSize: 6, color: PdfColors.grey600),
                    textAlign: pw.TextAlign.center),
              ],
            ],
          ),
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('APPROVAL',
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: cols),
        ],
      ),
    );
  }

  static pw.Widget buildTermsAndSignatureSection(
    Map<String, dynamic> order, {
    required String salesName,
    required String salesCode,
  }) {
    final customerName = order['customer_name']?.toString() ?? 'No Name';

    const terms = [
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

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Syarat - Syarat Pembelian :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.SizedBox(height: 3),
        ...terms.asMap().entries.map((e) {
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
                      ? _buildFirstTermWithBoldBank(e.value)
                      : pw.Text(e.value,
                          style: const pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.justify),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 10),
        _buildSignatureSection(customerName, salesName, salesCode),
      ],
    );
  }

  static pw.Widget _buildFirstTermWithBoldBank(String text) {
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
      String customerName, String salesName, String? spgCode) {
    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      child: pw.Row(
        children: [
          _sigBox('PEMBELI', customerName),
          _sigBoxWithCode('SLEEP CONSULTANT', salesName, spgCode,
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

  static pw.Widget _sigBoxWithCode(String title, String name, String? spgCode,
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

  // ── Private helpers ──

  static String _mapLevel(String level) {
    switch (level.toLowerCase()) {
      case 'user':
        return 'SC';
      case 'direct leader':
        return 'Supervisor';
      case 'indirect leader':
        return 'RSM';
      case 'controller':
        return 'Controller';
      case 'analyst':
        return 'Analyst';
      default:
        return level;
    }
  }

  static String _formatApprovalDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      if (rawDate.contains('T')) {
        final date = DateTime.parse(rawDate);
        return '${date.day.toString().padLeft(2, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.year} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}';
      }
      return rawDate.length > 16 ? rawDate.substring(0, 16) : rawDate;
    } catch (_) {
      Log.warning('PDF date parse failed: $rawDate', tag: 'PDF');
      return rawDate.length > 16 ? rawDate.substring(0, 16) : rawDate;
    }
  }
}
