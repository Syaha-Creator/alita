import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/discount_formatter.dart';
import '../../../../core/widgets/detail_bonus_items_section.dart';
import '../../../../core/widgets/detail_discount_block.dart';
import '../../../../core/widgets/detail_item_index_badge.dart';
import '../../../../core/widgets/detail_section_label.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/detail_totals_summary_section.dart';

/// Products & discount approval card for the approval detail page.
///
/// Displays item list with discount blocks, bonus items, shipping cost,
/// and grand total. All data is read-only — no state mutations.
class ApprovalProductsCard extends StatelessWidget {
  final List<dynamic> details;
  final Map<String, dynamic> order;

  const ApprovalProductsCard({
    super.key,
    required this.details,
    required this.order,
  });

  static String _fmt(num value) => AppFormatters.currencyIdr(value);

  @override
  Widget build(BuildContext context) {
    final postage = double.tryParse(order['postage']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(order['extended_amount']?.toString() ?? '0') ?? 0;

    final List<Map<String, dynamic>> bonusItems = [];
    for (final detail in details) {
      final d = detail as Map<String, dynamic>;
      for (int i = 1; i <= 8; i++) {
        final bonusKey = 'bonus_$i';
        final qtyKey = 'qty_bonus$i';
        final bonusName = d[bonusKey] as String?;
        final bonusQty = d[qtyKey];
        if (bonusName != null && bonusName.isNotEmpty) {
          bonusItems.add({'name': bonusName, 'qty': bonusQty ?? 1});
        }
      }
    }

    return DetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(title: 'Rincian Barang & Approval Diskon'),
          const SizedBox(height: 14),
          ...details.asMap().entries.map((entry) {
            final idx = entry.key;
            final detail = entry.value as Map<String, dynamic>;
            final isLast = idx == details.length - 1 && bonusItems.isEmpty;

            final name = detail['desc_1'] as String? ??
                detail['item_description'] as String? ??
                '-';
            final brand = detail['desc_2'] as String? ??
                detail['sub_brand'] as String? ??
                '';
            final qty = detail['qty']?.toString() ?? '-';
            final netPrice =
                double.tryParse(detail['net_price']?.toString() ?? '0') ?? 0;
            final discounts =
                detail['order_letter_discount'] as List<dynamic>? ?? [];

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
                                      '${qty}x $name',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (brand.isNotEmpty)
                                      Text(
                                        brand,
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
                              Text(
                                netPrice == 0
                                    ? 'GRATIS'
                                    : _fmt(netPrice.round()),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: netPrice == 0
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (discounts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDiscountBlock(discounts),
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
          if (bonusItems.isNotEmpty) ...[
            DetailBonusItemsSection(
              rows: bonusItems
                  .map(
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
                            child: Text(
                              '${b['qty']}x ${b['name']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          DetailTotalsSummarySection(
            postageText: _fmt(postage),
            totalText: _fmt(totalAmount),
          ),
        ],
      ),
    );
  }

  // ── Discount helpers ──

  Widget _buildDiscountBlock(List<dynamic> discounts) {
    return DetailDiscountBlock(
      rows: discounts.map((disc) => _buildDiscountRow(disc)).toList(),
    );
  }

  Widget _buildDiscountRow(dynamic disc) {
    final status = disc['approved'] as String? ?? OrderStatus.pending.apiValue;
    final statusEnum = OrderStatusX.fromRaw(status);
    final color = statusEnum.detailForegroundColor;
    final icon = statusEnum.icon;
    final level = disc['approver_level'] as String? ?? '-';
    final name = disc['approver_name'] as String? ?? '-';
    final pctStr = DiscountFormatter.percentLabel(disc['discount']);

    return DetailDiscountRow(
      icon: icon,
      color: color,
      leadingValue: SizedBox(
        width: 90,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12),
            children: [
              TextSpan(
                text: level,
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              TextSpan(
                text: '  $pctStr',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      approverName: name,
    );
  }
}
