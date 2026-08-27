import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:alitapricelist/features/history/data/models/order_history.dart';

import '../../utils/log.dart';
import '../../utils/payment_verification_utils.dart';
import '../pdf_asset_cache.dart';
import 'sections/pdf_helpers.dart';
import 'sections/pdf_header_section.dart';
import 'sections/pdf_items_table.dart';
import 'sections/pdf_totals_section.dart';
import 'sections/pdf_approval_signature.dart';

/// Hasil keputusan stempel watermark PDF: aset gambar + fallback teks/warna
/// kalau aset gagal dimuat. Lihat [InvoicePdfGenerator.resolveWatermarkSpec].
class WatermarkSpec {
  const WatermarkSpec({
    required this.assetPath,
    required this.fallbackLabel,
    required this.fallbackColor,
  });

  final String assetPath;
  final String fallbackLabel;
  final PdfColor fallbackColor;
}

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
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, name: fileName, mimeType: 'application/pdf')],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE GENERATOR (Orchestrator)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _generate(
    Map<String, dynamic> orderData, {
    required bool isInternal,
  }) async {
    final letterRaw =
        (orderData['order_letter'] ?? orderData) as Map<String, dynamic>;
    final letter = PdfHelpers.letterWithContactPhonesForPdf(
      Map<String, dynamic>.from(letterRaw),
      orderData,
    );
    final details = PdfHelpers.toListMap(orderData['order_letter_details']);
    final payments = PdfHelpers.toListMap(orderData['order_letter_payments']);
    final approvals = PdfHelpers.toListMap(
        orderData['order_letter_approvals'] ?? orderData['approval_data']);
    final discounts = PdfHelpers.resolveDiscountRows(orderData, details);
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
    // Stempel diskon toko selalu disembunyikan dari blok PERSETUJUAN — persentase
    // diskon toko masih tampil di kolom DISKON tabel item. Filter berlaku untuk
    // SO, S0, maupun direct (tidak tergantung channel).
    final approvalsForPdf =
        approvals.where((a) => !_isPdfStoreDiscountRow(a)).toList();
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
              isSoIndirectPdf: isSoIndirectPdf,
              details: details),
          pw.SizedBox(height: 10),
          if (isInternal && approvalsForPdf.isNotEmpty) ...[
            PdfApprovalSignature.buildApprovalTable(approvalsForPdf,
                approveStamp, letter['created_at']?.toString()),
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

  /// Hanya channel **`SO`** yang memakai layout PDF **indirect** (Massindo header, blok penerima, dll.).
  /// Channel **`S0`** diperlakukan seperti PDF **direct** (sama MM / tanpa channel).
  /// Stamp approval: baris "diskon toko" tetap disaring lewat [approvalsForPdf] hanya saat indirect.
  static bool _isSoIndirectPdfChannel(String? channel) {
    final c = channel?.trim().toUpperCase() ?? '';
    return c == 'SO';
  }

  /// Baris diskon/approval bertipe diskon toko (level 5+ / label "Diskon Toko …").
  static bool _isPdfStoreDiscountRow(Map<String, dynamic> d) {
    final level = d['approver_level']?.toString().toLowerCase() ?? '';
    return level.startsWith('diskon toko');
  }

  /// Channel **`SO`** saja: header pakai teks Massindo, bukan logo Sleep Center. **`S0`** pakai logo seperti direct.
  static const _massindoHeaderText = 'PT Massindo Karya Prima';

  static PdfLogos _buildLogos(String? channel) {
    final useMassindoText = _isSoIndirectPdfChannel(channel);
    return PdfLogos(
      sleepCenter: useMassindoText ? null : PdfAssetCache.sleepCenterLogo,
      sleepCenterReplacementText: useMassindoText ? _massindoHeaderText : null,
      others: PdfAssetCache.brandLogos,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WATERMARK
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stempel PDF punya 6 status berbeda — "approved" (semua approver
  /// menyetujui) TIDAK sama dengan "lunas" (grand total sudah terbayar).
  /// SP boleh saja fully-approved tapi belum ada pembayaran sama sekali,
  /// jadi stempel PAID tidak boleh keluar hanya karena approval selesai.
  ///
  /// Pure decision logic — dipisah dari I/O ([rootBundle.load]) agar bisa
  /// diuji tanpa perlu render PDF sungguhan.
  @visibleForTesting
  static WatermarkSpec resolveWatermarkSpec(
    List<Map<String, dynamic>> approvals,
    List<Map<String, dynamic>> payments,
    double grandTotal,
  ) {
    final allApproved = approvals.isNotEmpty &&
        approvals.every((a) => PdfHelpers.isApprovedStatus(a['approved']));

    if (!allApproved) {
      return const WatermarkSpec(
        assetPath: 'assets/images/approval.png',
        fallbackLabel: 'MENUNGGU APPROVAL',
        fallbackColor: PdfColors.yellow700,
      );
    }

    final countedPayments =
        payments.where((p) => paymentCountsTowardTotal(p['verified']));
    final hasPendingVerification =
        countedPayments.any((p) => p['verified'] == null);
    final paid = countedPayments.fold<double>(
        0, (s, p) => s + PdfHelpers.dbl(p['payment_amount']));
    final isFullyPaid = grandTotal > 0 && paid >= grandTotal;
    final isPartiallyPaid = paid > 0 && !isFullyPaid;

    if (payments.isEmpty) {
      return const WatermarkSpec(
        assetPath: 'assets/images/approve.png',
        fallbackLabel: 'APPROVED',
        fallbackColor: PdfColors.green300,
      );
    }
    if (hasPendingVerification) {
      return const WatermarkSpec(
        assetPath: 'assets/images/verification.png',
        fallbackLabel: 'MENUNGGU VERIFIKASI',
        fallbackColor: PdfColors.blue300,
      );
    }
    if (isFullyPaid) {
      return const WatermarkSpec(
        assetPath: 'assets/images/paid.png',
        fallbackLabel: 'LUNAS',
        fallbackColor: PdfColors.green300,
      );
    }
    if (isPartiallyPaid) {
      return const WatermarkSpec(
        assetPath: 'assets/images/dp.png',
        fallbackLabel: 'DP TERVERIFIKASI',
        fallbackColor: PdfColors.cyan300,
      );
    }
    return const WatermarkSpec(
      assetPath: 'assets/images/unpaid.png',
      fallbackLabel: 'BELUM LUNAS',
      fallbackColor: PdfColors.red300,
    );
  }

  static Future<pw.Widget?> _buildWatermark(
    List<Map<String, dynamic>> approvals,
    List<Map<String, dynamic>> payments,
    double grandTotal,
  ) async {
    final spec = resolveWatermarkSpec(approvals, payments, grandTotal);
    return _watermarkFromAsset(
      spec.assetPath,
      fallbackLabel: spec.fallbackLabel,
      fallbackColor: spec.fallbackColor,
    );
  }

  static Future<pw.Widget> _watermarkFromAsset(
    String assetPath, {
    required String fallbackLabel,
    required PdfColor fallbackColor,
  }) async {
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
            fallbackLabel,
            style: pw.TextStyle(
              fontSize: 90,
              color: PdfColor(
                fallbackColor.red,
                fallbackColor.green,
                fallbackColor.blue,
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
        final programLabel = disc.discountProgram.trim();
        allDiscounts.add({
          'order_letter_detail_id': d.id,
          'detail_id': d.id,
          'discount': disc.discountVal,
          'approver_name': disc.approverName,
          'approver_level': disc.approverLevel,
          'approved': disc.approvedStatus,
          'approved_at': disc.approvedAt,
          'approver_level_id': disc.approverLevelId,
          if (disc.discountPrice > 0) 'discount_price': disc.discountPrice,
          if (programLabel.isNotEmpty && programLabel != '-')
            'discount_program': programLabel,
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
        if (d.itemNumber.trim().isNotEmpty) 'item_number': d.itemNumber.trim(),
        if (d.pricelistType.trim().isNotEmpty)
          'pricelist_type': d.pricelistType.trim(),
        if (d.pricelistArea.trim().isNotEmpty)
          'pricelist_area': d.pricelistArea.trim(),
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
                'verified': p.verified,
              })
          .toList(),
      'creator': order.creator,
      'creator_name': order.creatorName,
      'sales_code': order.salesCode,
      'sales_name': order.salesName,
      'order_letter_discounts': allDiscounts,
      'order_letter_approvals': approvalList,
      if (order.orderLetterContacts.isNotEmpty)
        'order_letter_contacts': order.orderLetterContacts,
    };
  }

  static String _extractRepaymentDate(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> fallbackPayments,
    double grandTotal,
  ) {
    final rawPayments = orderData['order_letter_payments'];
    final allPayments = rawPayments is List
        ? rawPayments
            .map((e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map))
            .toList()
        : fallbackPayments;
    // `verified == false` (ditolak/duplikat/invalid) tidak dihitung sebagai
    // pelunasan.
    final payments = allPayments
        .where((p) => paymentCountsTowardTotal(p['verified']))
        .toList();

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

  /// Resolves sales/SC name via fallback chain: order/letter fields first,
  /// then the discount approver matching the creator ID or level `"user"`,
  /// finally a generic placeholder (label differs for indirect vs direct).
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
