import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../cart/data/cart_item.dart';
import 'bonus_takeaway_control.dart';

/// Bonus / Aksesoris section in checkout order summary: title + list of
/// [BonusTakeAwayControl]. State (checked, qty) and callbacks live in parent.
class OrderSummaryBonusSection extends StatelessWidget {
  final List<CartBonusSnapshot> bonuses;
  final bool Function(CartBonusSnapshot) isChecked;
  final int Function(CartBonusSnapshot) currentTakeAwayQty;
  final void Function(CartBonusSnapshot, bool) onCheckedChanged;
  final void Function(CartBonusSnapshot, int) onSetTakeAwayQty;

  const OrderSummaryBonusSection({
    super.key,
    required this.bonuses,
    required this.isChecked,
    required this.currentTakeAwayQty,
    required this.onCheckedChanged,
    required this.onSetTakeAwayQty,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = bonuses.where((b) => b.name.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        ),
        const Text(
          'Bonus / Aksesoris:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        ...filtered.map((bonus) {
          final currentTakeAway = currentTakeAwayQty(bonus);
          return BonusTakeAwayControl(
            name: bonus.name,
            sku: bonus.sku,
            totalQty: bonus.qty,
            isChecked: isChecked(bonus),
            currentTakeAway: currentTakeAway,
            onCheckedChanged: (value) => onCheckedChanged(bonus, value),
            onDecrement: currentTakeAway > 0
                ? () => onSetTakeAwayQty(bonus, currentTakeAway - 1)
                : null,
            onIncrement: currentTakeAway < bonus.qty
                ? () => onSetTakeAwayQty(bonus, currentTakeAway + 1)
                : null,
          );
        }),
      ],
    );
  }
}
