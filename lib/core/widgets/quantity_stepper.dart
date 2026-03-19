import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable horizontal quantity stepper with minus/plus actions.
///
/// Function:
/// - Menstandarkan kontrol perubahan jumlah item (`- qty +`) di UI.
/// - Mendukung icon khusus saat kuantitas minimum (mis. icon delete).
/// - Mengurangi duplikasi layout border, radius, dan spacing untuk stepper.
class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final IconData decrementIcon;
  final Color decrementIconColor;
  final IconData incrementIcon;
  final Color incrementIconColor;
  final TextStyle? quantityTextStyle;
  final EdgeInsetsGeometry buttonPadding;
  final EdgeInsetsGeometry quantityPadding;
  final Color borderColor;
  final double borderRadius;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementIcon = Icons.remove,
    this.decrementIconColor = AppColors.textPrimary,
    this.incrementIcon = Icons.add,
    this.incrementIconColor = AppColors.textPrimary,
    this.quantityTextStyle,
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.quantityPadding = const EdgeInsets.symmetric(horizontal: 8),
    this.borderColor = AppColors.border,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.horizontal(left: radius),
            child: Padding(
              padding: buttonPadding,
              child: Icon(decrementIcon, size: 16, color: decrementIconColor),
            ),
          ),
          Padding(
            padding: quantityPadding,
            child: Text(
              '$quantity',
              style:
                  quantityTextStyle ??
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.horizontal(right: radius),
            child: Padding(
              padding: buttonPadding,
              child: Icon(incrementIcon, size: 16, color: incrementIconColor),
            ),
          ),
        ],
      ),
    );
  }
}
