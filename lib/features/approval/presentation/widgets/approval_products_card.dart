import 'package:flutter/material.dart';

import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/discount_formatter.dart';
import '../../../../core/widgets/detail_bonus_items_section.dart';
import '../../../../core/widgets/detail_discount_block.dart';
import '../../../../core/widgets/detail_item_index_badge.dart';
import '../../../../core/widgets/detail_pricelist_tags.dart';
import '../../../../core/widgets/detail_section_label.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/detail_totals_summary_section.dart';
import '../../logic/approval_inbox_utils.dart';

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

  static bool _isBonusRow(Map<String, dynamic> d) =>
      (d['item_type']?.toString() ?? '').toLowerCase().contains('bonus');

  @override
  Widget build(BuildContext context) {
    final postage = double.tryParse(order['postage']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(order['extended_amount']?.toString() ?? '0') ?? 0;

    // `order_letter_details` menandai bonus lewat `item_type: 'bonus'` — bukan
    // field `bonus_N`/`qty_bonusN` (itu field katalog produk, beda payload).
    // Baris bonus harus dipisah dari daftar utama, bukan ikut dinomori.
    // Urutan utama mengikuti `line_number` (urutan input checkout).
    final mainDetails = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> bonusItems = [];
    for (final detail in sortOrderLetterDetailsByLineNumber(details)) {
      final d = detail;
      if (_isBonusRow(d)) {
        final name = (d['item_description']?.toString().trim().isNotEmpty ??
                false)
            ? d['item_description'].toString().trim()
            : (d['desc_1']?.toString() ?? 'Bonus');
        bonusItems.add({'name': name, 'qty': d['qty'] ?? 1});
      } else {
        mainDetails.add(d);
      }
    }

    return DetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(title: 'Rincian Barang & Approval Diskon'),
          const SizedBox(height: 14),
          ...mainDetails.asMap().entries.map((entry) {
            final idx = entry.key;
            final detail = entry.value;

            final rawDesc = (detail['item_description'] as String? ?? '').trim();
            final name = rawDesc.isNotEmpty
                ? rawDesc
                : (detail['desc_1'] as String? ?? '-');
            final qty = detail['qty']?.toString() ?? '-';
            final netPrice =
                double.tryParse(detail['net_price']?.toString() ?? '0') ?? 0;
            final discounts =
                detail['order_letter_discount'] as List<dynamic>? ?? [];
            final pricelistType =
                (detail['pricelist_type'] as String? ?? '').trim();
            final pricelistArea =
                (detail['pricelist_area'] as String? ?? '').trim();

            return Container(
              padding: const EdgeInsets.all(12),
              margin:
                  EdgeInsets.only(bottom: idx == mainDetails.length - 1 ? 0 : 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              netPrice == 0 ? 'GRATIS' : _fmt(netPrice.round()),
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
                        if (pricelistType.isNotEmpty ||
                            pricelistArea.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          DetailPricelistTags(
                            type: pricelistType,
                            area: pricelistArea,
                          ),
                        ],
                        if (discounts.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDiscountBlock(discounts),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          if (bonusItems.isNotEmpty) ...[
            DetailBonusItemsSection(
              rows: bonusItems
                  .map((b) => DetailBonusChip(label: '${b['qty']}x ${b['name']}'))
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
    final sorted = List<dynamic>.from(discounts)
      ..sort((a, b) {
        final aMap = a as Map<String, dynamic>;
        final bMap = b as Map<String, dynamic>;
        final aLevel =
            (aMap['approver_level_id'] as num?)?.toInt() ?? 999;
        final bLevel =
            (bMap['approver_level_id'] as num?)?.toInt() ?? 999;
        if (aLevel != bLevel) return aLevel.compareTo(bLevel);
        final aId =
            (aMap['order_letter_discount_id'] as num?)?.toInt() ?? 0;
        final bId =
            (bMap['order_letter_discount_id'] as num?)?.toInt() ?? 0;
        return aId.compareTo(bId);
      });
    return DetailDiscountBlock(
      rows: sorted.map((disc) => _buildDiscountRow(disc)).toList(),
    );
  }

  Widget _buildDiscountRow(dynamic disc) {
    // `approved` bisa datang sebagai bool dari API (bukan hanya String) —
    // cast langsung ke String? melempar TypeCastError dan crash card ini.
    final statusEnum = OrderStatusX.fromDynamic(disc['approved']);
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
