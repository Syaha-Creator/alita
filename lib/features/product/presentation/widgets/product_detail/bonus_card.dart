import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Clean card displaying bonus items - only shows when there are bonuses
class BonusCard extends StatelessWidget {
  final ProductEntity product;
  final bool isDark;

  const BonusCard({
    super.key,
    required this.product,
    required this.isDark,
  });

  /// Check if bonus item should be displayed
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

    // Don't show card if no bonus
    if (bonusItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                Expanded(
                  child: Text(
                    "Bonus",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${bonusItems.length} item",
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),

          // Bonus items - simple list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: bonusItems.asMap().entries.map((entry) {
                final index = entry.key;
                final bonus = entry.value;
                final isLast = index == bonusItems.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: Row(
                    children: [
                      // Check icon
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                      const SizedBox(width: AppPadding.p10),
                      // Bonus name
                      Expanded(
                        child: Text(
                          bonus.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Quantity
                      Text(
                        "${bonus.quantity}x",
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
