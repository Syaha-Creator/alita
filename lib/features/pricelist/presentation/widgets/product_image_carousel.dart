import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/network_image_view.dart';

class ProductImageCarousel extends StatelessWidget {
  final double screenWidth;
  final String baseImageUrl;
  final String productId;
  final Map<String, dynamic>? matchedSpec;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const ProductImageCarousel({
    super.key,
    required this.screenWidth,
    required this.baseImageUrl,
    required this.productId,
    required this.matchedSpec,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String baseImage = baseImageUrl.isNotEmpty
        ? baseImageUrl
        : 'https://images.unsplash.com/photo-1505693416022-14c1c9240ce4?q=80&w=800&auto=format&fit=crop';

    final List<String> productImages = [];

    final brandImage = matchedSpec?['image']?.toString() ?? '';
    if (brandImage.isNotEmpty) {
      productImages.add(brandImage);
    } else {
      productImages.add(baseImage);
    }

    productImages.addAll([
      'https://images.unsplash.com/photo-1631679706909-1844bbd07221?q=80&w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?q=80&w=800&auto=format&fit=crop',
    ]);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: screenWidth * 0.85,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: productImages.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final img = NetworkImageView(
                  imageUrl: productImages[index],
                  fit: BoxFit.cover,
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
                );
                return index == 0
                    ? Hero(
                        tag: 'product-image-$productId',
                        child: img,
                      )
                    : img;
              },
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
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(productImages.length, (i) {
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
