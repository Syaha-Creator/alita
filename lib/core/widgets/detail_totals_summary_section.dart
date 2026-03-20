import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable totals summary section for detail product cards.
class DetailTotalsSummarySection extends StatelessWidget {
  final String postageText;
  final String totalText;

  const DetailTotalsSummarySection({
    super.key,
    required this.postageText,
    required this.totalText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Ringkasan total',
      child: Column(
      children: [
        const SizedBox(height: 14),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ongkos Kirim',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              postageText,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Tagihan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              totalText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ],
    ),
    );
  }
}
