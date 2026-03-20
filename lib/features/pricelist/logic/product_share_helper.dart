import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_formatters.dart';
import '../data/models/product.dart';

/// Handles share-product logic extracted from [ProductDetailPage].
class ProductShareHelper {
  ProductShareHelper._();

  static Future<void> share(
    BuildContext context, {
    required Product product,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final Rect origin;
    if (box != null && box.hasSize && box.size.width > 0) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final screen = MediaQuery.of(context).size;
      origin = Rect.fromLTWH(0, 0, screen.width, screen.height / 2);
    }

    try {
      final formattedPrice = AppFormatters.currencyIdr(product.price);
      final text = 'Cek produk keren ini!\n'
          '*${product.brand}* — ${product.name}\n'
          '*Harga:* $formattedPrice\n'
          '\nLihat detail selengkapnya di Alita Pricelist.';

      final files = <XFile>[];
      if (product.imageUrl.isNotEmpty) {
        final bytes = await ApiClient.instance.downloadBytes(product.imageUrl);
        if (bytes != null) {
          final dir = await getTemporaryDirectory();
          final ext = product.imageUrl.contains('.png') ? 'png' : 'jpg';
          final file = File('${dir.path}/share_product.$ext');
          await file.writeAsBytes(bytes);
          files.add(XFile(file.path, mimeType: 'image/$ext'));
        }
      }

      await Share.shareXFiles(
        files,
        text: text,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        AppFeedback.show(
          context,
          message: 'Gagal membagikan produk: $e',
          type: AppFeedbackType.error,
          floating: true,
        );
      }
    }
  }
}
