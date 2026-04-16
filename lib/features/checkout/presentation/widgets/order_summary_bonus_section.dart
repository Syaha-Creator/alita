import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../cart/data/cart_item.dart';
import 'bonus_takeaway_control.dart';

/// Bonus / Aksesoris section in checkout order summary: title + list of
/// [BonusTakeAwayControl]. State (checked, qty) and callbacks live in parent.
///
/// Jika [splitControlsEnabled] false (barang utama bawa sendiri), bonus hanya
/// ditampilkan sebagai teks — semua qty ikut bawa.
class OrderSummaryBonusSection extends StatelessWidget {
  final List<CartBonusSnapshot> bonuses;
  final int itemQuantity;
  final bool Function(CartBonusSnapshot) isChecked;
  final int Function(CartBonusSnapshot) currentTakeAwayQty;
  final void Function(CartBonusSnapshot, bool) onCheckedChanged;
  final void Function(CartBonusSnapshot, int) onSetTakeAwayQty;
  final bool splitControlsEnabled;

  const OrderSummaryBonusSection({
    super.key,
    required this.bonuses,
    this.itemQuantity = 1,
    required this.isChecked,
    required this.currentTakeAwayQty,
    required this.onCheckedChanged,
    required this.onSetTakeAwayQty,
    this.splitControlsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = bonuses.where((b) => b.name.trim().isNotEmpty).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[
      const Text(
        'Bonus / Aksesoris:',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppLayoutTokens.space10),
    ];

    if (!splitControlsEnabled) {
      children.add(
        Text(
          'Semua bonus ikut bawa sendiri (sama barang utama).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
        ),
      );
      children.add(const SizedBox(height: AppLayoutTokens.space8));
      for (var i = 0; i < filtered.length; i++) {
        if (i > 0) {
          children.add(const SizedBox(height: AppLayoutTokens.space10));
        }
        final bonus = filtered[i];
        final effectiveQty = bonus.qty * itemQuantity;
        children.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$effectiveQty× ${bonus.name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SKU: ${bonus.sku.isNotEmpty ? bonus.sku : '—'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      for (var i = 0; i < filtered.length; i++) {
        if (i > 0) {
          children.add(const SizedBox(height: AppLayoutTokens.space10));
        }
        final bonus = filtered[i];
        final effectiveQty = bonus.qty * itemQuantity;
        final takeAway = currentTakeAwayQty(bonus);
        children.add(
          BonusTakeAwayControl(
            name: bonus.name,
            sku: bonus.sku,
            totalQty: effectiveQty,
            isChecked: isChecked(bonus),
            currentTakeAway: takeAway,
            onCheckedChanged: (value) => onCheckedChanged(bonus, value),
            onDecrement: takeAway > 0
                ? () => onSetTakeAwayQty(bonus, takeAway - 1)
                : null,
            onIncrement: takeAway < effectiveQty
                ? () => onSetTakeAwayQty(bonus, takeAway + 1)
                : null,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
