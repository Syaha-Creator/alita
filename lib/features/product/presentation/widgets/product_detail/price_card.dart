import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Modern card displaying price breakdown with gradient and visual hierarchy
class PriceCard extends StatelessWidget {
  final ProductEntity product;
  final double netPrice;
  final double totalDiscount;
  final List<String> combinedDiscounts;
  final int? installmentMonths;
  final bool isDark;

  const PriceCard({
    super.key,
    required this.product,
    required this.netPrice,
    required this.totalDiscount,
    required this.combinedDiscounts,
    this.installmentMonths,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercentage = product.pricelist > 0
        ? ((totalDiscount / product.pricelist) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppPadding.p16, vertical: AppPadding.p8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.surfaceDark,
                  AppColors.surfaceDark.withValues(alpha: 0.8),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryLight.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                const Text(
                  "Rincian Harga",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (discountPercentage > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.white, size: 14),
                        const SizedBox(width: AppPadding.p4),
                        Text(
                          "HEMAT $discountPercentage%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Price content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Original price (strikethrough)
                _buildPriceRow(
                  context,
                  icon: Icons.sell_outlined,
                  iconColor: AppColors.textSecondaryLight,
                  label: "Pricelist",
                  value: FormatHelper.formatCurrency(product.pricelist),
                  valueColor: AppColors.textSecondaryLight,
                  isStrikethrough: true,
                ),
                const SizedBox(height: AppPadding.p12),

                // Program (only show if exists and not just "-")
                if (product.program.isNotEmpty &&
                    product.program != "-" &&
                    product.program.trim() != "-") ...[
                  _buildPriceRow(
                    context,
                    icon: Icons.campaign_outlined,
                    iconColor: AppColors.info,
                    label: "Program",
                    value: product.program,
                    valueColor: AppColors.info,
                  ),
                  const SizedBox(height: AppPadding.p12),
                ],

                // Additional discounts
                if (combinedDiscounts.isNotEmpty) ...[
                  _buildPriceRow(
                    context,
                    icon: Icons.percent_rounded,
                    iconColor: AppColors.warning,
                    label: "Plus Diskon",
                    value: combinedDiscounts.join(' + '),
                    valueColor: AppColors.warning,
                  ),
                  const SizedBox(height: AppPadding.p12),
                ],

                // Total discount (only show if > 0)
                if (totalDiscount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: AppPadding.p8),
                        Text(
                          "Total Hemat",
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "- ${FormatHelper.formatCurrency(totalDiscount)}",
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppPadding.p16),
                ],

                // Net price (highlighted - solid for light, glow for dark)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? AppColors.success.withValues(alpha: 0.4)
                          : AppColors.success.withValues(alpha: 0.5),
                      width: isDark ? 1.5 : 2,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                              spreadRadius: -4,
                            ),
                          ]
                        : [
                            // Subtle shadow for light theme - no glow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.success,
                              AppColors.success.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: AppColors.success
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  // Subtle shadow for light theme
                                  BoxShadow(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: AppPadding.p16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Harga Net",
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: AppPadding.p8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "BEST PRICE",
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppPadding.p4),
                            Text(
                              FormatHelper.formatCurrency(netPrice),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Installment info
                if (installmentMonths != null && installmentMonths! > 0) ...[
                  const SizedBox(height: AppPadding.p12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card_rounded,
                            color: AppColors.info, size: 18),
                        const SizedBox(width: AppPadding.p8),
                        Text(
                          "${FormatHelper.formatCurrency(netPrice / installmentMonths!)} × $installmentMonths bulan",
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isStrikethrough = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: AppPadding.p8),
        Text(
          label,
          style: TextStyle(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
            fontWeight: FontWeight.w600,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: valueColor,
          ),
        ),
      ],
    );
  }
}
