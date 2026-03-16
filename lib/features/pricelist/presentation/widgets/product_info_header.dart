import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProductInfoHeader extends StatelessWidget {
  final String category;
  final String productName;

  const ProductInfoHeader({
    super.key,
    required this.category,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryBadge(context),
        const SizedBox(height: 12),
        Text(
          productName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 12),
        _buildRating(context),
      ],
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildRating(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < 4.5 ? Icons.star : Icons.star_border,
            size: 20,
            color: const Color(0xFFFFA726),
          );
        }),
        const SizedBox(width: 8),
        Text(
          '4.5',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          '(1k+ reviews)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
