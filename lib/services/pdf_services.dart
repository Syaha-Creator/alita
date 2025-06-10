// File: lib/services/pdf_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_constant.dart';
import '../core/utils/format_helper.dart';
import '../core/utils/logger.dart';
import '../features/cart/domain/entities/cart_entity.dart';

class PDFService {
  /// Generate PDF dari data checkout
  static Future<Uint8List> generateCheckoutPDF({
    required List<CartEntity> cartItems,
    required double totalPrice,
    required String customerInfo,
    required String paymentMethod,
    required String shippingAddress,
    required String promoCode,
    required String notes,
  }) async {
    final pdf = pw.Document();

    // Load font (opsional untuk bahasa Indonesia)
    final font = await _loadFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(customerInfo, shippingAddress),
            pw.SizedBox(height: 20),
            _buildItemsTable(cartItems),
            pw.SizedBox(height: 20),
            _buildSummary(totalPrice, promoCode, paymentMethod),
            if (notes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildNotes(notes),
            ],
            pw.SizedBox(height: 30),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Load custom font (opsional)
  static Future<pw.Font?> _loadFont() async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      return pw.Font.ttf(fontData);
    } catch (e) {
      logger.e("❌ Error loading font: $e");
      return null;
    }
  }

  /// Build PDF header
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(AppPadding.p16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE CHECKOUT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Alita Pricelist',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.blue600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Tanggal: ${_formatDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Text(
                'Invoice #: INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customer information section
  static pw.Widget _buildCustomerInfo(
      String customerInfo, String shippingAddress) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(AppPadding.p16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMASI PELANGGAN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          if (customerInfo.isNotEmpty) ...[
            pw.Text('Nama: $customerInfo',
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 4),
          ],
          pw.Text(
            'Alamat Pengiriman:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(shippingAddress, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<CartEntity> cartItems) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETAIL PESANAN',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3), // NAMA BARANG
            1: const pw.FlexColumnWidth(1.5), // UKURAN
            2: const pw.FlexColumnWidth(2), // PRICE LIST
            3: const pw.FlexColumnWidth(1.5), // DISCOUNT
            4: const pw.FlexColumnWidth(2), // HARGA NET
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('NAMA BARANG', isHeader: true),
                _buildTableCell('UKURAN', isHeader: true),
                _buildTableCell('PRICE LIST', isHeader: true),
                _buildTableCell('DISCOUNT', isHeader: true),
                _buildTableCell('HARGA NET', isHeader: true),
              ],
            ),
            // Items
            ...cartItems.expand((item) => _buildItemRows(item)),
            // Bonus section
            ..._buildBonusRows(cartItems),
            // Total section
            ..._buildTotalRows(cartItems),
          ],
        ),
      ],
    );
  }

  /// Build rows for each cart item with breakdown
  static List<pw.TableRow> _buildItemRows(CartEntity item) {
    List<pw.TableRow> rows = [];
    final product = item.product;
    final discounts = _formatDiscounts(item);
    final discountText = discounts.isNotEmpty ? discounts.join(' + ') : '-';

    // Main product row (Kasur)
    if (product.kasur.isNotEmpty && product.kasur != "Tanpa Kasur") {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('${product.kasur} (x${item.quantity})'),
          _buildTableCell(product.ukuran),
          _buildTableCell(
              FormatHelper.formatCurrency(product.eupKasur * item.quantity)),
          _buildTableCell(discountText),
          _buildTableCell(
            FormatHelper.formatCurrency(_calculateKasurNetPrice(item)),
            isAmount: true,
          ),
        ],
      ));
    }

    // Divan row (if exists and not "Tanpa Divan")
    if (product.divan.isNotEmpty && product.divan != "Tanpa Divan") {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('${product.divan} (x${item.quantity})'),
          _buildTableCell(product.ukuran),
          _buildTableCell(
              FormatHelper.formatCurrency(product.eupDivan * item.quantity)),
          _buildTableCell('-'),
          _buildTableCell(
            FormatHelper.formatCurrency(product.eupDivan * item.quantity),
            isAmount: true,
          ),
        ],
      ));
    }

    // Headboard row (if exists and not "Tanpa Headboard")
    if (product.headboard.isNotEmpty &&
        product.headboard != "Tanpa Headboard") {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('${product.headboard} (x${item.quantity})'),
          _buildTableCell(product.ukuran),
          _buildTableCell(FormatHelper.formatCurrency(
              product.eupHeadboard * item.quantity)),
          _buildTableCell('-'),
          _buildTableCell(
            FormatHelper.formatCurrency(product.eupHeadboard * item.quantity),
            isAmount: true,
          ),
        ],
      ));
    }

    // Sorong row (if exists and not "Tanpa Sorong")
    if (product.sorong.isNotEmpty && product.sorong != "Tanpa Sorong") {
      rows.add(pw.TableRow(
        children: [
          _buildTableCell('${product.sorong} (x${item.quantity})'),
          _buildTableCell(product.ukuran),
          _buildTableCell(FormatHelper.formatCurrency(
              0.0)), // Assuming sorong price is included
          _buildTableCell('-'),
          _buildTableCell(FormatHelper.formatCurrency(0.0), isAmount: true),
        ],
      ));
    }

    return rows;
  }

  /// Build bonus rows
  static List<pw.TableRow> _buildBonusRows(List<CartEntity> cartItems) {
    List<pw.TableRow> bonusRows = [];

    // Collect all bonuses from all items
    List<String> allBonuses = [];
    for (var item in cartItems) {
      for (var bonus in item.product.bonus) {
        if (bonus.name.isNotEmpty && bonus.quantity > 0) {
          allBonuses.add('${bonus.quantity}x ${bonus.name}');
        }
      }
    }

    if (allBonuses.isNotEmpty) {
      bonusRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple50),
          children: [
            _buildTableCell('BONUS', isHeader: true),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell(''),
            _buildTableCell(''),
          ],
        ),
      );

      for (var bonus in allBonuses) {
        bonusRows.add(
          pw.TableRow(
            children: [
              _buildTableCell(bonus),
              _buildTableCell('-'),
              _buildTableCell('-'),
              _buildTableCell('-'),
              _buildTableCell('-'),
            ],
          ),
        );
      }
    }

    return bonusRows;
  }

  /// Build total rows
  static List<pw.TableRow> _buildTotalRows(List<CartEntity> cartItems) {
    double totalBiayaKirim = 0.0; // Could be calculated or input
    double grandTotal = cartItems.fold(
        0.0, (sum, item) => sum + (item.netPrice * item.quantity));

    return [
      // Total row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.green50),
        children: [
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell('TOTAL', isHeader: true),
          _buildTableCell(
            FormatHelper.formatCurrency(grandTotal),
            isAmount: true,
            isHeader: true,
          ),
        ],
      ),
      // Biaya Kirim row
      pw.TableRow(
        children: [
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell('BIAYA KIRIM', isHeader: true),
          _buildTableCell(
            FormatHelper.formatCurrency(totalBiayaKirim),
            isAmount: true,
          ),
        ],
      ),
      // Grand Total row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue50),
        children: [
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell(''),
          _buildTableCell('GRAND TOTAL', isHeader: true),
          _buildTableCell(
            FormatHelper.formatCurrency(grandTotal + totalBiayaKirim),
            isAmount: true,
            isHeader: true,
          ),
        ],
      ),
    ];
  }

  /// Calculate kasur net price with discounts applied
  static double _calculateKasurNetPrice(CartEntity item) {
    double basePrice = item.product.eupKasur * item.quantity;

    // Apply discounts
    for (var discount in item.discountPercentages) {
      if (discount > 0) {
        basePrice = basePrice * (1 - discount / 100);
      }
    }

    // Apply edit popup discount
    if (item.editPopupDiscount > 0) {
      basePrice = basePrice * (1 - item.editPopupDiscount / 100);
    }

    return basePrice;
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isAmount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(AppPadding.p8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isAmount ? PdfColors.green800 : PdfColors.black,
        ),
        textAlign: isAmount ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  /// Build summary section
  static pw.Widget _buildSummary(
      double totalPrice, String promoCode, String paymentMethod) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 2, child: pw.SizedBox()),
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(AppPadding.p16),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RINGKASAN',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (promoCode.isNotEmpty) ...[
                  _buildSummaryRow('Lokasi Penjualan:', promoCode),
                  pw.SizedBox(height: 4),
                ],
                _buildSummaryRow('Metode Pembayaran:', paymentMethod),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.green300),
                pw.SizedBox(height: 4),
                _buildSummaryRow(
                  'TOTAL:',
                  FormatHelper.formatCurrency(totalPrice),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build summary row
  static pw.Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 12 : 10,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 12 : 10,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isTotal ? PdfColors.green800 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  /// Build notes section
  static pw.Widget _buildNotes(String notes) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(AppPadding.p16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'CATATAN',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        // Contact info box
        pw.Container(
          width: 200,
          padding: const pw.EdgeInsets.all(AppPadding.p12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'SC: 081234567788 (DEWI)',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        // Thank you section
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(AppPadding.p16),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Terima kasih atas pesanan Anda!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Invoice ini dibuat secara otomatis oleh sistem Alita Pricelist',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Dibuat pada: ${_formatDateTime(DateTime.now())}',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Save PDF to device storage
  static Future<String> savePDFToDevice(Uint8List pdfBytes) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get documents directory
      final Directory? directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create file path
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'invoice_$timestamp.pdf';
      final String filePath = '${directory.path}/$fileName';

      // Write file
      final File file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      logger.i("✅ PDF saved to: $filePath");
      return filePath;
    } catch (e) {
      logger.e("❌ Error saving PDF: $e");
      throw Exception('Failed to save PDF: $e');
    }
  }

  /// Share PDF file
  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      // Create temporary file
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';
      final File tempFile = File(tempPath);
      await tempFile.writeAsBytes(pdfBytes);

      // Share file
      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Invoice Checkout - Alita Pricelist',
      );

      logger.i("✅ PDF shared successfully");
    } catch (e) {
      logger.e("❌ Error sharing PDF: $e");
      throw Exception('Failed to share PDF: $e');
    }
  }

  // Helper methods
  static String _formatDate(DateTime date) {
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static List<String> _formatDiscounts(CartEntity item) {
    final list = <double>[...item.discountPercentages];
    if (item.editPopupDiscount > 0) list.add(item.editPopupDiscount);
    return list
        .where((d) => d > 0)
        .map((d) => d % 1 == 0 ? '${d.toInt()}%' : '${d.toStringAsFixed(2)}%')
        .toList();
  }
}
