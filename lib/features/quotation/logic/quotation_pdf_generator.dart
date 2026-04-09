import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/services/pdf_asset_cache.dart';
import '../data/quotation_model.dart';
import 'quotation_pdf_cell_helpers.dart';
import 'quotation_pdf_items_builder.dart';
import 'quotation_pdf_terms_builder.dart';

/// Generates a "PENAWARAN HARGA (QUOTATION)" PDF from local [QuotationModel].
///
/// Mirrors the **external/customer invoice** layout 1-to-1:
///   Header → Customer Info → Items Table → Notes & Totals → Terms → Signature
///
/// Added for quotation only:
///   * "PENAWARAN HARGA (QUOTATION)" banner between header and customer info
///   * Disclaimer section after signature
class QuotationPdfGenerator {
  QuotationPdfGenerator._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> generateAndShare(
    QuotationModel quotation, {
    Rect? sharePositionOrigin,
  }) async {
    final bytes = await _generate(quotation);
    final fileName = _buildFileName(quotation);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, name: fileName, mimeType: 'application/pdf')],
      sharePositionOrigin: sharePositionOrigin ?? Rect.zero,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE GENERATOR
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _generate(QuotationModel q) async {
    if (!PdfAssetCache.isWarmedUp) await PdfAssetCache.warmUp();

    final sleepCenterLogo = PdfAssetCache.sleepCenterLogo;
    final brandLogos = PdfAssetCache.brandLogos;
    final theme = pw.ThemeData.withFont(
      base: PdfAssetCache.fontBase,
      bold: PdfAssetCache.fontBold,
      italic: PdfAssetCache.fontItalic,
      boldItalic: PdfAssetCache.fontBold,
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          theme: theme,
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? _buildHeader(sleepCenterLogo, brandLogos, q)
            : pw.Container(),
        footer: _buildFooter,
        build: (ctx) => [
          _buildQuotationBanner(),
          pw.SizedBox(height: 4),
          _buildCustomerInfo(q),
          pw.SizedBox(height: 12),
          ...QuotationPdfItemsBuilder.build(q),
          pw.SizedBox(height: 8),
          _buildNotesAndTotals(q),
          pw.SizedBox(height: 10),
          _buildDisclaimer(),
          pw.SizedBox(height: 10),
          QuotationPdfTermsBuilder.build(q),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildHeader(
    pw.ImageProvider? sleepCenterLogo,
    List<pw.ImageProvider?> brandLogos,
    QuotationModel q,
  ) {
    final validBrandLogos = brandLogos.whereType<pw.ImageProvider>().toList();
    final workPlace =
        q.workPlaceName.isNotEmpty ? q.workPlaceName : 'SLEEP CENTER';

    return pw.Column(
      children: [
        if (sleepCenterLogo != null)
          pw.Container(
            height: 70,
            alignment: pw.Alignment.center,
            child: pw.Image(sleepCenterLogo, fit: pw.BoxFit.contain),
          ),
        if (validBrandLogos.isNotEmpty)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: validBrandLogos
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
            pw.Text('SHOWROOM/PAMERAN: $workPlace',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
                'TANGGAL PENAWARAN: ${QuotationPdfCellHelpers.dateFmt.format(q.createdAt)}',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Divider(color: PdfColors.black, thickness: 1.5),
        pw.SizedBox(height: 5),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUOTATION BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildQuotationBanner() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColor(0.204, 0.451, 0.91),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Center(
        child: pw.Text(
          'SURAT PESANAN (OFFLINE)',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUSTOMER INFO
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildCustomerInfo(QuotationModel q) {
    final customerAddress = QuotationPdfCellHelpers.buildFullAddress(
      q.customerAddress,
      q.regionKecamatan,
      q.regionKota,
      q.regionProvinsi,
    );

    final reqDate = q.requestDate;
    final requestDateText = reqDate != null && reqDate.isNotEmpty
        ? QuotationPdfCellHelpers.prettyDate(reqDate) ?? reqDate
        : '-';

    final phone = [q.customerPhone, q.customerPhone2]
        .where((p) => p.isNotEmpty)
        .join(' / ');

    const colWidths = {
      0: pw.IntrinsicColumnWidth(),
      1: pw.FixedColumnWidth(10),
      2: pw.FlexColumnWidth(),
    };

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Table(
            columnWidths: colWidths,
            children: [
              QuotationPdfCellHelpers.infoRow('Nama Customer', q.customerName),
              QuotationPdfCellHelpers.infoRow(
                  'Alamat Customer', customerAddress),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Table(
            columnWidths: colWidths,
            children: [
              QuotationPdfCellHelpers.infoRow('No. Ref', _buildRefNumber(q)),
              QuotationPdfCellHelpers.infoRow('Tgl Kirim', requestDateText),
              QuotationPdfCellHelpers.infoRow(
                  'Telepon', phone.isNotEmpty ? phone : '-'),
              QuotationPdfCellHelpers.infoRow(
                  'Email', q.customerEmail.isNotEmpty ? q.customerEmail : '-'),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NOTES & TOTALS
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildNotesAndTotals(QuotationModel q) {
    final grandTotal = q.totalPrice;
    final subtotal = (grandTotal / 1.11).roundToDouble();
    final ppn = grandTotal - subtotal;

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1.85),
        1: pw.FlexColumnWidth(1),
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
                  pw.Text(q.notes.isNotEmpty ? q.notes : '-',
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.justify),
                ],
              ),
            ),
            pw.Column(
              children: [
                QuotationPdfCellHelpers.totalCurrencyRow('Subtotal', subtotal),
                QuotationPdfCellHelpers.totalCurrencyRow('PPN 11%', ppn),
                if (q.discount > 0)
                  QuotationPdfCellHelpers.totalCurrencyRow(
                      'Diskon', q.discount),
                QuotationPdfCellHelpers.totalCurrencyRow(
                    'Grand Total', grandTotal,
                    isBold: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISCLAIMER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildDisclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor(1, 0.98, 0.94),
        border: pw.Border.all(color: const PdfColor(0.96, 0.82, 0.52)),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DISCLAIMER',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.73, 0.49, 0.0))),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dokumen ini adalah surat pesanan (offline) dan ini adalah'
            ' bukti transaksi sementara dan SC atau Sales akan mengirimkan'
            ' Surat Pesanan Resmi kemudian setelah SP Resmi diterima.',
            style: const pw.TextStyle(
                fontSize: 7.5, color: PdfColor(0.4, 0.4, 0.4)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
        ),
        pw.Text(
          'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _buildRefNumber(QuotationModel q) {
    final hash = q.id.replaceAll('-', '').substring(0, 8).toUpperCase();
    final month = DateFormat('MMyy').format(q.createdAt);
    return 'QT-$hash-$month';
  }

  static String _buildFileName(QuotationModel q) {
    final name = q.customerName
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final ref = _buildRefNumber(q);
    return 'Quotation_${name}_$ref.pdf';
  }
}
