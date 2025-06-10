import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_bloc.dart';
import 'product_card.dart';

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
      builder: (_) {
        return CreditDialog(product: product);
      },
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
          title: const Text("Bagikan Produk"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Bagikan produk ini ke teman atau media sosial."),
              const SizedBox(height: 10),
              Screenshot(
                controller: screenshotController,
                child: ProductCard(product: product, hideButtons: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Tutup"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  showDialog(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final imageBytes = await screenshotController.capture();
                  Navigator.pop(dialogContext);

                  if (imageBytes == null) {
                    CustomToast.showToast(
                        "Gagal mengambil gambar produk", ToastType.error);
                    return;
                  }

                  double netPrice =
                      state.roundedPrices[product.id] ?? product.endUserPrice;
                  String shareText =
                      "Produk: ${product.kasur} (${product.ukuran})\n"
                      "Harga Pricelist: ${FormatHelper.formatCurrency(product.pricelist)}\n"
                      "Harga Net: ${FormatHelper.formatCurrency(netPrice)}";

                  final imageFile = XFile.fromData(imageBytes,
                      mimeType: 'image/png', name: 'product.png');

                  await Share.shareXFiles([imageFile], text: shareText);
                  Navigator.pop(dialogContext); // Close share dialog
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  CustomToast.showToast(
                      "Gagal membagikan: $e", ToastType.error);
                }
              },
              child: const Text("Bagikan"),
            ),
          ],
        );
      },
    );
  }
}
