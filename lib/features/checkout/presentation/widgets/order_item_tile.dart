import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../cart/data/cart_item.dart';
import 'order_summary_bonus_section.dart';
import 'order_summary_item_header.dart';
import 'order_summary_set_details.dart';

/// Single order item tile inside the checkout Order Summary card.
///
/// Displays item header, set details (divan/headboard/sorong), and optionally
/// bonus section with take-away controls. When [showBonusSection] is false,
/// bonus is rendered once in a combined section below all items.
class OrderItemTile extends StatelessWidget {
  final CartItem item;
  final String Function(num) priceFmt;
  final bool Function(CartBonusSnapshot) isBonusTakeAwayChecked;
  final int Function(CartBonusSnapshot) currentTakeAwayQty;
  final void Function(CartBonusSnapshot, bool) onTakeAwayToggled;
  final void Function(CartBonusSnapshot, int) onTakeAwayQtyChanged;
  /// When false, only header + set details are shown (bonus shown once below all items).
  final bool showBonusSection;

  const OrderItemTile({
    super.key,
    required this.item,
    required this.priceFmt,
    required this.isBonusTakeAwayChecked,
    required this.currentTakeAwayQty,
    required this.onTakeAwayToggled,
    required this.onTakeAwayQtyChanged,
    this.showBonusSection = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    final tipe = p.isSet ? 'Set Lengkap' : 'Matress Only';
    final configText = p.ukuran.isNotEmpty && !p.name.contains(p.ukuran)
        ? '${p.ukuran} · $tipe'
        : tipe;

    final hasSetComponents = p.isSet &&
        (item.divanSku.isNotEmpty ||
            item.sandaranSku.isNotEmpty ||
            item.sorongSku.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderSummaryItemHeader(
            imageUrl: p.imageUrl,
            name: p.name,
            configText: configText,
            kasurSku: item.kasurSku,
            quantity: item.quantity,
            totalPriceText: priceFmt(item.totalPrice),
          ),
          if (hasSetComponents) ...[
            OrderSummarySetDetails(
              divanLabel: p.divan,
              divanSku: item.divanSku,
              showDivan: item.divanSku.isNotEmpty &&
                  !p.divan.toLowerCase().contains('tanpa'),
              headboardLabel: p.headboard,
              headboardSku: item.sandaranSku,
              showHeadboard: item.sandaranSku.isNotEmpty &&
                  !p.headboard.toLowerCase().contains('tanpa'),
              sorongLabel: p.sorong,
              sorongSku: item.sorongSku,
              showSorong: item.sorongSku.isNotEmpty &&
                  !p.sorong.toLowerCase().contains('tanpa'),
            ),
          ],
          if (showBonusSection && item.bonusSnapshots.isNotEmpty)
            OrderSummaryBonusSection(
              bonuses: item.bonusSnapshots,
              isChecked: isBonusTakeAwayChecked,
              currentTakeAwayQty: currentTakeAwayQty,
              onCheckedChanged: onTakeAwayToggled,
              onSetTakeAwayQty: onTakeAwayQtyChanged,
            ),
        ],
      ),
    );
  }
}
