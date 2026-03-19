import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/widgets/detail_payment_item_row.dart';
import '../../../../core/widgets/detail_payments_section.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../../../core/widgets/image_viewer_dialog.dart';

/// Payments info card for the approval detail page.
///
/// Lists each payment entry (method, bank, amount) with an optional
/// receipt image thumbnail that opens [ImageViewerDialog] on tap.
class ApprovalPaymentsCard extends StatelessWidget {
  final List<dynamic> payments;

  const ApprovalPaymentsCard({
    super.key,
    required this.payments,
  });

  static String _fmt(num value) => AppFormatters.currencyIdr(value);

  @override
  Widget build(BuildContext context) {
    final paymentItems = payments.map((entry) {
      final p = entry as Map<String, dynamic>;
      final method = p['payment_method']?.toString() ?? '-';
      final bank = p['payment_bank']?.toString() ?? '-';
      final amount = double.tryParse(p['payment_amount']?.toString() ?? '0') ?? 0;
      final imageUrl = p['image']?.toString() ?? '';
      return DetailPaymentItemRow(
        method: method,
        bank: bank,
        amountText: _fmt(amount),
        receiptImageUrl: imageUrl,
        onTapReceipt:
            imageUrl.isNotEmpty ? () => _showImageDialog(context, imageUrl) : null,
      );
    }).toList();

    return DetailSurfaceCard(
      child: DetailPaymentsSection(
        items: paymentItems.isEmpty
            ? const [
                _EmptyPaymentState(),
              ]
            : paymentItems,
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    ImageViewerDialog.show(
      context: context,
      imageUrl: imageUrl,
      borderRadius: 12,
    );
  }
}

class _EmptyPaymentState extends StatelessWidget {
  const _EmptyPaymentState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 32,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: 10),
          Text(
            'Belum ada riwayat pembayaran',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
