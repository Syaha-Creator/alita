import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Section showing bonus information for a product - hidden when no bonus
class BonusInfoSection extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;

  const BonusInfoSection({
    super.key,
    required this.product,
    this.isDark = false,
  });

  /// Check if bonus item is valid for display
  bool _isValidBonus(dynamic bonus) {
    // Skip if name is empty, "0", or "-"
    if (bonus.name.isEmpty) return false;
    if (bonus.name.trim() == '0') return false;
    if (bonus.name.trim() == '-') return false;
    // Skip if quantity is 0 or less
    if (bonus.quantity <= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bonusItems = product.bonus.where(_isValidBonus).toList();

    // Don't show if no valid bonus
    if (bonusItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final iconColor = AppColors.warning;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: iconColor,
                size: 20,
              ),
              const SizedBox(width: AppPadding.p10),
              Text(
                "Complimentary:",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p10),

          // Bonus items
          ...bonusItems.map(
            (bonus) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: iconColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppPadding.p8),
                  Expanded(
                    child: Text(
                      "${bonus.quantity}x ${bonus.name}",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

