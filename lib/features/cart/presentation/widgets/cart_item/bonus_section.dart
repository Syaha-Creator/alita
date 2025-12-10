import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../product/domain/entities/product_entity.dart';
import '../../../domain/entities/cart_entity.dart';
import '../../bloc/cart_bloc.dart';
import '../../bloc/cart_event.dart';

/// Widget untuk menampilkan section bonus di cart item
class BonusSection extends StatelessWidget {
  final CartEntity item;
  final bool isDark;
  final void Function(int bonusIndex, BonusItem bonus) onSelectBonus;
  final void Function(int bonusIndex) onRemoveBonus;

  static const Radius radius = Radius.circular(12);

  const BonusSection({
    super.key,
    required this.item,
    required this.isDark,
    required this.onSelectBonus,
    required this.onRemoveBonus,
  });

  /// Check if bonus is valid for display
  bool _isValidBonus(BonusItem b) {
    if (b.name.isEmpty) return false;
    if (b.name.trim() == '0') return false;
    if (b.name.trim() == '-') return false;
    if (b.quantity <= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bonusList = item.product.bonus;
    // Only show valid bonuses
    final validBonuses = bonusList.where(_isValidBonus).toList();
    final hasBonus = validBonuses.isNotEmpty;

    // Hide bonus section if there's no valid bonus
    if (!hasBonus) {
      return const SizedBox.shrink();
    }

    return _buildBonusBox(context, validBonuses, hasBonus);
  }

  Widget _buildBonusBox(
      BuildContext context, List<BonusItem> bonusList, bool hasBonus) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppPadding.p8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.accentLight.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.all(radius),
        border: Border.all(
          color: isDark
              ? AppColors.accentDark.withValues(alpha: 0.2)
              : AppColors.accentLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact header
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                size: 18,
                color: isDark ? AppColors.accentDark : AppColors.accentLight,
              ),
              const SizedBox(width: AppPadding.p8),
              Expanded(
                child: Text(
                  'Bonus',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),

          // Compact bonus items
          if (hasBonus) ...[
            ...bonusList.asMap().entries.map((entry) {
              final bonus = entry.value;
              // Get original index from the full bonus list
              final originalIndex = item.product.bonus.indexOf(bonus);
              return _buildBonusItem(context, originalIndex, bonus);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBonusItem(BuildContext context, int index, BonusItem bonus) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          // Bonus name
          Expanded(
            child: InkWell(
              onTap: () => onSelectBonus(index, bonus),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.accentDark.withValues(alpha: 0.3)
                        : AppColors.accentLight.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        bonus.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppPadding.p8),
          // Quantity controls
          _buildQuantityControls(context, index, bonus),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(
      BuildContext context, int index, BonusItem bonus) {
    final perUnit =
        bonus.originalQuantity > 0 ? bonus.originalQuantity : bonus.quantity;
    final maxQty = perUnit * 2 * item.quantity;

    return Row(
      children: [
        // Minus button or delete button
        IconButton(
          onPressed: () {
            if (bonus.quantity > 1) {
              // Decrease quantity
              context.read<CartBloc>().add(UpdateCartBonus(
                    productId: item.product.id,
                    netPrice: item.netPrice,
                    bonusIndex: index,
                    bonusName: bonus.name,
                    bonusQuantity: bonus.quantity - 1,
                    cartLineId: item.cartLineId,
                  ));
            } else {
              // Delete bonus when quantity is 1
              onRemoveBonus(index);
            }
          },
          icon: Icon(
            bonus.quantity > 1
                ? Icons.remove_circle_outline
                : Icons.delete_outline,
            size: 20,
            color: bonus.quantity > 1
                ? (isDark ? AppColors.accentDark : AppColors.accentLight)
                : AppColors.error,
          ),
          tooltip: bonus.quantity > 1 ? 'Kurangi jumlah' : 'Hapus bonus',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
        // Quantity display
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.accentDark.withValues(alpha: 0.3)
                  : AppColors.accentLight.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${bonus.quantity}x (Max: $maxQty)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
        // Plus button
        IconButton(
          onPressed: bonus.quantity < maxQty
              ? () {
                  context.read<CartBloc>().add(UpdateCartBonus(
                        productId: item.product.id,
                        netPrice: item.netPrice,
                        bonusIndex: index,
                        bonusName: bonus.name,
                        bonusQuantity: bonus.quantity + 1,
                        cartLineId: item.cartLineId,
                      ));
                }
              : null,
          icon: Icon(
            Icons.add_circle_outline,
            size: 20,
            color: bonus.quantity < maxQty
                ? (isDark ? AppColors.accentDark : AppColors.accentLight)
                : Colors.grey,
          ),
          tooltip: bonus.quantity < maxQty
              ? 'Tambah jumlah (Max: $maxQty)'
              : 'Maksimum tercapai ($maxQty)',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ],
    );
  }
}
