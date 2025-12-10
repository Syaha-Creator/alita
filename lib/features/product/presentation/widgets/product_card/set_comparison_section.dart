import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';

/// Section showing comparison between individual product and set product
class SetComparisonSection extends StatelessWidget {
  final double setNetPrice;
  final double currentNetPrice;
  final bool isDark;

  const SetComparisonSection({
    super.key,
    required this.setNetPrice,
    required this.currentNetPrice,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceDifference = setNetPrice - currentNetPrice;
    final isMoreExpensive = priceDifference > 0;
    final savingsPercentage = ((priceDifference.abs() / setNetPrice) * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.info.withValues(alpha: 0.1),
            AppColors.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: AppColors.surfaceLight,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppPadding.p12),
              Expanded(
                child: Text(
                  "Perbandingan dengan Set",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p12),

          // Set price
          _buildPriceRow(context, "Harga Set:", setNetPrice),
          const SizedBox(height: AppPadding.p8),

          // Difference
          _buildDifferenceRow(context, priceDifference, isMoreExpensive),
          const SizedBox(height: AppPadding.p8),

          // Summary badge
          _buildSummaryBadge(
              context, priceDifference, isMoreExpensive, savingsPercentage),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          FormatHelper.formatCurrency(price),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDifferenceRow(
      BuildContext context, double difference, bool isMoreExpensive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Selisih:"),
        Text(
          "${isMoreExpensive ? '+' : '-'}${FormatHelper.formatCurrency(difference.abs())}",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isMoreExpensive ? AppColors.error : AppColors.success,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(BuildContext context, double difference,
      bool isMoreExpensive, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMoreExpensive
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "Customer hanya menambah ${FormatHelper.formatCurrency(difference.abs())} (${percentage.toStringAsFixed(1)}%)",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isMoreExpensive ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

