import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/utils/format_helper.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/product_entity.dart';

/// Modal bottom sheet showing detailed item pricing breakdown
/// Displays pricelist and end user price for each component
class ItemPricingModal extends StatelessWidget {
  final ProductEntity product;

  const ItemPricingModal({
    super.key,
    required this.product,
  });

  /// Show the modal as a bottom sheet
  static Future<void> show(BuildContext context, ProductEntity product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemPricingModal(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _buildPricingItems();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(context, isDark),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppPadding.p16),
              child: Column(
                children: [
                  // Item pricing list
                  if (items.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...items.map(
                      (item) => _buildItemCard(context, item, isDark),
                    ),

                  // Total summary
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: AppPadding.p16),
                    _buildTotalSummary(context, isDark),
                  ],

                  // Bottom padding for safe area
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.p16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryLight.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.price_change_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppPadding.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rincian Harga per Item",
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pricelist & End User Price",
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 48,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppPadding.p12),
          Text(
            "Tidak ada rincian harga per item",
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    _PricingItem item,
    bool isDark,
  ) {
    // Check if there's a discount (pricelist > EUP, including when EUP = 0)
    final hasDiscount =
        item.pricelist > 0 && item.pricelist > item.endUserPrice;
    final discountAmount =
        hasDiscount ? item.pricelist - item.endUserPrice : 0.0;
    final discountPercentage = hasDiscount && item.pricelist > 0
        ? ((discountAmount / item.pricelist) * 100).round()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppPadding.p12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.primaryLight.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.primaryLight.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Item header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.isBonus
                  ? (isDark
                      ? AppColors.accentDark.withValues(alpha: 0.15)
                      : AppColors.accentLight.withValues(alpha: 0.08))
                  : (isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.15)
                      : AppColors.primaryLight.withValues(alpha: 0.08)),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.isBonus
                        ? (isDark
                            ? AppColors.accentDark.withValues(alpha: 0.2)
                            : AppColors.accentLight.withValues(alpha: 0.15))
                        : (isDark
                            ? AppColors.primaryDark.withValues(alpha: 0.2)
                            : AppColors.primaryLight.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isBonus
                        ? (isDark
                            ? AppColors.accentDark
                            : AppColors.accentLight)
                        : (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight),
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: item.isBonus
                                  ? (isDark
                                      ? AppColors.accentDark
                                      : AppColors.accentLight)
                                  : (isDark
                                      ? AppColors.primaryDark
                                      : AppColors.primaryLight),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Show quantity for bonus items
                          if (item.isBonus && item.quantity > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.accentDark
                                        .withValues(alpha: 0.2)
                                    : AppColors.accentLight
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "x${item.quantity}",
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.accentDark
                                      : AppColors.accentLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.name.isNotEmpty)
                        Text(
                          item.name,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (hasDiscount)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "-$discountPercentage%",
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Price rows
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Pricelist row
                _buildPriceRow(
                  context,
                  label: "Pricelist",
                  value: item.pricelist,
                  icon: Icons.sell_outlined,
                  iconColor: AppColors.textSecondaryLight,
                  isStrikethrough: hasDiscount,
                  isDark: isDark,
                ),
                const SizedBox(height: AppPadding.p8),

                // End User Price row
                _buildPriceRow(
                  context,
                  label: "End User Price",
                  value: item.endUserPrice,
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.success,
                  valueColor: AppColors.success,
                  isBold: true,
                  isDark: isDark,
                ),

                // Discount savings
                if (hasDiscount) ...[
                  const SizedBox(height: AppPadding.p8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.savings_outlined,
                          color: AppColors.error,
                          size: 14,
                        ),
                        const SizedBox(width: AppPadding.p6),
                        Text(
                          "Hemat ${FormatHelper.formatCurrency(discountAmount)}",
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    required String label,
    required double value,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    Color? valueColor,
    bool isStrikethrough = false,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: AppPadding.p8),
        Text(
          label,
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textPrimaryLight,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          FormatHelper.formatCurrency(
              value), // Always show currency, even for 0
          style: TextStyle(
            color: valueColor ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            decorationColor: valueColor ?? AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(BuildContext context, bool isDark) {
    // Calculate total pricelist including bonus items
    final totalBonusPricelist = product.bonus.fold<double>(
      0,
      (sum, bonus) => sum + bonus.pricelist,
    );
    final totalPricelist = product.plKasur +
        product.plDivan +
        product.plHeadboard +
        product.plSorong +
        totalBonusPricelist;
    // EUP for bonus is 0 (free), so don't add it to totalEup
    final totalEup = product.eupKasur +
        product.eupDivan +
        product.eupHeadboard +
        product.eupSorong;
    final totalSavings = totalPricelist - totalEup;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.success.withValues(alpha: 0.15),
                  AppColors.success.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.success.withValues(alpha: 0.1),
                  AppColors.success.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Total pricelist
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  color: AppColors.textSecondaryLight, size: 18),
              const SizedBox(width: AppPadding.p8),
              Text(
                "Total Pricelist",
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                FormatHelper.formatCurrency(totalPricelist),
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 14,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPadding.p12),

          // Total EUP
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppPadding.p8),
              const Text(
                "Total End User Price",
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                FormatHelper.formatCurrency(totalEup),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Total savings
          if (totalSavings > 0) ...[
            const SizedBox(height: AppPadding.p12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppPadding.p6),
                  Text(
                    "Total Hemat ${FormatHelper.formatCurrency(totalSavings)}",
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build list of pricing items from product data
  List<_PricingItem> _buildPricingItems() {
    final items = <_PricingItem>[];

    // Helper to check if value is valid
    bool isValidItem(String name) {
      if (name.isEmpty) return false;
      if (name.trim() == '-') return false;
      if (name.trim().toLowerCase().startsWith('tanpa')) return false;
      return true;
    }

    // Helper to check if bonus is valid
    bool isValidBonus(String name, int qty) {
      if (name.isEmpty) return false;
      if (name.trim() == '0') return false;
      if (name.trim() == '-') return false;
      if (qty <= 0) return false;
      return true;
    }

    // Kasur
    if (isValidItem(product.kasur) ||
        product.plKasur > 0 ||
        product.eupKasur > 0) {
      items.add(_PricingItem(
        label: "Kasur",
        name: isValidItem(product.kasur) ? product.kasur : "",
        pricelist: product.plKasur,
        endUserPrice: product.eupKasur,
        icon: Icons.bed_rounded,
      ));
    }

    // Divan
    if (isValidItem(product.divan) ||
        product.plDivan > 0 ||
        product.eupDivan > 0) {
      items.add(_PricingItem(
        label: "Divan",
        name: isValidItem(product.divan) ? product.divan : "",
        pricelist: product.plDivan,
        endUserPrice: product.eupDivan,
        icon: Icons.chair_rounded,
      ));
    }

    // Headboard
    if (isValidItem(product.headboard) ||
        product.plHeadboard > 0 ||
        product.eupHeadboard > 0) {
      items.add(_PricingItem(
        label: "Headboard",
        name: isValidItem(product.headboard) ? product.headboard : "",
        pricelist: product.plHeadboard,
        endUserPrice: product.eupHeadboard,
        icon: Icons.view_headline_rounded,
      ));
    }

    // Sorong
    if (isValidItem(product.sorong) ||
        product.plSorong > 0 ||
        product.eupSorong > 0) {
      items.add(_PricingItem(
        label: "Sorong",
        name: isValidItem(product.sorong) ? product.sorong : "",
        pricelist: product.plSorong,
        endUserPrice: product.eupSorong,
        icon: Icons.drag_handle_rounded,
      ));
    }

    // Add bonus items with pricelist
    for (int i = 0; i < product.bonus.length; i++) {
      final bonus = product.bonus[i];
      // Only add bonus with valid name and quantity, or has pricelist
      if (isValidBonus(bonus.name, bonus.quantity) || bonus.pricelist > 0) {
        items.add(_PricingItem(
          label: "Bonus ${i + 1}",
          name: bonus.name,
          pricelist: bonus.pricelist,
          endUserPrice: 0, // Bonus is free (100% discount)
          icon: Icons.card_giftcard_rounded,
          isBonus: true,
          quantity: bonus.quantity,
        ));
      }
    }

    return items;
  }
}

/// Internal class to hold pricing item data
class _PricingItem {
  final String label;
  final String name;
  final double pricelist;
  final double endUserPrice;
  final IconData icon;
  final bool isBonus;
  final int quantity; // For bonus items

  const _PricingItem({
    required this.label,
    required this.name,
    required this.pricelist,
    required this.endUserPrice,
    required this.icon,
    this.isBonus = false,
    this.quantity = 1,
  });
}
