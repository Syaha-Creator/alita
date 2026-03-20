import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable bonus/accessory section for detail pages.
class DetailBonusItemsSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const DetailBonusItemsSection({
    super.key,
    this.title = 'Bonus & Aksesoris',
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: title,
      child: Column(
      children: [
        const SizedBox(height: 12),
        Container(height: 1, color: AppColors.surfaceLight),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.card_giftcard_outlined,
              size: 13,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: AppColors.textTertiary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    ),
    );
  }
}
