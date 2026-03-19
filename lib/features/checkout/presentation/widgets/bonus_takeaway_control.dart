import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/quantity_stepper.dart';

class BonusTakeAwayControl extends StatelessWidget {
  final String name;
  final String sku;
  final int totalQty;
  final bool isChecked;
  final int currentTakeAway;
  final ValueChanged<bool> onCheckedChanged;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const BonusTakeAwayControl({
    super.key,
    required this.name,
    required this.sku,
    required this.totalQty,
    required this.isChecked,
    required this.currentTakeAway,
    required this.onCheckedChanged,
    this.onDecrement,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = totalQty - currentTakeAway;
    final canDecrement = onDecrement != null && currentTakeAway > 0;
    final canIncrement = onIncrement != null && currentTakeAway < totalQty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (value) => onCheckedChanged(value ?? false),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalQty}x $name',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sku.isNotEmpty)
                      Text(
                        'SKU: $sku',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              if (isChecked)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Take Away',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (isChecked)
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Jumlah dibawa:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      QuantityStepper(
                        quantity: currentTakeAway,
                        onDecrement: canDecrement ? onDecrement! : () {},
                        onIncrement: canIncrement ? onIncrement! : () {},
                        decrementIcon: Icons.remove_circle_outline,
                        incrementIcon: Icons.add_circle_outline,
                        decrementIconColor: canDecrement
                            ? AppColors.textSecondary
                            : AppColors.border,
                        incrementIconColor: canIncrement
                            ? AppColors.textSecondary
                            : AppColors.border,
                      ),
                    ],
                  ),
                  if (remaining > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Sisa $remaining dikirim',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
