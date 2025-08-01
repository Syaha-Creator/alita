import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_state.dart';
import 'dialogs/credit_dialog.dart';
import 'dialogs/edit_price_dialog.dart';
import 'dialogs/info_dialog.dart';

class ProductActions {
  static void showCreditPopup(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreditDialog(product: product),
    );
  }

  static void showEditPopup(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditPriceDialog(product: product),
    );
  }

  static void showInfoPopup(BuildContext context, ProductEntity product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InfoDialog(product: product),
    );
  }

  static void showSharePopup(BuildContext context, ProductEntity product) {
    final state = context.read<ProductBloc>().state;
    ScreenshotController screenshotController = ScreenshotController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Icon(Icons.share,
                  color: Theme.of(context).primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text("Bagikan Produk"),
            ],
          ),
          content: SingleChildScrollView(
            child: Screenshot(
              controller: screenshotController,
              child: _buildShareProductDetail(product, state),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Show loading dialog
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (loadingContext) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  // Capture screenshot
                  final imageBytes = await screenshotController.capture();
                  Navigator.pop(dialogContext); // Close loading
                  if (imageBytes == null) {
                    CustomToast.showToast(
                        "Gagal mengambil gambar produk", ToastType.error);
                    return;
                  }
                  double netPrice =
                      state.roundedPrices[product.id] ?? product.endUserPrice;
                  String shareText =
                      "🛏️ Produk: ${product.kasur} (${product.ukuran})\n"
                      "💰 Harga Pricelist: ${product.pricelist}\n"
                      "💵 Harga Net: $netPrice\n\n"
                      "📱 Dibagikan dari Alita Pricelist";
                  final imageFile = XFile.fromData(imageBytes,
                      mimeType: 'image/png', name: 'product_${product.id}.png');
                  await Share.shareXFiles([imageFile], text: shareText);
                  Navigator.pop(dialogContext); // Close share dialog
                  CustomToast.showToast(
                      "Produk berhasil dibagikan!", ToastType.success);
                } catch (e) {
                  Navigator.pop(dialogContext);
                  CustomToast.showToast(
                      "Gagal membagikan: $e", ToastType.error);
                }
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text("Bagikan"),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildShareProductDetail(
      ProductEntity product, ProductState state) {
    final netPrice = state.roundedPrices[product.id] ?? product.endUserPrice;
    final discountPercentages =
        state.productDiscountsPercentage[product.id] ?? [];
    final totalDiscount = product.pricelist - netPrice;
    final installmentMonths = state.installmentMonths[product.id];
    final note = state.productNotes[product.id] ?? "";

    final List<String> combinedDiscounts = [];
    final programDiscounts = discountPercentages
        .where((d) => d > 0.0)
        .map((d) => d % 1 == 0 ? "${d.toInt()}%" : "${d.toStringAsFixed(2)}%")
        .toList();
    combinedDiscounts.addAll(programDiscounts);

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '${product.kasur} (${product.ukuran})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Price Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Rincian Harga",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  _buildPriceRow("Pricelist",
                      FormatHelper.formatCurrency(product.pricelist),
                      isStrikethrough: true),
                  _buildPriceRow(
                      "Program",
                      product.program.isNotEmpty
                          ? product.program
                          : "Tidak ada promo"),
                  if (combinedDiscounts.isNotEmpty)
                    _buildPriceRow(
                        "Diskon Tambahan", combinedDiscounts.join(' + '),
                        valueColor: Colors.blue),
                  _buildPriceRow("Total Diskon",
                      "- ${FormatHelper.formatCurrency(totalDiscount)}",
                      valueColor: Colors.red),
                  const Divider(height: 16, thickness: 1.5),
                  _buildPriceRow(
                      "Harga Net", FormatHelper.formatCurrency(netPrice),
                      isBold: true, valueSize: 18, valueColor: Colors.green),
                  if (installmentMonths != null && installmentMonths > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          "Cicilan: ${FormatHelper.formatCurrency(netPrice / installmentMonths)} x $installmentMonths bulan",
                          style: const TextStyle(
                              fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Detail Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Spesifikasi Set",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  _buildSpecRow("Tipe Kasur", product.kasur),
                  if (product.divan.isNotEmpty &&
                      product.divan != AppStrings.noDivan)
                    _buildSpecRow("Tipe Divan", product.divan),
                  if (product.headboard.isNotEmpty &&
                      product.headboard != AppStrings.noHeadboard)
                    _buildSpecRow("Tipe Headboard", product.headboard),
                  if (product.sorong.isNotEmpty &&
                      product.sorong != AppStrings.noSorong)
                    _buildSpecRow("Tipe Sorong", product.sorong),
                  _buildSpecRow("Ukuran", product.ukuran),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bonus & Notes Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bonus & Catatan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 16),
                  const Text("Complimentary:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (product.bonus.isNotEmpty &&
                      product.bonus.any((b) => b.name.isNotEmpty))
                    ...product.bonus
                        .where((b) => b.name.isNotEmpty)
                        .map((b) => Padding(
                              padding:
                                  const EdgeInsets.only(left: 8, bottom: 4),
                              child: Text("• ${b.name}"),
                            ))
                  else
                    const Text("Tidak ada bonus",
                        style: TextStyle(fontStyle: FontStyle.italic)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Catatan:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(note),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isStrikethrough = false,
    double? valueSize,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: valueSize,
              color: valueColor,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
