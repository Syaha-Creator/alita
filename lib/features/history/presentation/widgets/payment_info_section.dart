import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/detail_payment_item_row.dart';
import '../../../../core/widgets/detail_payments_section.dart';
import '../../../../core/widgets/detail_surface_card.dart';
import '../../data/models/order_history.dart';

class PaymentInfoSection extends StatelessWidget {
  const PaymentInfoSection({
    super.key,
    required this.order,
    required this.onTapAddPayment,
    required this.onTapReceipt,
    required this.currencyFormatter,
  });

  final OrderHistory order;
  final VoidCallback onTapAddPayment;
  final void Function(String imageUrl) onTapReceipt;
  final String Function(num) currencyFormatter;

  @override
  Widget build(BuildContext context) {
    final totalPaid =
        order.payments.fold<double>(0, (sum, payment) => sum + payment.amount);
    final remaining = (order.totalAmount - totalPaid).clamp(0.0, double.infinity);

    if (order.payments.isEmpty && remaining <= 0) {
      return const SizedBox.shrink();
    }

    final paymentItems = <Widget>[
      if (order.payments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 32, color: AppColors.textTertiary),
              SizedBox(height: 10),
              Text(
                'Belum ada riwayat pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tambahkan pembayaran pertama di bawah',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ...order.payments.map(
        (payment) => DetailPaymentItemRow(
          method: payment.method,
          bank: payment.bank,
          amountText: currencyFormatter(payment.amount),
          receiptImageUrl: payment.image,
          onTapReceipt: payment.image.isNotEmpty
              ? () => onTapReceipt(payment.image)
              : null,
        ),
      ),
    ];

    final summaryFooter = _PaymentSummaryFooter(
      totalPaid: totalPaid,
      remaining: remaining,
      currencyFormatter: currencyFormatter,
      onTapAddPayment: remaining > 0 ? onTapAddPayment : null,
    );

    return DetailSurfaceCard(
      child: DetailPaymentsSection(
        items: paymentItems,
        footer: summaryFooter,
      ),
    );
  }
}

class _PaymentSummaryFooter extends StatelessWidget {
  final double totalPaid;
  final double remaining;
  final String Function(num) currencyFormatter;
  final VoidCallback? onTapAddPayment;

  const _PaymentSummaryFooter({
    required this.totalPaid,
    required this.remaining,
    required this.currencyFormatter,
    this.onTapAddPayment,
  });

  @override
  Widget build(BuildContext context) {
    final isFullyPaid = remaining <= 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isFullyPaid
                ? AppColors.success.withValues(alpha: 0.06)
                : AppColors.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFullyPaid
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.warning.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Dibayar',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    currencyFormatter(totalPaid),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isFullyPaid ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!isFullyPaid) ...[
                const SizedBox(height: 8),
                Container(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Sisa Tagihan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      currencyFormatter(remaining),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
              if (isFullyPaid) ...[
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Lunas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        if (onTapAddPayment != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTapAddPayment,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Tambah Pembayaran'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
