import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/product_image_utils.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';
import '../../../../core/widgets/network_image_view.dart';

/// Full-width image pager for product detail; [imageUrls] from
/// [productDisplayImageProvider] (network URL or `asset://` logo).
class ProductImageCarousel extends StatelessWidget {
  const ProductImageCarousel({
    super.key,
    required this.screenWidth,
    required this.imageUrls,
    required this.productId,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final double screenWidth;

  /// Display sources (network or `asset://…`); typically one slide.
  final List<String> imageUrls;

  final String productId;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls.where((e) => e.isNotEmpty).toList();
    final slides = urls.isEmpty
        ? <String>[ProductImageUtils.brandLogoAssetUri('')]
        : urls;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: screenWidth * 0.85,
        width: double.infinity,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                final u = slides[currentIndex];
                if (ProductImageUtils.isNetworkProductPhoto(u) &&
                    currentIndex == 0) {
                  ImageViewerDialog.show(
                    context: context,
                    imageUrl: u,
                    maxScale: 4.0,
                    showCloseButton: false,
                  );
                }
              },
              child: PageView.builder(
                controller: controller,
                itemCount: slides.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  final url = slides[index];
                  final isAsset =
                      url.startsWith(ProductImageUtils.assetUriPrefix);
                  final img = ColoredBox(
                    color: AppColors.background,
                    child: NetworkImageView(
                      imageUrl: url,
                      fit: isAsset ? BoxFit.contain : BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      memCacheWidth: 600,
                      errorWidget: Container(
                        color: AppColors.border,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                  return index == 0
                      ? Hero(
                          tag: 'product-image-$productId',
                          child: img,
                        )
                      : img;
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
                ),
              ),
            ),
            if (slides.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (i) {
                    final isActive = currentIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 20 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
