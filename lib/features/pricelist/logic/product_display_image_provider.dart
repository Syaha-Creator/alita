import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alitapricelist/core/utils/product_image_utils.dart';
import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

/// Returns the best display source for a product image, in priority order:
///
/// 1. Brand spec image when [Product.name] matches a spec — prefers `kasur`
///    (spesifik tipe kasur, dipakai iSleep) over `image` (komposit generik).
/// 2. Else [Product.imageUrl], if it's a real URL (not picsum/unsplash).
/// 3. Else bundled brand logo (`asset://…`) from [Product.brand].
final productDisplayImageProvider =
    Provider.family<String, Product>((ref, product) {
  final brandSpecs = ref.watch(brandSpecProvider).valueOrNull ?? [];
  final erpName = product.name.toLowerCase();

  for (final spec in brandSpecs) {
    final brandName = (spec['name'] as String? ?? '').toLowerCase();
    if (brandName.isNotEmpty && erpName.contains(brandName)) {
      final kasurImg = spec['kasur']?.toString() ?? '';
      final img = kasurImg.isNotEmpty ? kasurImg : spec['image']?.toString() ?? '';
      if (img.isNotEmpty) return img;
      break;
    }
  }

  if (!ProductImageUtils.isSyntheticProductImageUrl(product.imageUrl)) {
    return product.imageUrl;
  }

  return ProductImageUtils.brandLogoAssetUri(product.brand);
});
