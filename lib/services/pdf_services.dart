import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_constant.dart';
import '../core/utils/format_helper.dart';
import '../features/cart/domain/entities/cart_entity.dart';

/// Service untuk generate, simpan, dan share PDF checkout.
class PDFService {
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
    String? orderLetterNo,
    String? orderLetterStatus,
    String? orderLetterDate,
    List<Map<String, dynamic>>? approvalData,
    double? orderLetterExtendedAmount,
    double? orderLetterHargaAwal,
    String? shipToName,
    List<Map<String, dynamic>>? discountData,
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
    final subtotal = grandTotal * 0.89;
    final ppn = grandTotal - subtotal;
    // Hitung total EUP semua item (untuk proporsi harga net)
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    final totalEup = selectedItems.fold<double>(
        0.0, (sum, item) => sum + (item.netPrice * item.quantity));

    // --- PERUBAHAN 1: Tentukan kondisi lunas ---
    final bool isPaid = grandTotal - paymentAmount <= 0;

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

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
        // --- Akhir Perubahan ---

        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return _buildHeader(sleepCenterLogo, otherLogos, orderLetterNo,
                orderLetterStatus, orderLetterDate);
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
            shipToName: shipToName,
          ),
          pw.SizedBox(height: 12),
          _buildItemsTable(cartItems, subtotal, totalEup,
              orderLetterExtendedAmount: orderLetterExtendedAmount,
              discountData: discountData),
          pw.SizedBox(height: 8),
          _buildNotesAndTotals(
            keterangan: keterangan ?? '-',
            subtotal: subtotal,
            ppn: ppn,
            grandTotal: grandTotal,
            paymentMethod: paymentMethod,
            paymentAmount: paymentAmount,
            repaymentDate: repaymentDate,
          ),
          pw.SizedBox(height: 10),
          // _buildApprovalTable(approvalData),
          // pw.SizedBox(height: 10),
          _buildSignatureSection(customerName, salesName ?? "NAMA SALES"),
          pw.Spacer(),
          _buildTermsAndConditions(),
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

  /// Build header PDF dengan logo dan showroom.
  static pw.Widget _buildHeader(
      pw.ImageProvider? sleepCenterLogo,
      List<pw.ImageProvider?> otherLogos,
      String? orderLetterNo,
      String? orderLetterStatus,
      String? orderLetterDate) {
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
            pw.Text('SHOWROOM/PAMERAN: -',
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

  /// Build tabel item pesanan.
  static pw.Widget _buildItemsTable(
      List<CartEntity> items, double subtotal, double totalEup,
      {double? orderLetterExtendedAmount,
      List<Map<String, dynamic>>? discountData}) {
    const tableHeaders = [
      'ORDER',
      'NAMA BARANG',
      'QTY',
      'PRICELIST',
      'DISCOUNT',
      'HARGA TOTAL'
    ];
    final List<pw.TableRow> tableRows = [];

    tableRows.add(
      pw.TableRow(
        verticalAlignment: pw.TableCellVerticalAlignment.middle,
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: tableHeaders.map((header) {
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

      // Jika ada order letter extended amount, gunakan perhitungan yang sesuai
      if (orderLetterExtendedAmount != null && orderLetterExtendedAmount > 0) {
        // Calculate original pricelist from unit_price using discount data
        // Use product description as key (same format as order letter document)
        final productKey = '${product.kasur}_${product.ukuran}';

        double kasurPricelistPerUnit = _calculateOriginalPricelistByProductKey(
          item.netPrice,
          productKey,
          discountData,
        );

        // If no discount data found, use the original pricelist from product
        if (kasurPricelistPerUnit == item.netPrice) {
          kasurPricelistPerUnit = product.plKasur;
        }

        double kasurPricelist = kasurPricelistPerUnit * item.quantity;
        double kasurNet =
            item.netPrice * item.quantity; // Gunakan netPrice dari CartEntity
        double kasurDiscount = kasurPricelist - kasurNet;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell((itemNumber++).toString(),
                align: pw.TextAlign.center),
            _buildTableCell('${product.kasur} ${product.ukuran}'),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(kasurDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(kasurNet),
                align: pw.TextAlign.right),
          ],
        ));
      } else {
        // Logic lama untuk cart biasa
        double kasurPricelist = (product.plKasur) * item.quantity;
        double kasurNet = (item.netPrice * item.quantity) * 0.89;
        double kasurDiscount = kasurPricelist - kasurNet;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell((itemNumber++).toString(),
                align: pw.TextAlign.center),
            _buildTableCell('${product.kasur} ${product.ukuran}'),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(kasurDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(kasurNet),
                align: pw.TextAlign.right),
          ],
        ));
      }
      if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan) {
        double divanPricelist = (product.plDivan) * item.quantity;
        double divanEUP = (product.eupDivan) * item.quantity;
        double divanDiscount = divanEUP;
        double divanNet = divanPricelist - divanDiscount;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(product.divan),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(divanPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(divanDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(divanNet),
                align: pw.TextAlign.right),
          ],
        ));
      }
      if (product.headboard.isNotEmpty &&
          product.headboard != AppStrings.noHeadboard) {
        double headboardPricelist = (product.plHeadboard) * item.quantity;
        double headboardEUP = (product.eupHeadboard) * item.quantity;
        double headboardDiscount = headboardEUP;
        double headboardNet = headboardPricelist - headboardDiscount;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(product.headboard),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(headboardPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(headboardDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(headboardNet),
                align: pw.TextAlign.right),
          ],
        ));
      }
      if (product.sorong.isNotEmpty && product.sorong != AppStrings.noSorong) {
        double sorongPricelist = (product.plSorong) * item.quantity;
        double sorongEUP = (product.eupSorong) * item.quantity;
        double sorongDiscount = sorongEUP;
        double sorongNet = sorongPricelist - sorongDiscount;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(product.sorong),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(FormatHelper.formatCurrency(sorongPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(sorongDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(sorongNet),
                align: pw.TextAlign.right),
          ],
        ));
      }

      if (product.bonus.isNotEmpty) {
        for (var bonus in product.bonus) {
          final bonusQuantity = bonus.quantity * item.quantity;
          const String bonusPrice = "0";

          // Add take away indicator if applicable
          String bonusName = bonus.name;
          if (bonus.takeAway == true) {
            bonusName = '${bonus.name} (BONUS - TAKE AWAY)';
          } else {
            bonusName = '${bonus.name} (BONUS)';
          }

          tableRows.add(pw.TableRow(
            children: [
              _buildTableCell(''),
              _buildTableCell(bonusName),
              _buildTableCell(bonusQuantity.toString(),
                  align: pw.TextAlign.center),
              _buildTableCell(bonusPrice, align: pw.TextAlign.right),
              _buildTableCell(bonusPrice, align: pw.TextAlign.right),
              _buildTableCell(bonusPrice, align: pw.TextAlign.right),
            ],
          ));
        }
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(3.8),
        2: const pw.FlexColumnWidth(0.6),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
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

    // Apply each discount backward to get original price
    // If unit_price = original * (1 - disc1/100) * (1 - disc2/100) * (1 - disc3/100)
    // Then original = unit_price / ((1 - disc1/100) * (1 - disc2/100) * (1 - disc3/100))
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
      String customerName, String salesName) {
    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      child: pw.Row(
        children: [
          _buildSignatureBox('PEMBELI', customerName),
          _buildSignatureBox('SLEEP CONSULTANT', salesName, borderLeft: true),
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

  /// Build syarat dan ketentuan pembelian.
  static pw.Widget _buildTermsAndConditions() {
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
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Syarat - Syarat Pembelian :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
        pw.SizedBox(height: 3),
        pw.Column(
          children: terms.asMap().entries.map((entry) {
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
                    child: pw.Text(
                      entry.value,
                      style: const pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.justify,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
      print('💾 PDF Saved to Device Successfully!');
      print('📄 File Name: $fileName');
      print('📂 Full Path: $filePath');
      print(
          '🗂️  ${Platform.isAndroid ? 'Android' : 'iOS'} Storage: ${directory.path}');
      if (Platform.isMacOS || Platform.isIOS) {
        print('🍎 Finder: Cmd+Shift+G → ${directory.path}');
        print('📱 iOS Files App: On My iPhone → [App Name] → Documents');
      } else if (Platform.isAndroid) {
        print(
            '🤖 File Manager: Internal Storage → Android → data → [package] → files');
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
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(pdfBytes);

      // 📁 LOG: Tampilkan lokasi file PDF untuk debugging
      print('🔍 PDF Generated Successfully!');
      print('📄 File Name: $fileName');
      print('📂 Full Path: $tempPath');
      print('🗂️  Temp Directory: ${tempDir.path}');
      if (Platform.isMacOS || Platform.isIOS) {
        print('🍎 Finder: Cmd+Shift+G → ${tempDir.path}');
      } else if (Platform.isAndroid) {
        print('🤖 File Manager: Navigate to temp directory');
      }

      // Set default position if not provided (fallback for iOS)
      final defaultPosition =
          sharePositionOrigin ?? const Rect.fromLTWH(100, 100, 100, 100);

      await Share.shareXFiles(
        [XFile(tempPath)],
        sharePositionOrigin: defaultPosition,
      );
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }
}
