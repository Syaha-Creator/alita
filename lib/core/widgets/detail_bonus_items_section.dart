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
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: rows),
            ],
          ),
        ),
      ),
    );
  }
}

/// One bonus/accessory pill inside [DetailBonusItemsSection]'s [Wrap] —
/// e.g. "2x Dacron Pillow", with an optional "Bawa Langsung" sub-badge.
class DetailBonusChip extends StatelessWidget {
  const DetailBonusChip({
    super.key,
    required this.label,
    this.isTakeAway = false,
  });

  final String label;
  final bool isTakeAway;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isTakeAway) ...[
            const SizedBox(width: 5),
            Text(
              '· Bawa Langsung',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
