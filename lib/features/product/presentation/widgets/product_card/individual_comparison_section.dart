import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';

/// Section showing comparison between set product and individual mattress
class IndividualComparisonSection extends StatelessWidget {
  final double setNetPrice;
  final double individualNetPrice;
  final bool isDark;

  const IndividualComparisonSection({
    super.key,
    required this.setNetPrice,
    required this.individualNetPrice,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceDifference = setNetPrice - individualNetPrice;
    final isMoreExpensive = priceDifference > 0;
    final savingsPercentage = ((priceDifference.abs() / setNetPrice) * 100);

    final cardBg = isDark
        ? AppColors.primaryDark.withValues(alpha: 0.13)
        : AppColors.accentLight.withValues(alpha: 0.25);
    final border = isDark ? AppColors.primaryDark : AppColors.accentLight;
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border.withValues(alpha: 0.7)),
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
                  color: iconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.single_bed,
                  color: AppColors.surfaceLight,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppPadding.p12),
              Expanded(
                child: Text(
                  "Perbandingan dengan Kasur Only",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p12),

          // Set price
          _buildPriceRow(
              context, "Harga Set Kasur:", setNetPrice, textColor),
          const SizedBox(height: AppPadding.p8),

          // Individual price
          _buildPriceRow(
              context, "Harga Kasur Only:", individualNetPrice, textColor),
          const SizedBox(height: AppPadding.p8),

          // Difference
          _buildDifferenceRow(context, priceDifference, isMoreExpensive, textColor),
          const SizedBox(height: AppPadding.p8),

          // Summary badge
          _buildSummaryBadge(
              context, priceDifference, isMoreExpensive, savingsPercentage),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      BuildContext context, String label, double price, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor)),
        Text(
          FormatHelper.formatCurrency(price),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildDifferenceRow(BuildContext context, double difference,
      bool isMoreExpensive, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Selisih:",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textColor)),
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

