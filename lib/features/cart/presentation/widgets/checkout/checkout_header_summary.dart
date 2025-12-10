import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/cart_entity.dart';

/// Widget untuk menampilkan ringkasan pesanan di header checkout
/// Pure UI widget - hanya menerima data untuk ditampilkan
class CheckoutHeaderSummary extends StatelessWidget {
  final List<CartEntity> selectedItems;
  final double grandTotal;
  final bool isDark;
  final bool isExistingCustomer;

  const CheckoutHeaderSummary({
    super.key,
    required this.selectedItems,
    required this.grandTotal,
    required this.isDark,
    this.isExistingCustomer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.primaryDark.withValues(alpha: 0.1)
                : AppColors.primaryLight.withValues(alpha: 0.05),
            isDark
                ? AppColors.primaryDark.withValues(alpha: 0.05)
                : AppColors.primaryLight.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.8)
              : AppColors.surfaceLight.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIcon(),
                const SizedBox(width: AppPadding.p12),
                Expanded(child: _buildSummaryInfo(context)),
              ],
            ),
            if (isExistingCustomer) ...[
              const SizedBox(height: AppPadding.p12),
              _buildExistingCustomerBadge(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.surfaceLight,
        size: 20,
      ),
    );
  }

  Widget _buildSummaryInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ringkasan Pesanan',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
        ),
        const SizedBox(height: AppPadding.p4),
        Text(
          '${selectedItems.length} item • Total: ${FormatHelper.formatCurrency(grandTotal)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
      ],
    );
  }

  Widget _buildExistingCustomerBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, color: AppColors.success, size: 16),
          const SizedBox(width: AppPadding.p4),
          Text(
            'Customer Existing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}

