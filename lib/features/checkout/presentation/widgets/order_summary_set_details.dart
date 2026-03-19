import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Set component breakdown section shown in checkout order summary item.
class OrderSummarySetDetails extends StatelessWidget {
  final String divanLabel;
  final String divanSku;
  final bool showDivan;
  final String headboardLabel;
  final String headboardSku;
  final bool showHeadboard;
  final String sorongLabel;
  final String sorongSku;
  final bool showSorong;

  const OrderSummarySetDetails({
    super.key,
    required this.divanLabel,
    required this.divanSku,
    required this.showDivan,
    required this.headboardLabel,
    required this.headboardSku,
    required this.showHeadboard,
    required this.sorongLabel,
    required this.sorongSku,
    required this.showSorong,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1),
        ),
        const Text(
          'Rincian Set:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        if (showDivan) _skuRow(divanLabel, divanSku),
        if (showHeadboard) _skuRow(headboardLabel, headboardSku),
        if (showSorong) _skuRow(sorongLabel, sorongSku),
      ],
    );
  }

  Widget _skuRow(String label, String sku) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          '• $label  (SKU: ${sku.isNotEmpty ? sku : "—"})',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      );
}
