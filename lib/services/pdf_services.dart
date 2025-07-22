// lib/services/pdf_services.dart
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

class PDFService {
  // Ganti seluruh fungsi ini di pdf_services.dart
  static Future<Uint8List> generateCheckoutPDF({
    required List<CartEntity> cartItems,
    required String customerName,
    required String shippingAddress,
    required String phoneNumber,
    required String deliveryDate,
    required String paymentMethod,
    required double paymentAmount,
    required String repaymentDate,
    String? email,
    String? showroom,
    String? keterangan,
    String? salesName,
  }) async {
    final pdf = pw.Document();

    // Load semua logo seperti sebelumnya
    final sleepCenterLogo =
        await _loadImageProvider('assets/logo/sleepcenter_logo.png');
    final sleepSpaLogo =
        await _loadImageProvider('assets/logo/sleepspa_logo.png');
    // ... (lanjutan load logo lainnya)
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

    // Hitung total dan sisa bayar
    final selectedItems = cartItems.where((item) => item.isSelected).toList();
    double subtotal = 0;
    for (var item in selectedItems) {
      subtotal += item.netPrice * item.quantity;
    }
    double ppn = subtotal * 0.11;
    double grandTotal = subtotal + ppn;
    final double sisaPembayaran = grandTotal - paymentAmount;

    // --- PERUBAHAN 1: Tentukan kondisi lunas ---
    final bool isPaid = sisaPembayaran <= 0;

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        // --- PERUBAHAN 2: Tambahkan `pageTheme` untuk background ---
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 28, 36, 28),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          buildBackground: (pw.Context context) {
            // Tampilkan watermark hanya jika sudah lunas
            if (isPaid) {
              return _buildLunasWatermark();
            }
            // Jika tidak, kembalikan widget kosong
            return pw.SizedBox();
          },
        ),
        // --- Akhir Perubahan ---

        header: (pw.Context context) {
          if (context.pageNumber == 1) {
            return _buildHeader(sleepCenterLogo, otherLogos, showroom ?? "-");
          }
          return pw.Container();
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Halaman ${context.pageNumber} dari ${context.pagesCount}",
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) => [
          _buildCustomerAndOrderInfo(
            customerName: customerName,
            shippingAddress: shippingAddress,
            phoneNumber: phoneNumber,
            email: email ?? '-',
            spNumber:
                'SP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            deliveryDate: deliveryDate,
          ),
          pw.SizedBox(height: 12),
          _buildItemsTable(cartItems),
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
          _buildSignatureSection(customerName, salesName ?? "NAMA SALES"),
          pw.Spacer(),
          _buildTermsAndConditions(),
          pw.SizedBox(height: 5),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'Dokumen ini dicetak pada: ${_formatDateTime(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildLunasWatermark() {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: 0.785,
        child: pw.Text(
          'LUNAS',
          style: pw.TextStyle(
            fontSize: 120,
            color: PdfColor(
              PdfColors.green300.red,
              PdfColors.green300.green,
              PdfColors.green300.blue,
              0.3,
            ),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Future<pw.ImageProvider?> _loadImageProvider(String path) async {
    try {
      final ByteData byteData = await rootBundle.load(path);
      return pw.MemoryImage(byteData.buffer.asUint8List());
    } catch (e) {
      // logger.e('Gagal memuat aset gambar: $path. Error: $e');
      return null;
    }
  }

  // --- HEADER FINAL DENGAN UKURAN DAN LAYOUT YANG TEPAT ---
  static pw.Widget _buildHeader(pw.ImageProvider? sleepCenterLogo,
      List<pw.ImageProvider?> otherLogos, String showroom) {
    return pw.Column(
      children: [
        if (sleepCenterLogo != null)
          pw.Container(
            height: 170,
            width: double.infinity,
            child: pw.Image(
              sleepCenterLogo,
              fit: pw.BoxFit.fitWidth,
            ),
          ),
        pw.SizedBox(height: 15),
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
            pw.Text('SHOWROOM/PAMERAN: ${showroom.isNotEmpty ? showroom : "-"}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.Text('TANGGAL PEMBELIAN: ${_formatSimpleDate(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.Divider(color: PdfColors.black, thickness: 1.5),
        pw.SizedBox(height: 5),
        pw.Text('SURAT PESANAN',
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline)),
        pw.SizedBox(height: 5),
      ],
    );
  }

  // Sisa kode di bawah ini sudah benar dan tidak perlu diubah.
  static pw.Widget _buildCustomerAndOrderInfo({
    required String customerName,
    required String shippingAddress,
    required String phoneNumber,
    required String email,
    required String spNumber,
    required String deliveryDate,
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
              _buildInfoTableRow('Nama Pembeli', customerName),
              _buildInfoTableRow('Alamat Pengiriman', shippingAddress),
              _buildInfoTableRow('Nama Penerima', customerName),
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

  static pw.Widget _buildItemsTable(List<CartEntity> items) {
    const tableHeaders = [
      'NO',
      'QTY',
      'NAMA BARANG',
      'HARGA\nPRICELIST',
      'DISC/\nPROGRAM',
      'HARGA\nNETT'
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
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );

    int itemNumber = 1;

    for (var item in items) {
      final product = item.product;

      double kasurPricelist = (product.plKasur) * item.quantity;
      double kasurEUP = (product.eupKasur) * item.quantity;
      double kasurDiscount = kasurPricelist - kasurEUP;
      tableRows.add(pw.TableRow(
        children: [
          _buildTableCell((itemNumber++).toString(),
              align: pw.TextAlign.center),
          _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
          _buildTableCell('${product.kasur} ${product.ukuran}'),
          _buildTableCell(FormatHelper.formatCurrency(kasurPricelist),
              align: pw.TextAlign.right),
          _buildTableCell(FormatHelper.formatCurrency(kasurDiscount),
              align: pw.TextAlign.right),
          _buildTableCell(FormatHelper.formatCurrency(kasurEUP),
              align: pw.TextAlign.right),
        ],
      ));
      if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan) {
        double divanPricelist = (product.plDivan) * item.quantity;
        double divanEUP = (product.eupDivan) * item.quantity;
        double divanDiscount = divanPricelist - divanEUP;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(product.divan),
            _buildTableCell(FormatHelper.formatCurrency(divanPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(divanDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(divanEUP),
                align: pw.TextAlign.right),
          ],
        ));
      }
      if (product.headboard.isNotEmpty &&
          product.headboard != AppStrings.noHeadboard) {
        double headboardPricelist = (product.plHeadboard) * item.quantity;
        double headboardEUP = (product.eupHeadboard) * item.quantity;
        double headboardDiscount = headboardPricelist - headboardEUP;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(product.headboard),
            _buildTableCell(FormatHelper.formatCurrency(headboardPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(headboardDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(headboardEUP),
                align: pw.TextAlign.right),
          ],
        ));
      }
      if (product.sorong.isNotEmpty && product.sorong != AppStrings.noSorong) {
        double sorongPricelist = (product.plSorong) * item.quantity;
        double sorongEUP = (product.eupSorong) * item.quantity;
        double sorongDiscount = sorongPricelist - sorongEUP;
        tableRows.add(pw.TableRow(
          children: [
            _buildTableCell(''),
            _buildTableCell(item.quantity.toString(),
                align: pw.TextAlign.center),
            _buildTableCell(product.sorong),
            _buildTableCell(FormatHelper.formatCurrency(sorongPricelist),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(sorongDiscount),
                align: pw.TextAlign.right),
            _buildTableCell(FormatHelper.formatCurrency(sorongEUP),
                align: pw.TextAlign.right),
          ],
        ));
      }

      if (product.bonus.isNotEmpty) {
        for (var bonus in product.bonus) {
          final bonusQuantity = bonus.quantity * item.quantity;
          const String bonusPrice = "Rp 0";
          tableRows.add(pw.TableRow(
            children: [
              _buildTableCell(''),
              _buildTableCell(bonusQuantity.toString(),
                  align: pw.TextAlign.center),
              _buildTableCell('${bonus.name} (BONUS)'),
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
        1: const pw.FlexColumnWidth(0.6),
        2: const pw.FlexColumnWidth(3.8),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: tableRows,
    );
  }

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

  static pw.Widget _buildSignatureSection(
      String customerName, String salesName) {
    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      child: pw.Row(
        children: [
          _buildSignatureBox('PEMBELI', customerName),
          _buildSignatureBox('SALES', salesName, borderLeft: true),
        ],
      ),
    );
  }

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

  static String _formatSimpleDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    return '${_formatSimpleDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

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
      return filePath;
    } catch (e) {
      // logger.e("❌ Error saving PDF: $e");
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<void> sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(tempPath)],
          text: 'Invoice Checkout - Alita Pricelist');
    } catch (e) {
      // logger.e("❌ Error sharing PDF: $e");
      throw Exception('Failed to share PDF: $e');
    }
  }
}
