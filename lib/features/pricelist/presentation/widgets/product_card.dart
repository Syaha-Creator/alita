import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/store_discount_calculator.dart';
import '../../../../core/widgets/network_image_view.dart';
import '../../../../core/widgets/price_block.dart';
import '../../../../core/widgets/tap_scale.dart';
import '../../data/models/product.dart';
import '../../logic/product_display_image_provider.dart';
import '../../../favorites/logic/favorites_provider.dart';

/// Product card with Pinterest-style minimalist design
class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;

  /// Jika non-null: harga tampilan setelah diskon toko (EUP × cascade).
  final List<double>? indirectStoreDiscounts;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.indirectStoreDiscounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(product.id));
    final displayImageUrl = ref.watch(productDisplayImageProvider(product));

    final discounts = indirectStoreDiscounts;
    final bool indirectPricing =
        discounts != null && discounts.isNotEmpty;
    final double displayNet = indirectPricing
        ? StoreDiscountCalculator.cascade(product.price, discounts)
        : product.price;
    final double? displayOriginal =
        indirectPricing ? product.price : null;
    return Semantics(
      button: true,
      label: 'Lihat detail ${product.name}',
      child: TapScale(
        child: GestureDetector(
          onTap: () {
            hapticTap();
            onTap?.call();
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image with rounded top corners & Hero animation
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.85, // Slightly wider for bed product photos
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'product-image-${product.id}',
                          child: Container(
                            color: AppColors.background,
                            child: NetworkImageView(
                              imageUrl: displayImageUrl,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              memCacheWidth: 300,
                              errorWidget: Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Semantics(
                            button: true,
                            label: isFavorite
                                ? 'Hapus dari favorit'
                                : 'Tambah ke favorit',
                            child: GestureDetector(
                              onTap: () {
                                hapticSelection();
                                ref
                                    .read(favoritesProvider.notifier)
                                    .toggleFavorite(product.id);
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFavorite
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Category
                      Text(
                        product.category,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),

                      const SizedBox(height: 8),

                      // Price — indirect: coret EUP, tampil setelah diskon toko
                      PriceBlock(
                        price: displayNet,
                        originalPrice: displayOriginal ?? product.pricelist,
                        formatPrice: _formatPrice,
                        priceStyle:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return AppFormatters.currencyIdr(price);
  }
}
