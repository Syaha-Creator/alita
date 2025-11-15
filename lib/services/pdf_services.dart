import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

import '../config/app_constant.dart';
import '../core/utils/format_helper.dart';
import '../features/cart/domain/entities/cart_entity.dart';

/// Service untuk generate, simpan, dan share PDF checkout.
class PDFService {
  static String _sanitizeFileName(String fileName) {
    final sanitized = fileName
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\r\n]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (sanitized.isEmpty) {
      return 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
    }
    return sanitized;
  }

  /// Generate PDF checkout dari cart dan detail customer.
  static Future<Uint8List> generateCheckoutPDF({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerAddress,
    required String shippingAddress,
    required String phoneNumber,
    required String deliveryDate,
    required String paymentMethod,
    required double paymentAmount,
    required String repaymentDate,
    required double grandTotal,
    String? email,
    String? keterangan,
    String? salesName,
    String? spgCode,
    String? orderLetterNo,
    String? orderLetterStatus,
    String? orderLetterDate,
    String? orderDate,
    String? workPlaceName,
    List<Map<String, dynamic>>? approvalData,
    double? orderLetterExtendedAmount,
    double? orderLetterHargaAwal,
    String? shipToName,
    List<Map<String, dynamic>>? discountData,
    Map<String, List<Map<String, dynamic>>>? pricingData,
    bool showApprovalColumn = false,
  }) async {
    final pdf = pw.Document();

    // Load semua logo seperti sebelumnya
    final sleepCenterLogo =
        await _loadImageProvider('assets/logo/sleepcenter_logo.png');
    final sleepSpaLogo =
        await _loadImageProvider('assets/logo/sleepspa_logo.png');
    final springAirLogo =
        await _loadImageProvider('assets/logo/springair_logo.png');
    final therapedicLogo =
        await _loadImageProvider('assets/logo/therapedic_logo.png');

    // Load approval stamp image
    pw.ImageProvider? approveStamp;
    if (showApprovalColumn) {
      approveStamp = await _loadImageProvider('assets/images/approve.png');
    }
    final comfortaLogo =
        await _loadImageProvider('assets/logo/comforta_logo.png');
    final superfitLogo =
        await _loadImageProvider('assets/logo/superfit_logo.png');
    final isleepLogo = await _loadImageProvider('assets/logo/isleep_logo.png');

    final List<pw.ImageProvider?> otherLogos = [
      sleepSpaLogo,
      springAirLogo,
      therapedicLogo,
      comfortaLogo,
      superfitLogo,
      isleepLogo,
    ];

    // Hitung subtotal dan PPN dari grandTotal
    final subtotal = ((grandTotal / 1.11) * 100).roundToDouble() /
        100; // Subtotal sebelum PPN (dibulatkan 2 desimal)
    final ppn = ((grandTotal - subtotal) * 100).roundToDouble() /
        100; // PPN (dibulatkan 2 desimal)
    final grandTotalWithPPN = grandTotal;
    // Hitung total EUP semua item (untuk proporsi harga net)
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    final totalEup = selectedItems.fold<double>(
        0.0, (sum, item) => sum + (item.netPrice * item.quantity));

    final bool isPaid = grandTotal - paymentAmount <= 0;

    // Use local Inter font from assets for offline-safe PDF generation
    final interData =
        await rootBundle.load('assets/fonts/Inter-VariableFont_opsz,wght.ttf');
    final font = pw.Font.ttf(interData);

    // Try to load bold font separately, fallback to regular font if not available
    pw.Font boldFont = font;
    try {
      final boldFontData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      boldFont = pw.Font.ttf(boldFontData);
    } catch (e) {
      // If Inter-Bold.ttf doesn't exist, try Inter_18pt-Bold.ttf
      try {
        final boldFontData =
            await rootBundle.load('assets/fonts/Inter_18pt-Bold.ttf');
        boldFont = pw.Font.ttf(boldFontData);
      } catch (e2) {
        // Fallback to regular font if bold font not available
        boldFont = font;
      }
    }

    // Load watermark image berdasarkan status
    pw.Widget? watermarkWidget;
    if (approvalData != null) {
      watermarkWidget = await _buildImageWatermark(
          isAllApproved: _isAllApproved(approvalData));
    } else if (isPaid) {
      watermarkWidget = await _buildImageWatermark(isAllApproved: true);
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          buildBackground: (pw.Context context) {
            return watermarkWidget ?? pw.SizedBox();
          },
        ),
        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return _buildHeader(sleepCenterLogo, otherLogos, orderLetterNo,
                orderLetterStatus, orderDate, workPlaceName);
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Dokumen ini dicetak pada: ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
              ),
              pw.Text(
                "Halaman ${context.pageNumber} dari ${context.pagesCount}",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          _buildCustomerAndOrderInfo(
            customerName: customerName,
            customerAddress: customerAddress,
            shippingAddress: shippingAddress,
            phoneNumber: phoneNumber,
            email: email ?? '-',
            spNumber: orderLetterNo ??
                'SP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            deliveryDate: deliveryDate,
            orderDate: orderDate,
            shipToName: shipToName,
          ),
          pw.SizedBox(height: 12),
          _buildItemsTable(cartItems, subtotal, totalEup,
              orderLetterExtendedAmount: orderLetterExtendedAmount,
              discountData: discountData,
              pricingData: pricingData,
              showApprovalColumn: showApprovalColumn),
          pw.SizedBox(height: 8),
          _buildNotesAndTotals(
            keterangan: keterangan ?? '-',
            subtotal: subtotal,
            ppn: ppn,
            grandTotal: grandTotalWithPPN,
            paymentMethod: paymentMethod,
            paymentAmount: paymentAmount,
            repaymentDate: repaymentDate,
          ),
          pw.SizedBox(height: 10),
          // Add approval table if needed
          if (showApprovalColumn) ...[
            _buildApprovalTable(approvalData, approveStamp),
            pw.SizedBox(height: 10),
          ],
          _buildTermsAndSignatureSection(
              customerName, salesName ?? "NAMA SALES", spgCode),
        ],
      ),
    );
    return pdf.save();
  }

  /// Cek apakah semua approval sudah selesai.
  static bool _isAllApproved(List<Map<String, dynamic>>? approvalData) {
    if (approvalData == null || approvalData.isEmpty) return false;
    return approvalData.every((approval) => approval['approved'] == true);
  }

  /// Membuat watermark dengan gambar PAID atau UNPAID pada PDF.
  static Future<pw.Widget> _buildImageWatermark(
      {bool isAllApproved = false}) async {
    try {
      // Load gambar dari assets berdasarkan status
      final String assetPath = isAllApproved
          ? 'assets/images/paid.png'
          : 'assets/images/approval.png';

      final ByteData imageData = await rootBundle.load(assetPath);
      final Uint8List imageBytes = imageData.buffer.asUint8List();
      final pw.ImageProvider imageProvider = pw.MemoryImage(imageBytes);

      return pw.Center(
        child: pw.Transform.rotate(
          angle: 0.785, // 45 degrees rotation
          child: pw.Opacity(
            opacity: 0.10,
            child: pw.Image(
              imageProvider,
              width: 300,
              height: 300,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    } catch (e) {
      // Fallback ke text watermark jika gambar gagal dimuat
      return pw.Center(
        child: pw.Transform.rotate(
          angle: 0.785,
          child: pw.Text(
            isAllApproved ? 'PAID' : 'UNPAID',
            style: pw.TextStyle(
              fontSize: 120,
              color: PdfColor(
                isAllApproved
                    ? PdfColors.green300.red
                    : PdfColors.orange300.red,
                isAllApproved
                    ? PdfColors.green300.green
                    : PdfColors.orange300.green,
                isAllApproved
                    ? PdfColors.green300.blue
                    : PdfColors.orange300.blue,
                0.10,
              ),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  /// Load image provider dari asset untuk logo.
  static Future<pw.ImageProvider?> _loadImageProvider(String path) async {
    try {
      final ByteData byteData = await rootBundle.load(path);
      return pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      // logger.e('Gagal memuat aset gambar: $path. Error: $e');
      return null;
    }
  }

  /// Build header PDF dengan logo dan work place name.
  static pw.Widget _buildHeader(
      pw.ImageProvider? sleepCenterLogo,
      List<pw.ImageProvider?> otherLogos,
      String? orderLetterNo,
      String? orderLetterStatus,
      String? orderLetterDate,
      String? workPlaceName) {
    return pw.Column(
      children: [
        if (sleepCenterLogo != null)
          pw.Container(
            height: 70,
            child: pw.Image(
              sleepCenterLogo,
            ),
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center, // Logo di tengah
          children: otherLogos
              .where((logo) => logo != null)
              .map((logo) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 5),
                    child: pw.Container(
                      height: 70,
                      child: pw.Image(logo!),
                    ),
                  ))
              .toList(),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SHOWROOM/PAMERAN: ${workPlaceName ?? 'SLEEP CENTER'}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Text(
                'TANGGAL PEMBELIAN: ${orderLetterDate ?? _formatSimpleDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Divider(color: PdfColors.black, thickness: 1.5),
        pw.SizedBox(height: 5),
      ],
    );
  }

  /// Build info customer dan order.
  static pw.Widget _buildCustomerAndOrderInfo({
    required String customerName,
    required String customerAddress,
    required String shippingAddress,
    required String phoneNumber,
    required String email,
    required String spNumber,
    required String deliveryDate,
    String? orderDate,
    String? shipToName,
  }) {
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
              _buildInfoTableRow('Nama Customer', customerName),
              _buildInfoTableRow('Alamat Customer', customerAddress),
              _buildInfoTableRow('Nama Penerima', shipToName ?? customerName),
              _buildInfoTableRow('Alamat Pengiriman', shippingAddress),
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
              _buildInfoTableRow('No. SP.', spNumber),
              _buildInfoTableRow('Tgl Kirim', deliveryDate),
              _buildInfoTableRow('Telepon', phoneNumber),
              _buildInfoTableRow('Email', email),
            ],
          ),
        ),
      ],
    );
  }

  /// Build satu baris info pada tabel info customer/order.
  static pw.TableRow _buildInfoTableRow(String label, String value) {
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

  /// Build approval table with stamps and names
  static pw.Widget _buildApprovalTable(List<Map<String, dynamic>>? approvalData,
      pw.ImageProvider? approveStamp) {
    if (approvalData == null || approvalData.isEmpty || approveStamp == null) {
      return pw.SizedBox.shrink();
    }

    // Group approvals by level and get unique levels
    final Map<String, List<Map<String, dynamic>>> approvalsByLevel = {};

    for (final approval in approvalData) {
      final level = approval['approver_level'] ?? 'Unknown';
      if (!approvalsByLevel.containsKey(level)) {
        approvalsByLevel[level] = [];
      }
      approvalsByLevel[level]!.add(approval);
    }

    // Create table rows for each approval level
    final List<pw.Widget> approvalColumns = [];

    approvalsByLevel.forEach((level, approvals) {
      // Check if this level has been approved
      final approvedApproval = approvals.firstWhere(
        (approval) => approval['approved'] == true,
        orElse: () => {},
      );

      // Check if approved
      final bool isApproved =
          approvedApproval.isNotEmpty && approvedApproval['approved'] == true;

      // Get approver name (from approved approval or first entry)
      final approverName = isApproved
          ? (approvedApproval['approver_name'] ?? 'Unknown')
          : (approvals.first['approver_name'] ?? 'Pending');

      // Map level names for PDF display only
      String displayLevel = level;
      switch (level.toLowerCase()) {
        case 'user':
          displayLevel = 'SC';
          break;
        case 'direct leader':
          displayLevel = 'Supervisor';
          break;
        case 'indirect leader':
          displayLevel = 'RSM';
          break;
        case 'controller':
          displayLevel = 'Controller';
          break;
        case 'analyst':
          displayLevel = 'Analyst';
          break;
        default:
          displayLevel = level; // Keep original if not in mapping
      }

      approvalColumns.add(
        pw.Container(
          width: 80,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // Level name at top
              pw.Text(
                displayLevel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              // Approval stamp in middle - ONLY show if approved
              pw.SizedBox(
                width: 30,
                height: 30,
                child: isApproved
                    ? pw.Image(approveStamp)
                    : pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.orange,
                            width: 1,
                          ),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'PENDING',
                            style: pw.TextStyle(
                              fontSize: 5,
                              color: PdfColors.orange,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(height: 4),
              // Approver name at bottom
              pw.Text(
                approverName,
                style: pw.TextStyle(
                  fontSize: 7,
                  color: isApproved ? PdfColors.black : PdfColors.grey600,
                ),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ],
          ),
        ),
      );
    });

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'APPROVAL',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: approvalColumns,
          ),
        ],
      ),
    );
  }

  /// Build tabel item pesanan.
  static pw.Widget _buildItemsTable(
      List<CartEntity> items, double subtotal, double totalEup,
      {double? orderLetterExtendedAmount,
      List<Map<String, dynamic>>? discountData,
      Map<String, List<Map<String, dynamic>>>? pricingData,
      bool showApprovalColumn = false}) {
    const defaultHeaders = [
      'BRAND',
      'ORDER',
      'NAMA BARANG',
      'QTY',
      'PRICELIST',
      'DISCOUNT',
      'HARGA TOTAL'
    ];

    final bool useApprovalLayout =
        showApprovalColumn && pricingData != null && pricingData.isNotEmpty;

    final headers = useApprovalLayout
        ? [
            'BRAND',
            'ORDER',
            'NAMA BARANG',
            'QTY',
            'PRICELIST',
            'END USER PRICE',
            'DISCOUNT',
            'HARGA TOTAL'
          ]
        : defaultHeaders;

    final Map<String, List<Map<String, dynamic>>> pricingQueues = {};
    if (pricingData != null) {
      for (final entry in pricingData.entries) {
        pricingQueues[entry.key] =
            entry.value.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    String pricingKey(String type, String name, String size) =>
        '${type.toLowerCase()}|${name.trim()}|${size.trim()}';

    Map<String, dynamic>? getPricing(String type, String name, String size) {
      final key = pricingKey(type, name, size);
      final queue = pricingQueues[key];
      if (queue == null || queue.isEmpty) return null;
      return queue.removeAt(0);
    }

    final List<pw.TableRow> tableRows = [];

    tableRows.add(
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: headers.map((header) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              header,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );

    int itemNumber = 1;

    for (var item in items) {
      final product = item.product;
      final productKey = '${product.kasur}_${product.ukuran}';

      final kasurPricing = getPricing('kasur', product.kasur, product.ukuran);
      final double? pricingKasurUnit =
          (kasurPricing?['unit_price_per_unit'] as num?)?.toDouble();
      final double? pricingKasurCustomer =
          (kasurPricing?['customer_price_per_unit'] as num?)?.toDouble();
      final double? pricingKasurNet =
          (kasurPricing?['net_price_per_unit'] as num?)?.toDouble();
      final int? kasurDetailId = (kasurPricing?['detail_id'] as num?)?.toInt();
      final bool kasurHasExplicitCustomerPrice =
          (kasurPricing?['has_customer_price'] as bool?) ?? false;

      if (useApprovalLayout) {
        final double unitPricePerUnit = pricingKasurUnit ?? product.plKasur;
        final double customerPricePerUnit =
            pricingKasurCustomer ?? product.eupKasur;
        final double netPricePerUnit = pricingKasurNet ?? item.netPrice;
        final double kasurPricelist = unitPricePerUnit * item.quantity;
        final double kasurCustomer = customerPricePerUnit * item.quantity;
        final double kasurNet = netPricePerUnit * item.quantity;
        final double kasurDiscount = kasurCustomer - kasurNet;
        final bool hasKasurCustomerAmount = kasurCustomer > 0;
        final bool showKasurDiscountDetails = hasKasurCustomerAmount &&
            kasurHasExplicitCustomerPrice &&
            showApprovalColumn;
        final pw.Widget kasurDiscountCell = hasKasurCustomerAmount
            ? _buildDiscountCell(kasurDiscount, kasurDetailId ?? product.id,
                productKey, discountData,
                align: pw.TextAlign.right,
                showApprovalColumn: showKasurDiscountDetails)
            : _buildTableCell('0', align: pw.TextAlign.right);

        tableRows.add(pw.TableRow(children: [
          _buildTableCell(_getBrandAbbreviation(product.brand),
              align: pw.TextAlign.center),
          _buildTableCell((itemNumber++).toString(),
              align: pw.TextAlign.center),
          _buildTableCell('${product.kasur} ${product.ukuran}'),
          _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
          _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
              align: pw.TextAlign.right),
          _buildTableCell(
              hasKasurCustomerAmount
                  ? FormatHelper.formatCurrency(kasurCustomer)
                  : '0',
              align: pw.TextAlign.right),
          kasurDiscountCell,
          _buildTableCell(FormatHelper.formatCurrency(kasurNet),
              align: pw.TextAlign.right),
        ]));
      } else if (orderLetterExtendedAmount != null &&
          orderLetterExtendedAmount > 0) {
        double kasurPricelistPerUnit = pricingKasurUnit ??
            _calculateOriginalPricelistByProductKey(
              item.netPrice,
              productKey,
              discountData,
            );
        if (kasurPricelistPerUnit == item.netPrice) {
          kasurPricelistPerUnit = product.plKasur;
        }

        final double kasurNetPerUnit = pricingKasurNet ?? item.netPrice;
        final double kasurPricelist = kasurPricelistPerUnit * item.quantity;
        final double kasurNet = kasurNetPerUnit * item.quantity;
        final double kasurDiscount = kasurPricelist - kasurNet;

        tableRows.add(pw.TableRow(children: [
          _buildTableCell(_getBrandAbbreviation(product.brand),
              align: pw.TextAlign.center),
          _buildTableCell((itemNumber++).toString(),
              align: pw.TextAlign.center),
          _buildTableCell('${product.kasur} ${product.ukuran}'),
          _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
          _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
              align: pw.TextAlign.right),
          _buildDiscountCell(kasurDiscount, null, productKey, discountData,
              align: pw.TextAlign.right,
              showApprovalColumn: showApprovalColumn),
          _buildTableCell(FormatHelper.formatCurrency(kasurNet),
              align: pw.TextAlign.right),
        ]));
      } else {
        final double kasurPricelistPerUnit =
            pricingKasurUnit ?? product.plKasur;
        final double kasurNetPerUnit = pricingKasurNet ?? item.netPrice;
        final double kasurPricelist = kasurPricelistPerUnit * item.quantity;
        final double kasurNet = kasurNetPerUnit * item.quantity;
        final double kasurDiscount = kasurPricelist - kasurNet;

        tableRows.add(pw.TableRow(children: [
          _buildTableCell(_getBrandAbbreviation(product.brand),
              align: pw.TextAlign.center),
          _buildTableCell((itemNumber++).toString(),
              align: pw.TextAlign.center),
          _buildTableCell('${product.kasur} ${product.ukuran}'),
          _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
          _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
              align: pw.TextAlign.right),
          _buildDiscountCell(kasurDiscount, null, productKey, discountData,
              align: pw.TextAlign.right,
              showApprovalColumn: showApprovalColumn),
          _buildTableCell(FormatHelper.formatCurrency(kasurNet),
              align: pw.TextAlign.right),
        ]));
      }

      if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan) {
        if (useApprovalLayout) {
          final divanPricing =
              getPricing('divan', product.divan, product.ukuran);
          final double unitPricePerUnit =
              (divanPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plDivan;
          final double customerPricePerUnit =
              (divanPricing?['customer_price_per_unit'] as num?)?.toDouble() ??
                  product.eupDivan;
          final double netPricePerUnit =
              (divanPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (customerPricePerUnit > 0 ? customerPricePerUnit : 0);
          final bool divanHasExplicitCustomerPrice =
              (divanPricing?['has_customer_price'] as bool?) ?? false;
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final double divanQty =
              (divanPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          final double divanPricelist = unitPricePerUnit * divanQty;
          final double divanCustomer = customerPricePerUnit * divanQty;
          final double divanNet = netPricePerUnit * divanQty;
          final double divanDiscount = divanCustomer - divanNet;
          final bool hasDivanCustomerAmount = divanCustomer > 0;
          final bool showDivanDiscountDetails = hasDivanCustomerAmount &&
              divanHasExplicitCustomerPrice &&
              showApprovalColumn;
          final pw.Widget divanDiscountCell = hasDivanCustomerAmount
              ? _buildDiscountCell(
                  divanDiscount, kasurDetailId, null, discountData,
                  align: pw.TextAlign.right,
                  showApprovalColumn: showDivanDiscountDetails)
              : _buildTableCell('0', align: pw.TextAlign.right);

          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.divan),
            _buildTableCell(divanQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(divanPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(
                divanCustomer > 0
                    ? FormatHelper.formatCurrency(divanCustomer)
                    : '0',
                align: pw.TextAlign.right),
            divanDiscountCell,
            _buildTableCell(FormatHelper.formatCurrency(divanNet),
                align: pw.TextAlign.right),
          ]));
        } else {
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final divanPricing =
              getPricing('divan', product.divan, product.ukuran);
          final double unitPricePerUnit =
              (divanPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plDivan;
          final double netPricePerUnit =
              (divanPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (product.eupDivan > 0 ? product.eupDivan : product.plDivan);
          final double divanQty =
              (divanPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          double divanPricelist = unitPricePerUnit * divanQty;
          double divanNet = netPricePerUnit * divanQty;
          double divanDiscount = divanPricelist - divanNet;
          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.divan),
            _buildTableCell(divanQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(divanPricelist),
                align: pw.TextAlign.right),
            _buildDiscountCell(divanDiscount, null, null, discountData,
                align: pw.TextAlign.right,
                showApprovalColumn: showApprovalColumn),
            _buildTableCell(FormatHelper.formatCurrency(divanNet),
                align: pw.TextAlign.right),
          ]));
        }
      }
      if (product.headboard.isNotEmpty &&
          product.headboard != AppStrings.noHeadboard) {
        if (useApprovalLayout) {
          final headboardPricing =
              getPricing('headboard', product.headboard, product.ukuran);
          final double unitPricePerUnit =
              (headboardPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plHeadboard;
          final double customerPricePerUnit =
              (headboardPricing?['customer_price_per_unit'] as num?)
                      ?.toDouble() ??
                  product.eupHeadboard;
          final double netPricePerUnit =
              (headboardPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (customerPricePerUnit > 0 ? customerPricePerUnit : 0);
          final bool headboardHasExplicitCustomerPrice =
              (headboardPricing?['has_customer_price'] as bool?) ?? false;
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final double headboardQty =
              (headboardPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          final double headboardPricelist = unitPricePerUnit * headboardQty;
          final double headboardCustomer = customerPricePerUnit * headboardQty;
          final double headboardNet = netPricePerUnit * headboardQty;
          final double headboardDiscount = headboardCustomer - headboardNet;
          final bool hasHeadboardCustomerAmount = headboardCustomer > 0;
          final bool showHeadboardDiscountDetails =
              hasHeadboardCustomerAmount &&
                  headboardHasExplicitCustomerPrice &&
                  showApprovalColumn;
          final pw.Widget headboardDiscountCell = hasHeadboardCustomerAmount
              ? _buildDiscountCell(
                  headboardDiscount, kasurDetailId, null, discountData,
                  align: pw.TextAlign.right,
                  showApprovalColumn: showHeadboardDiscountDetails)
              : _buildTableCell('0', align: pw.TextAlign.right);

          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.headboard),
            _buildTableCell(headboardQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(headboardPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(
                headboardCustomer > 0
                    ? FormatHelper.formatCurrency(headboardCustomer)
                    : '0',
                align: pw.TextAlign.right),
            headboardDiscountCell,
            _buildTableCell(FormatHelper.formatCurrency(headboardNet),
                align: pw.TextAlign.right),
          ]));
        } else {
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final headboardPricing =
              getPricing('headboard', product.headboard, product.ukuran);
          final double unitPricePerUnit =
              (headboardPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plHeadboard;
          final double netPricePerUnit =
              (headboardPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (product.eupHeadboard > 0
                      ? product.eupHeadboard
                      : product.plHeadboard);
          final double headboardQty =
              (headboardPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          double headboardPricelist = unitPricePerUnit * headboardQty;
          double headboardNet = netPricePerUnit * headboardQty;
          double headboardDiscount = headboardPricelist - headboardNet;
          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.headboard),
            _buildTableCell(headboardQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(headboardPricelist),
                align: pw.TextAlign.right),
            _buildDiscountCell(headboardDiscount, null, null, discountData,
                align: pw.TextAlign.right,
                showApprovalColumn: showApprovalColumn),
            _buildTableCell(FormatHelper.formatCurrency(headboardNet),
                align: pw.TextAlign.right),
          ]));
        }
      }
      if (product.sorong.isNotEmpty && product.sorong != AppStrings.noSorong) {
        if (useApprovalLayout) {
          final sorongPricing =
              getPricing('sorong', product.sorong, product.ukuran);
          final double unitPricePerUnit =
              (sorongPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plSorong;
          final double customerPricePerUnit =
              (sorongPricing?['customer_price_per_unit'] as num?)?.toDouble() ??
                  product.eupSorong;
          final double netPricePerUnit =
              (sorongPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (customerPricePerUnit > 0 ? customerPricePerUnit : 0);
          final bool sorongHasExplicitCustomerPrice =
              (sorongPricing?['has_customer_price'] as bool?) ?? false;
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final double sorongQty =
              (sorongPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          final double sorongPricelist = unitPricePerUnit * sorongQty;
          final double sorongCustomer = customerPricePerUnit * sorongQty;
          final double sorongNet = netPricePerUnit * sorongQty;
          final double sorongDiscount = sorongCustomer - sorongNet;
          final bool hasSorongCustomerAmount = sorongCustomer > 0;
          final bool showSorongDiscountDetails = hasSorongCustomerAmount &&
              sorongHasExplicitCustomerPrice &&
              showApprovalColumn;
          final pw.Widget sorongDiscountCell = hasSorongCustomerAmount
              ? _buildDiscountCell(
                  sorongDiscount, kasurDetailId, null, discountData,
                  align: pw.TextAlign.right,
                  showApprovalColumn: showSorongDiscountDetails)
              : _buildTableCell('0', align: pw.TextAlign.right);

          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.sorong),
            _buildTableCell(sorongQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(sorongPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(
                sorongCustomer > 0
                    ? FormatHelper.formatCurrency(sorongCustomer)
                    : '0',
                align: pw.TextAlign.right),
            sorongDiscountCell,
            _buildTableCell(FormatHelper.formatCurrency(sorongNet),
                align: pw.TextAlign.right),
          ]));
        } else {
          // Use qty from pricingData if available (already aggregated), otherwise use item.quantity
          final sorongPricing =
              getPricing('sorong', product.sorong, product.ukuran);
          final double unitPricePerUnit =
              (sorongPricing?['unit_price_per_unit'] as num?)?.toDouble() ??
                  product.plSorong;
          final double netPricePerUnit =
              (sorongPricing?['net_price_per_unit'] as num?)?.toDouble() ??
                  (product.eupSorong > 0
                      ? product.eupSorong
                      : product.plSorong);
          final double sorongQty =
              (sorongPricing?['quantity'] as num?)?.toDouble() ??
                  item.quantity.toDouble();

          double sorongPricelist = unitPricePerUnit * sorongQty;
          double sorongNet = netPricePerUnit * sorongQty;
          double sorongDiscount = sorongPricelist - sorongNet;
          tableRows.add(pw.TableRow(children: [
            _buildTableCell('', align: pw.TextAlign.center),
            _buildTableCell(''),
            _buildTableCell(product.sorong),
            _buildTableCell(sorongQty.toInt().toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(sorongPricelist),
                align: pw.TextAlign.right),
            _buildDiscountCell(sorongDiscount, null, null, discountData,
                align: pw.TextAlign.right,
                showApprovalColumn: showApprovalColumn),
            _buildTableCell(FormatHelper.formatCurrency(sorongNet),
                align: pw.TextAlign.right),
          ]));
        }
      }

      if (product.bonus.isNotEmpty) {
        for (var bonus in product.bonus) {
          final bonusQuantity = bonus.quantity;
          final String zeroPrice = FormatHelper.formatCurrency(0);

          String bonusName = bonus.name;
          if (bonus.takeAway == true) {
            bonusName = '${bonus.name} (BONUS - TAKE AWAY)';
          } else {
            bonusName = '${bonus.name} (BONUS)';
          }

          final bonusRowChildren = useApprovalLayout
              ? [
                  _buildTableCell('', align: pw.TextAlign.center),
                  _buildTableCell(''),
                  _buildTableCell(bonusName),
                  _buildTableCell(bonusQuantity.toString(),
                      align: pw.TextAlign.center),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                ]
              : [
                  _buildTableCell('', align: pw.TextAlign.center),
                  _buildTableCell(''),
                  _buildTableCell(bonusName),
                  _buildTableCell(bonusQuantity.toString(),
                      align: pw.TextAlign.center),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                  _buildTableCell(zeroPrice, align: pw.TextAlign.right),
                ];

          tableRows.add(pw.TableRow(children: bonusRowChildren));
        }
      }
    }

    final columnWidths = useApprovalLayout
        ? {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(0.6),
            2: const pw.FlexColumnWidth(3.0),
            3: const pw.FlexColumnWidth(0.6),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(1.2),
            7: const pw.FlexColumnWidth(1.2),
          }
        : {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(0.6),
            2: const pw.FlexColumnWidth(3.2),
            3: const pw.FlexColumnWidth(0.6),
            4: const pw.FlexColumnWidth(1.3),
            5: const pw.FlexColumnWidth(1.3),
            6: const pw.FlexColumnWidth(1.3),
          };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: columnWidths,
      children: tableRows,
    );
  }

  /// Calculate original pricelist from unit_price using product key (desc_1 + desc_2)
  static double _calculateOriginalPricelistByProductKey(double unitPrice,
      String productKey, List<Map<String, dynamic>>? discountData) {
    if (discountData == null || discountData.isEmpty) {
      return unitPrice;
    }

    // Find discounts for this specific product key
    final itemDiscounts = discountData.where((discount) {
      final discountProductKey = discount['product_key'];
      return discountProductKey == productKey;
    }).toList();

    if (itemDiscounts.isEmpty) {
      return unitPrice;
    }

    // Sort discounts by level to apply them in correct order
    itemDiscounts.sort((a, b) =>
        (a['approver_level_id'] ?? 0).compareTo(b['approver_level_id'] ?? 0));

    double currentPrice = unitPrice;

    for (final discount in itemDiscounts) {
      final discountPercentage = (discount['discount'] is String)
          ? double.tryParse(discount['discount']) ?? 0.0
          : (discount['discount'] ?? 0.0).toDouble();

      if (discountPercentage > 0) {
        // Add back the discount: current_price / (1 - discount/100)
        currentPrice = currentPrice / (1 - discountPercentage / 100);
      }
    }

    return currentPrice;
  }

  /// Build satu cell pada tabel item.
  static pw.Widget _buildTableCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildDiscountCell(double totalDiscount, int? detailId,
      String? productKey, List<Map<String, dynamic>>? discountData,
      {pw.TextAlign align = pw.TextAlign.right,
      bool showApprovalColumn = false}) {
    // Get discount details for this product
    // Note: For accessories (divan/headboard/sorong), discount only exists for kasur
    // So we should use productKey to get discount details, not detailId
    List<String> discountDetails = [];
    if (discountData != null && discountData.isNotEmpty) {
      Iterable<Map<String, dynamic>> itemDiscounts = const [];

      // First try to find discount by detailId (for kasur items)
      if (detailId != null) {
        itemDiscounts = discountData.where((discount) =>
            (discount['order_letter_detail_id'] ?? discount['detail_id']) ==
            detailId);
      }

      // If not found by detailId, or if detailId is null, use productKey
      // This ensures accessories (divan/headboard/sorong) use kasur's discount
      if (itemDiscounts.isEmpty && productKey != null) {
        itemDiscounts = discountData.where((discount) {
          final discountProductKey = discount['product_key'] as String?;
          return discountProductKey == productKey;
        });
      }

      // Sort by approver_level_id to ensure consistent order
      final sortedDiscounts = itemDiscounts.toList()
        ..sort((a, b) => (a['approver_level_id'] ?? 0)
            .compareTo(b['approver_level_id'] ?? 0));

      // Extract discount percentages
      for (final discount in sortedDiscounts) {
        final discountPercentage = (discount['discount'] is String)
            ? double.tryParse(discount['discount']) ?? 0.0
            : (discount['discount'] ?? 0.0).toDouble();

        if (discountPercentage > 0) {
          // Format discount as percentage (if whole number, show as int, else with decimal)
          if (discountPercentage % 1 == 0) {
            discountDetails.add('${discountPercentage.toInt()}%');
          } else {
            discountDetails.add(
                '${discountPercentage.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}%');
          }
        }
      }
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: align == pw.TextAlign.right
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // Baris 1: Total discount
          pw.Text(
            FormatHelper.formatCurrency(totalDiscount),
            style: const pw.TextStyle(fontSize: 8),
            textAlign: align,
          ),
          // Baris 2: Detail discount (hanya untuk PDF approval)
          if (showApprovalColumn && discountDetails.isNotEmpty)
            pw.Text(
              discountDetails.join(' + '),
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
              textAlign: align,
            ),
        ],
      ),
    );
  }

  /// Build tabel keterangan dan total pembayaran.
  static pw.Widget _buildNotesAndTotals({
    required String keterangan,
    required double subtotal,
    required double ppn,
    required double grandTotal,
    required String paymentMethod,
    required double paymentAmount,
    required String repaymentDate,
  }) {
    final double sisaPembayaran = grandTotal - paymentAmount;

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
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
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Keterangan:',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    keterangan.isNotEmpty ? keterangan : "-",
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),
            pw.Column(
              children: [
                _buildTotalRow(
                    'Subtotal', FormatHelper.formatCurrency(subtotal)),
                _buildTotalRow('PPN 11%', FormatHelper.formatCurrency(ppn)),
                _buildTotalRow(
                    'Grand Total', FormatHelper.formatCurrency(grandTotal),
                    isBold: true),
                _buildTotalRow('Pembayaran ($paymentMethod)',
                    FormatHelper.formatCurrency(paymentAmount)),
                _buildTotalRow('Sisa Pembayaran',
                    FormatHelper.formatCurrency(sisaPembayaran),
                    isBold: true),
                _buildTotalRow('Tgl Pelunasan', repaymentDate),
              ],
            ),
          ],
        )
      ],
    );
  }

  /// Build satu baris total pada tabel total pembayaran.
  static pw.Widget _buildTotalRow(String label, String value,
      {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 0.5, color: PdfColors.black),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value.isNotEmpty ? value : '-',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  /// Build section tanda tangan pembeli dan sales.
  static pw.Widget _buildSignatureSection(
      String customerName, String salesName, String? spgCode) {
    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      child: pw.Row(
        children: [
          _buildSignatureBox('PEMBELI', customerName),
          _buildSignatureBoxWithSpgCode('SLEEP CONSULTANT', salesName, spgCode,
              borderLeft: true),
        ],
      ),
    );
  }

  /// Build box tanda tangan.
  static pw.Widget _buildSignatureBox(String title, String name,
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

  /// Build box tanda tangan dengan SPG code di baris terpisah.
  static pw.Widget _buildSignatureBoxWithSpgCode(
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
              children: [
                pw.Text('($name)', style: const pw.TextStyle(fontSize: 9)),
                if (spgCode != null && spgCode.isNotEmpty)
                  pw.Text('($spgCode)',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Convert brand name to abbreviation.
  static String _getBrandAbbreviation(String brand) {
    final brandLower = brand.toLowerCase();

    if (brandLower.contains('spring air')) {
      return 'SA';
    } else if (brandLower.contains('therapedic')) {
      return 'TH';
    } else if (brandLower.contains('comforta')) {
      return 'CF';
    } else if (brandLower.contains('sleep spa')) {
      return 'SS';
    } else if (brandLower.contains('superfit')) {
      return 'SF';
    } else if (brandLower.contains('isleep')) {
      return 'isleep';
    } else {
      // Fallback: return first 2 characters in uppercase
      return brand.length >= 2
          ? brand.substring(0, 2).toUpperCase()
          : brand.toUpperCase();
    }
  }

  /// Build first term with bold bank account numbers in list format.
  static pw.Widget _buildFirstTermWithBoldBank() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Pembayaran dianggap SAH hanya apabila sudah diterima di rekening perusahaan atas nama:",
          style: pw.TextStyle(fontSize: 7),
        ),
        pw.SizedBox(height: 2),
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "PT MASSINDO KARYA PRIMA",
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                "BANK BCA 066-328-8871",
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          "Pembayaran ke rekening lain tidak akan diakui sebagai pembayaran yang sah.",
          style: pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  /// Build syarat dan ketentuan pembelian beserta signature dalam satu kesatuan.
  static pw.Widget _buildTermsAndSignatureSection(
      String customerName, String salesName, String? spgCode) {
    final List<String> terms = [
      "Konsumen wajib melunasi 100% nilai pesanan sebelum melakukan pengiriman / penyerahan barang pesanan. Pelunasan dilakukan selambat-lambatnya 3 hari kerja sebelum jadwal pengiriman / penyerahan yang dijadwalkan.",
      "Barang yang sudah dipesan / dibeli, tidak dapat ditukar atau dikembalikan.",
      "Uang muka yang telah dibayarkan tidak dapat dikembalikan.",
      "Sleep Center berhak mengubah tanggal pengiriman dengan sebelumnya memberitahukan kepada konsumen.",
      "Surat Pesanan yang sudah lewat 3 (Tiga) bulan namun belum dikirim harus dilunasi jika tidak akan dianggap batal dan uang muka tidak dapat dikembalikan",
      "Apabila konsumen menunda pengiriman selama lebih dari 2 (Dua) Bulan dari tanggal kirim awal, SP dianggap batal dan uang muka tidak dapat dikembalikan",
      "Pembeli akan dikenakan biaya tambahan untuk pengiriman, pembongkaran, pengambilan furnitur dll yang disebabkan adanya kesulitan/ketidakcocokan penempatan furnitur di tempat atau ruangan yang dikehendaki oleh pembeli.",
      "Jika pengiriman dilakukan lebih dari 1 (Satu) kali, konsumen wajib melunasi pembelian sebelum pengiriman pertama.",
      "Untuk tipe dan ukuran khusus, pelunasan harus dilakukan saat pemesanan dan tidak dapat dibatalkan/diganti."
    ];

    return pw.Wrap(
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Syarat - Syarat Pembelian :',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            pw.SizedBox(height: 3),
            ...terms.asMap().entries.map((entry) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 1.5),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 12,
                      child: pw.Text(
                        '${entry.key + 1}.',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ),
                    pw.Expanded(
                      child: entry.key == 0
                          ? _buildFirstTermWithBoldBank()
                          : pw.Text(
                              entry.value,
                              style: pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.justify,
                            ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),
            _buildSignatureSection(customerName, salesName, spgCode),
          ],
        ),
      ],
    );
  }

  /// Format tanggal dd/MM/yyyy.
  static String _formatSimpleDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format tanggal dan jam dd/MM/yyyy HH:mm.
  static String _formatDateTime(DateTime date) {
    return '${_formatSimpleDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Simpan PDF ke device (Android/iOS).
  static Future<String> savePDFToDevice(Uint8List pdfBytes) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw Exception('Storage permission denied');
      }
      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'invoice_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // 📁 LOG: Tampilkan lokasi file PDF yang disimpan permanen
      if (kDebugMode) {
        print('💾 PDF Saved to Device Successfully!');
      }
      if (kDebugMode) {
        print('📄 File Name: $fileName');
      }
      if (kDebugMode) {
        print('📂 Full Path: $filePath');
      }
      if (kDebugMode) {
        print(
            '🗂️  ${Platform.isAndroid ? 'Android' : 'iOS'} Storage: ${directory.path}');
      }
      if (Platform.isMacOS || Platform.isIOS) {
        if (kDebugMode) {
          print('🍎 Finder: Cmd+Shift+G → ${directory.path}');
        }
        if (kDebugMode) {
          print('📱 iOS Files App: On My iPhone → [App Name] → Documents');
        }
      } else if (Platform.isAndroid) {
        if (kDebugMode) {
          print(
              '🤖 File Manager: Internal Storage → Android → data → [package] → files');
        }
      }

      return filePath;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share PDF ke aplikasi lain.
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    await sharePDFWithPosition(pdfBytes, fileName, null);
  }

  /// Share PDF ke aplikasi lain dengan positioning untuk iOS.
  static Future<void> sharePDFWithPosition(
    Uint8List pdfBytes,
    String fileName,
    Rect? sharePositionOrigin,
  ) async {
    try {
      final sanitizedFileName = _sanitizeFileName(fileName);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$sanitizedFileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(pdfBytes);

      // 📁 LOG: Tampilkan lokasi file PDF untuk debugging
      if (kDebugMode) {
        print('🔍 PDF Generated Successfully!');
      }
      if (kDebugMode) {
        print('📄 File Name: $fileName');
      }
      if (kDebugMode) {
        print('📂 Full Path: $tempPath');
      }
      if (kDebugMode) {
        print('🗂️  Temp Directory: ${tempDir.path}');
      }
      if (Platform.isMacOS || Platform.isIOS) {
        if (kDebugMode) {
          print('🍎 Finder: Cmd+Shift+G → ${tempDir.path}');
        }
      } else if (Platform.isAndroid) {
        if (kDebugMode) {
          print('🤖 File Manager: Navigate to temp directory');
        }
      }

      // Set default position if not provided (fallback for iOS)
      final defaultPosition =
          sharePositionOrigin ?? const Rect.fromLTWH(100, 100, 100, 100);

      await Share.shareXFiles(
        [XFile(tempPath, name: sanitizedFileName)],
        sharePositionOrigin: defaultPosition,
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }

  /// Print PDF langsung ke printer.
  static Future<void> printPDF(Uint8List pdfBytes, String fileName) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }
}
