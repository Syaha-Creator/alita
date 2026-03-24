import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

/// Returns the best display image URL for a product.
///
/// Uses Comforta brand spec when product name matches; otherwise falls back
/// to [product.imageUrl] (placeholder from Alita API).
final productDisplayImageProvider =
    Provider.family<String, Product>((ref, product) {
  final brandSpecs = ref.watch(brandSpecProvider).valueOrNull ?? [];
  final erpName = product.name.toLowerCase();

  for (final spec in brandSpecs) {
    final brandName = (spec['name'] as String? ?? '').toLowerCase();
    if (brandName.isNotEmpty && erpName.contains(brandName)) {
      final img = spec['image']?.toString() ?? '';
      if (img.isNotEmpty) return img;
      break;
    }
  }

  return product.imageUrl;
});
