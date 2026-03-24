import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';

/// Shimmer skeleton that mirrors the dimensions of ProductCard.
/// Used as a loading placeholder in the Masonry Grid.
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceLight,
      highlightColor: AppColors.surface,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton — same aspect ratio as ProductCard
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Container(color: AppColors.surfaceLight),
              ),
            ),

            // Info skeleton
            const Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title line 1
                  _SkeletonLine(width: double.infinity, height: 14),
                  SizedBox(height: 6),
                  // Title line 2 (shorter)
                  _SkeletonLine(width: 80, height: 14),
                  SizedBox(height: 8),
                  // Category
                  _SkeletonLine(width: 60, height: 10),
                  SizedBox(height: 10),
                  // Price
                  _SkeletonLine(width: 100, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable rounded rectangle skeleton line
class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
