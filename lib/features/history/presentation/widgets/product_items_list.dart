import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/discount_formatter.dart';
import '../../../../core/widgets/detail_bonus_items_section.dart';
import '../../../../core/widgets/detail_discount_block.dart';
import '../../../../core/widgets/detail_item_index_badge.dart';
import '../../../../core/widgets/detail_section_label.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/detail_totals_summary_section.dart';
import '../../data/models/order_history.dart';

class ProductItemsList extends StatelessWidget {
  const ProductItemsList({
    super.key,
    required this.order,
    required this.currencyFormatter,
  });

  final OrderHistory order;
  final String Function(num) currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final sorted = _buildSortedItems();

    return DetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(title: 'Rincian Produk'),
          const SizedBox(height: 14),
          ...sorted.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == sorted.length - 1 && order.bonusItems.isEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailItemIndexBadge(index: idx + 1),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.qty}x ${item.desc1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.brand.isNotEmpty)
                                      Text(
                                        item.brand,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textTertiary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PriceColumn(
                                item: item,
                                currencyFormatter: currencyFormatter,
                              ),
                            ],
                          ),
                          if (item.discounts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _DiscountRows(discounts: item.discounts),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 14),
                  Container(height: 1, color: AppColors.divider),
                  const SizedBox(height: 14),
                ],
              ],
            );
          }),
          if (order.bonusItems.isNotEmpty)
            _CollapsibleBonusSection(bonusItems: order.bonusItems),
          DetailTotalsSummarySection(
            postageText: currencyFormatter(order.postage),
            totalText: currencyFormatter(order.totalAmount),
          ),
        ],
      ),
    );
  }

  List<OrderDetail> _buildSortedItems() =>
      List<OrderDetail>.from(order.mainItems)
        ..sort((a, b) {
          final brandCompare = a.brand.compareTo(b.brand);
          if (brandCompare != 0) return brandCompare;
          return _typeWeight(a.itemType).compareTo(_typeWeight(b.itemType));
        });

  static int _typeWeight(String? type) {
    if (type == null || type.isEmpty) return 99;
    final lower = type.toLowerCase();
    if (lower.contains('mattress') || lower.contains('kasur')) return 1;
    if (lower.contains('divan')) return 2;
    if (lower.contains('headboard') || lower.contains('sandaran')) return 3;
    return 4;
  }
}

// ── Collapsible Bonus ──────────────────────────────────────────

const int _kBonusCollapseThreshold = 5;
const int _kBonusVisibleWhenCollapsed = 3;

class _CollapsibleBonusSection extends StatefulWidget {
  const _CollapsibleBonusSection({required this.bonusItems});

  final List<OrderDetail> bonusItems;

  @override
  State<_CollapsibleBonusSection> createState() =>
      _CollapsibleBonusSectionState();
}

class _CollapsibleBonusSectionState extends State<_CollapsibleBonusSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final items = widget.bonusItems;
    final shouldCollapse = items.length > _kBonusCollapseThreshold;
    final visibleItems = shouldCollapse && !_expanded
        ? items.take(_kBonusVisibleWhenCollapsed).toList()
        : items;
    final hiddenCount = items.length - _kBonusVisibleWhenCollapsed;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: DetailBonusItemsSection(
      rows: [
        ...visibleItems.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 2),
                const Text(
                  '·  ',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${b.qty}x ${b.desc1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (b.isTakeAway) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Bawa Langsung',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (shouldCollapse)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded
                        ? 'Sembunyikan'
                        : 'Lihat $hiddenCount item lainnya',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    );
  }
}

// ── Price Column ───────────────────────────────────────────────

class _PriceColumn extends StatelessWidget {
  const _PriceColumn({
    required this.item,
    required this.currencyFormatter,
  });

  final OrderDetail item;
  final String Function(num) currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final bool hasApprovalDiscount =
        item.netPrice > 0 && item.netPrice < item.customerPrice;

    final double finalPrice =
        hasApprovalDiscount ? item.netPrice : item.customerPrice;

    // Strikethrough always uses the catalog pricelist (unitPrice),
    // regardless of whether the discount came from manual EUP or approval.
    final double originalPrice = item.unitPrice;

    final bool showStrikethrough =
        originalPrice > finalPrice && originalPrice > 0;
    final bool isFree = finalPrice == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showStrikethrough)
          Text(
            currencyFormatter(originalPrice.round()),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        Text(
          isFree ? 'GRATIS' : currencyFormatter(finalPrice.round()),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isFree ? AppColors.success : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Discount Rows ──────────────────────────────────────────────

class _DiscountRows extends StatelessWidget {
  const _DiscountRows({required this.discounts});

  final List<OrderDiscount> discounts;

  @override
  Widget build(BuildContext context) {
    return DetailDiscountBlock(
      rows: discounts.map((disc) {
        final color =
            OrderStatusX.fromRaw(disc.approvedStatus).detailForegroundColor;
        final icon = OrderStatusX.fromRaw(disc.approvedStatus).icon;
        final pctStr = DiscountFormatter.percentLabel(disc.discountVal);

        return DetailDiscountRow(
          icon: icon,
          color: color,
          leadingValue: SizedBox(
            width: 40,
            child: Text(
              pctStr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          approverName: disc.approverName,
        );
      }).toList(),
    );
  }
}
