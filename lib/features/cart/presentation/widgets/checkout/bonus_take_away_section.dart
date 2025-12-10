import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/responsive_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';
import '../../bloc/cart_bloc.dart';
import '../../bloc/cart_event.dart';

/// Widget untuk menampilkan opsi pengambilan bonus
/// Memungkinkan user memilih bonus mana yang ingin diambil di toko
class BonusTakeAwaySection extends StatelessWidget {
  final List<CartEntity> selectedItems;
  final bool isDark;

  const BonusTakeAwaySection({
    super.key,
    required this.selectedItems,
    required this.isDark,
  });

  /// Check if bonus is valid for display
  bool _isValidBonus(dynamic bonus) {
    if (bonus.name == null || bonus.name.isEmpty) return false;
    if (bonus.name.trim() == '0') return false;
    if (bonus.name.trim() == '-') return false;
    if (bonus.quantity <= 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Filter items yang punya bonus VALID
    final itemsWithBonus = selectedItems.where((item) {
      return item.product.bonus.any(_isValidBonus);
    }).toList();

    if (itemsWithBonus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark.withValues(alpha: 0.3) : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          // Content
          Padding(
            padding: ResponsiveHelper.getCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                _buildDescription(context),
                const SizedBox(height: AppPadding.p12),

                // Bonus Items List
                ...itemsWithBonus.expand((item) => _buildBonusItems(context, item)),

                const SizedBox(height: AppPadding.p8),

                // Info Box
                _buildInfoBox(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.getCardPadding(context),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Opsi Pengambilan Bonus',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'Pilih item bonus yang ingin diambil sendiri di toko:',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
    );
  }

  List<Widget> _buildBonusItems(BuildContext context, CartEntity item) {
    // Filter only valid bonuses
    final validBonuses = item.product.bonus.where(_isValidBonus).toList();

    return validBonuses.map((bonus) {
      final isChecked = item.bonusTakeAway?[bonus.name] ?? false;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: ResponsiveHelper.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (value) {
                final currentTakeAway =
                    Map<String, bool>.from(item.bonusTakeAway ?? {});
                currentTakeAway[bonus.name] = value ?? false;

                context.read<CartBloc>().add(UpdateBonusTakeAway(
                      productId: item.product.id,
                      netPrice: item.netPrice,
                      bonusTakeAway: currentTakeAway,
                    ));
              },
              activeColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
            const SizedBox(width: AppPadding.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bonus.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                  ),
                  Text(
                    'Qty: ${bonus.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.accentDark.withValues(alpha: 0.15) // 10% dengan opacity
            : AppColors.accentLight.withValues(alpha: 0.1), // 10% dengan opacity
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.accentDark.withValues(alpha: 0.3) // 10% dengan opacity
              : AppColors.accentLight.withValues(alpha: 0.3), // 10% dengan opacity
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: isDark ? AppColors.accentDark : AppColors.accentLight, // 10% - Accent
          ),
          const SizedBox(width: AppPadding.p8),
          Expanded(
            child: Text(
              'Item yang dicentang akan diambil di toko, sisanya akan dikirim bersama pesanan utama.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    color: isDark ? AppColors.accentDark : AppColors.accentLight, // 10% - Accent
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

