import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';

/// Widget untuk menampilkan ringkasan pembayaran
/// Pure UI widget - menerima data yang sudah dihitung dari parent
class PaymentSummary extends StatelessWidget {
  final double grandTotal;
  final double totalPaid;
  final bool isDark;

  const PaymentSummary({
    super.key,
    required this.grandTotal,
    required this.totalPaid,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate status
    final grandTotalInt = grandTotal.round();
    final totalPaidInt = totalPaid.round();
    final remainingInt = grandTotalInt - totalPaidInt;
    final isFullyPaid = totalPaidInt >= grandTotalInt;
    final isOverPaid = totalPaidInt > grandTotalInt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyPaid
              ? AppColors.success.withValues(alpha: 0.3)
              : isOverPaid
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildTotalRow(context),
          const SizedBox(height: AppPadding.p8),
          _buildPaidRow(context, isFullyPaid, isOverPaid),
          const SizedBox(height: AppPadding.p8),
          _buildRemainingRow(context, remainingInt, isFullyPaid, isOverPaid),
          if (!isFullyPaid) _buildStatusIndicator(context),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Pesanan',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        Text(
          FormatHelper.formatCurrency(grandTotal),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
        ),
      ],
    );
  }

  Widget _buildPaidRow(BuildContext context, bool isFullyPaid, bool isOverPaid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total Dibayar',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
        ),
        Text(
          FormatHelper.formatCurrency(totalPaid),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isFullyPaid
                    ? AppColors.success
                    : isOverPaid
                        ? AppColors.warning
                        : (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight),
              ),
        ),
      ],
    );
  }

  Widget _buildRemainingRow(
    BuildContext context,
    int remainingInt,
    bool isFullyPaid,
    bool isOverPaid,
  ) {
    final statusColor = isFullyPaid
        ? AppColors.success
        : isOverPaid
            ? AppColors.warning
            : (isDark ? AppColors.primaryDark : AppColors.primaryLight);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isFullyPaid
              ? 'Lunas'
              : isOverPaid
                  ? 'Kelebihan'
                  : 'Sisa Pembayaran',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
        ),
        Text(
          isFullyPaid
              ? '✓'
              : FormatHelper.formatCurrency(remainingInt.abs().toDouble()),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppPadding.p12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: AppPadding.p8),
              Expanded(
                child: Text(
                  'Tambahkan pembayaran untuk melanjutkan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

