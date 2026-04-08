import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:alitapricelist/features/history/data/models/order_history.dart';

import '../../utils/log.dart';
import '../pdf_asset_cache.dart';
import 'sections/pdf_helpers.dart';
import 'sections/pdf_header_section.dart';
import 'sections/pdf_items_table.dart';
import 'sections/pdf_totals_section.dart';
import 'sections/pdf_approval_signature.dart';

/// Generator PDF Surat Pesanan — 2 versi:
/// * **Eksternal (Customer)**: 7 kolom, tanpa approval, syarat & TTD.
/// * **Internal**: 8 kolom (+END USER PRICE), detail diskon %, tabel approval + stamp.
///
/// Data bisa berupa [Map<String, dynamic>] langsung dari API (preserve order),
/// atau [OrderHistory] via convenience wrappers.
class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate PDF **Eksternal (Customer)**. Return [Uint8List] bytes.
  static Future<Uint8List> generateExternalPdf(
    Map<String, dynamic> orderData,
  ) async =>
      _generate(orderData, isInternal: false);

  /// Generate PDF **Internal** (dengan approval, EUP, discount %).
  static Future<Uint8List> generateInternalPdf(
    Map<String, dynamic> orderData,
  ) async =>
      _generate(orderData, isInternal: true);

  /// Convenience: [OrderHistory] → External PDF → native preview/share.
  static Future<void> generateExternalPdfFromOrder(OrderHistory order) async {
    final data = _orderHistoryToMap(order);
    final bytes = await generateExternalPdf(data);
    final fileName = _buildFileName(order, isInternal: false);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }

  /// Convenience: [OrderHistory] → Internal PDF → native preview/share.
  static Future<void> generateInternalPdfFromOrder(OrderHistory order) async {
    final data = _orderHistoryToMap(order);
    final bytes = await generateInternalPdf(data);
    final fileName = _buildFileName(order, isInternal: true);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: fileName,
    );
  }

  /// Convenience: [OrderHistory] → External PDF → system share sheet.
  static Future<void> shareExternalPdfFromOrder(
    OrderHistory order, {
    required Rect sharePositionOrigin,
  }) async {
    final data = _orderHistoryToMap(order);
    final bytes = await generateExternalPdf(data);
    await _sharePdfBytes(
      bytes,
      _buildFileName(order, isInternal: false),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Convenience: [OrderHistory] → Internal PDF → system share sheet.
  static Future<void> shareInternalPdfFromOrder(
    OrderHistory order, {
    required Rect sharePositionOrigin,
  }) async {
    final data = _orderHistoryToMap(order);
    final bytes = await generateInternalPdf(data);
    await _sharePdfBytes(
      bytes,
      _buildFileName(order, isInternal: true),
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Builds a filesystem-safe PDF file name from order data.
  static String _buildFileName(OrderHistory order, {required bool isInternal}) {
    final suffix = isInternal ? '' : '';
    final customer = _sanitize(order.customerName);
    final noSp = _sanitize(order.noSp);
    return 'SP_${customer}_$noSp$suffix.pdf';
  }

  static String _sanitize(String input) {
    return input
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  static Future<void> _sharePdfBytes(
    Uint8List bytes,
    String fileName, {
    required Rect sharePositionOrigin,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, name: fileName, mimeType: 'application/pdf')],
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE GENERATOR (Orchestrator)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _generate(
    Map<String, dynamic> orderData, {
    required bool isInternal,
  }) async {
    final letter =
        (orderData['order_letter'] ?? orderData) as Map<String, dynamic>;
    final details = PdfHelpers.toListMap(orderData['order_letter_details']);
    final payments = PdfHelpers.toListMap(orderData['order_letter_payments']);
    final approvals = PdfHelpers.toListMap(
        orderData['order_letter_approvals'] ?? orderData['approval_data']);
    final discounts = PdfHelpers.toListMap(
        orderData['order_letter_discounts'] ?? orderData['discount_data']);
    final grandTotal = PdfHelpers.dbl(letter['extended_amount']);
    final tglPelunasan = _extractRepaymentDate(orderData, payments, grandTotal);
    final channelStr = letter['channel']?.toString();
    final isSoIndirectPdf = _isSoIndirectPdfChannel(channelStr);
    final salesCode = orderData['sales_code']?.toString() ?? '';
    final salesIdentity = _resolveSalesIdentity(
      orderData,
      details,
      letter,
      salesCode: salesCode,
      isSoIndirectPdf: isSoIndirectPdf,
    );

    if (!PdfAssetCache.isWarmedUp) await PdfAssetCache.warmUp();
    final logos = _buildLogos(channelStr);
    final approvalsForPdf = isSoIndirectPdf
        ? approvals.where((a) => !_isPdfStoreDiscountRow(a)).toList()
        : approvals;
    final watermark = await _buildWatermark(
        approvals, payments, PdfHelpers.dbl(letter['extended_amount']));
    final pw.ImageProvider? approveStamp =
        isInternal ? PdfAssetCache.approveStamp : null;

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
          buildBackground: (_) => watermark ?? pw.SizedBox(),
        ),
        header: (ctx) => ctx.pageNumber == 1
            ? PdfHeaderSection.buildHeader(logos, letter,
                isSoIndirectPdf: isSoIndirectPdf)
            : pw.Container(),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          PdfHeaderSection.buildCustomerAndOrderInfo(letter,
              isSoIndirectPdf: isSoIndirectPdf),
          pw.SizedBox(height: 12),
          ...PdfItemsTable.buildItemsTable(letter, details, discounts,
              isInternal: isInternal,
              // Persentase diskon toko tetap di tabel item; yang disaring hanya
              // baris approval/stamp diskon toko (approvalsForPdf), bukan kolom DISCOUNT.
              hideStoreDiscountTiers: false),
          pw.SizedBox(height: 8),
          PdfTotalsSection.buildNotesAndTotals(letter, payments,
              repaymentDate: tglPelunasan,
              isSoIndirectPdf: isSoIndirectPdf),
          pw.SizedBox(height: 10),
          if (isInternal && approvalsForPdf.isNotEmpty) ...[
            PdfApprovalSignature.buildApprovalTable(
                approvalsForPdf, approveStamp, letter['created_at']?.toString()),
            pw.SizedBox(height: 10),
          ],
          PdfApprovalSignature.buildTermsAndSignatureSection(
            letter,
            salesName: salesIdentity.$1,
            salesCode: salesIdentity.$2,
            isSoIndirectPdf: isSoIndirectPdf,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGO ASSEMBLY (from cache)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Channel `SO` / `S0` (indirect / Sleep Outlet): layout PDF khusus; stamp approval
  /// baris "diskon toko" disaring lewat [approvalsForPdf], bukan menyembunyikan % di tabel.
  static bool _isSoIndirectPdfChannel(String? channel) {
    final c = channel?.trim().toUpperCase() ?? '';
    return c == 'S0' || c == 'SO';
  }

  /// Baris diskon/approval bertipe diskon toko (level 5+ / label "Diskon Toko …").
  static bool _isPdfStoreDiscountRow(Map<String, dynamic> d) {
    final level = d['approver_level']?.toString().toLowerCase() ?? '';
    return level.startsWith('diskon toko');
  }

  /// Channel `SO` / `S0` (Sleep Outlet / divisi terkait): header pakai teks, bukan logo SC.
  static const _massindoHeaderText = 'PT Massindo Karya Prima';

  static PdfLogos _buildLogos(String? channel) {
    final useMassindoText = _isSoIndirectPdfChannel(channel);
    return PdfLogos(
      sleepCenter: useMassindoText ? null : PdfAssetCache.sleepCenterLogo,
      sleepCenterReplacementText:
          useMassindoText ? _massindoHeaderText : null,
      others: PdfAssetCache.brandLogos,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WATERMARK
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<pw.Widget?> _buildWatermark(
    List<Map<String, dynamic>> approvals,
    List<Map<String, dynamic>> payments,
    double grandTotal,
  ) async {
    final paid = payments.fold<double>(
        0, (s, p) => s + PdfHelpers.dbl(p['payment_amount']));
    final isPaid = grandTotal > 0 && grandTotal - paid <= 0;
    final allApproved = approvals.isNotEmpty &&
        approvals.every((a) => PdfHelpers.isApprovedStatus(a['approved']));

    final isApproved = allApproved || isPaid;
    final String assetPath =
        isApproved ? 'assets/images/paid.png' : 'assets/images/approval.png';

    try {
      final d = await rootBundle.load(assetPath);
      return pw.Center(
        child: pw.Transform.rotate(
          angle: 0.785,
          child: pw.Opacity(
            opacity: 0.10,
            child: pw.Image(pw.MemoryImage(d.buffer.asUint8List()),
                width: 300, height: 300, fit: pw.BoxFit.contain),
          ),
        ),
      );
    } catch (e) {
      Log.warning('PDF watermark failed: $e', tag: 'PDF');
      return pw.Center(
        child: pw.Transform.rotate(
          angle: 0.785,
          child: pw.Text(
            isApproved ? 'PAID' : 'UNPAID',
            style: pw.TextStyle(
              fontSize: 120,
              color: PdfColor(
                isApproved ? PdfColors.green300.red : PdfColors.orange300.red,
                isApproved
                    ? PdfColors.green300.green
                    : PdfColors.orange300.green,
                isApproved ? PdfColors.green300.blue : PdfColors.orange300.blue,
                0.10,
              ),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
            'Dokumen ini dicetak pada: ${PdfHelpers.fmtDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
        pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA MAPPING & HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, dynamic> _orderHistoryToMap(OrderHistory order) {
    final allDiscounts = <Map<String, dynamic>>[];
    final approvalSet = <String>{};
    final approvalList = <Map<String, dynamic>>[];

    final detailMaps = order.details.map((d) {
      for (final disc in d.discounts) {
        allDiscounts.add({
          'order_letter_detail_id': d.id,
          'detail_id': d.id,
          'discount': disc.discountVal,
          'approver_name': disc.approverName,
          'approver_level': disc.approverLevel,
          'approved': disc.approvedStatus,
          'approved_at': disc.approvedAt,
          'approver_level_id': disc.id,
        });

        final key = disc.approverLevel;
        if (!approvalSet.contains(key)) {
          approvalSet.add(key);
          approvalList.add({
            'approver_level': disc.approverLevel,
            'approver_name': disc.approverName,
            'approved': disc.approvedStatus,
            'approved_at': disc.approvedAt,
          });
        }
      }

      return <String, dynamic>{
        'brand': d.brand,
        'item_description': d.itemDescription,
        'desc_1': d.desc1,
        'desc_2': d.desc2,
        'qty': d.qty,
        'item_type': d.itemType,
        'unit_price': d.unitPrice,
        'extended_price': d.extendedPrice,
        'customer_price': d.customerPrice,
        'net_price': d.netPrice,
        'take_away': d.isTakeAway,
        'id': d.id,
        'order_letter_detail_id': d.id,
      };
    }).toList();

    return {
      'order_letter': {
        'no_sp': order.noSp,
        'order_date': order.orderDate,
        'request_date': order.requestDate,
        'customer_name': order.customerName,
        'address': order.address,
        'ship_to_name': order.shipToName,
        'address_ship_to': order.addressShipTo,
        'phone': order.phone,
        'email': order.email,
        'note': order.note,
        'extended_amount': order.totalAmount,
        'postage': order.postage,
        'work_place_name': order.workPlaceName,
        'created_at': order.createdAt?.toIso8601String(),
        'status': order.status,
        'creator': order.creator,
        'creator_name': order.creatorName,
        'sales_code': order.salesCode,
        'sales_name': order.salesName,
        'no_po': order.noPo,
        if ((order.channel ?? '').isNotEmpty) 'channel': order.channel,
      },
      'order_letter_details': detailMaps,
      'order_letter_payments': order.payments
          .map((p) => <String, dynamic>{
                'payment_amount': p.amount,
                'payment_method': p.method,
                'payment_bank': p.bank,
                'payment_date': p.paymentDate,
                'created_at': p.createdAt,
              })
          .toList(),
      'creator': order.creator,
      'creator_name': order.creatorName,
      'sales_code': order.salesCode,
      'sales_name': order.salesName,
      'order_letter_discounts': allDiscounts,
      'order_letter_approvals': approvalList,
    };
  }

  static String _extractRepaymentDate(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> fallbackPayments,
    double grandTotal,
  ) {
    final rawPayments = orderData['order_letter_payments'];
    final payments = rawPayments is List
        ? rawPayments
            .map((e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map))
            .toList()
        : fallbackPayments;

    if (payments.isEmpty) return '-';

    final totalPaid = payments.fold<double>(
        0, (s, p) => s + PdfHelpers.dbl(p['payment_amount']));
    final remaining = grandTotal - totalPaid;

    if (remaining > 0) return '-';

    String tglPelunasan = '-';
    if (payments.length == 1) {
      final rawDate =
          payments.first['payment_date'] ?? payments.first['created_at'];
      if (rawDate != null) {
        final raw = rawDate.toString();
        tglPelunasan = raw.length >= 10 ? raw.substring(0, 10) : raw;
      }
    } else {
      DateTime? latestDate;
      for (final payment in payments) {
        final rawDate = payment['payment_date'] ?? payment['created_at'];
        if (rawDate != null) {
          try {
            final parsedDate = DateTime.parse(rawDate.toString());
            if (latestDate == null || parsedDate.isAfter(latestDate)) {
              latestDate = parsedDate;
            }
          } catch (e) {
            Log.warning('PDF: failed to parse payment date "$rawDate"',
                tag: 'InvoicePdf');
          }
        }
      }
      if (latestDate != null) {
        tglPelunasan = latestDate.toIso8601String().substring(0, 10);
      }
    }

    if (tglPelunasan != '-') {
      tglPelunasan = PdfHelpers.prettyDate(tglPelunasan) ?? tglPelunasan;
    }

    return tglPelunasan;
  }

  static (String, String) _resolveSalesIdentity(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> details,
    Map<String, dynamic> letter, {
    String salesCode = '',
    bool isSoIndirectPdf = false,
  }) {
    salesCode = salesCode.isNotEmpty
        ? salesCode
        : orderData['sales_code']?.toString() ??
            letter['sales_code']?.toString() ??
            letter['spg_code']?.toString() ??
            '';
    final creatorId =
        orderData['creator']?.toString() ?? letter['creator']?.toString() ?? '';
    var salesName = orderData['sales_name']?.toString() ??
        orderData['creator_name']?.toString() ??
        letter['sales_name']?.toString() ??
        letter['creator_name']?.toString() ??
        '';

    if (salesName.isEmpty) {
      try {
        final rootDiscounts = PdfHelpers.toListMap(
          orderData['order_letter_discounts'] ?? orderData['discount_data'],
        );
        final nestedDiscounts = details.isNotEmpty
            ? PdfHelpers.toListMap(details.first['order_letter_discount'])
            : <Map<String, dynamic>>[];
        final discounts = [...nestedDiscounts, ...rootDiscounts];

        if (discounts.isNotEmpty) {
          for (final discount in discounts) {
            final approverId = discount['approver_id']?.toString() ?? '';
            final approverLevel =
                discount['approver_level']?.toString().toLowerCase() ?? '';
            if (approverId == creatorId || approverLevel == 'user') {
              salesName = discount['approver_name']?.toString() ?? '';
              break;
            }
          }

          if (salesName.isEmpty) {
            salesName = discounts.first['approver_name']?.toString() ?? '';
          }
        }
      } catch (e, st) {
        Log.error(e, st, reason: 'PDF: failed to resolve sales identity');
      }
    }

    if (salesName.isEmpty) {
      if (isSoIndirectPdf) {
        salesName = creatorId.isNotEmpty ? 'Admin ($creatorId)' : '-';
      } else {
        salesName =
            creatorId.isNotEmpty ? 'Admin ($creatorId)' : 'SLEEP CONSULTANT';
      }
    }

    return (salesName, salesCode);
  }
}
