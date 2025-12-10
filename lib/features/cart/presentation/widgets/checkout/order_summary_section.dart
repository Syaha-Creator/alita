import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';

/// Widget untuk menampilkan ringkasan detail pesanan
/// Pure UI widget - hanya menerima data untuk ditampilkan
class OrderSummarySection extends StatelessWidget {
  final List<CartEntity> selectedItems;
  final double grandTotal;
  final bool isDark;

  const OrderSummarySection({
    super.key,
    required this.selectedItems,
    required this.grandTotal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(context),
          _buildItemsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            Icons.receipt_long_outlined,
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Detail Pesanan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...selectedItems.map((item) => _buildOrderItem(context, item)),
          const SizedBox(height: AppPadding.p16),
          _buildTotalRow(context),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, CartEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight, // 30% - Border
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.kasur,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                ),
                const SizedBox(height: AppPadding.p4),
                Text(
                  'Qty: ${item.quantity} × ${FormatHelper.formatCurrency(item.netPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          Text(
            FormatHelper.formatCurrency(item.netPrice * item.quantity),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight, // 30% - Border
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Pesanan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
          Text(
            FormatHelper.formatCurrency(grandTotal),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
          ),
        ],
      ),
    );
  }
}

