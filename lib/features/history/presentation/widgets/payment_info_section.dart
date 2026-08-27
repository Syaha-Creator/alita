import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
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
    this.onTapPayPaper,
  });

  final OrderHistory order;
  final VoidCallback onTapAddPayment;
  final void Function(String imageUrl) onTapReceipt;
  final String Function(num) currencyFormatter;

  /// Opens Paper.id invoice for an unpaid Paper payment row.
  final void Function(OrderPayment payment)? onTapPayPaper;

  @override
  Widget build(BuildContext context) {
    // Paper unpaid tetap tampil (status + tombol bayar). Legacy rejected
    // (`verified == false`) tetap disembunyikan.
    final visiblePayments =
        order.payments.where((p) => p.isVisibleInPaymentHistory).toList();
    final totalPaid = visiblePayments
        .where((p) => p.countsTowardTotal)
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final remaining =
        (order.totalAmount - totalPaid).clamp(0.0, double.infinity);
    final hasUnpaidPaper = visiblePayments.any((p) => p.isPaperUnpaid);

    if (visiblePayments.isEmpty && remaining <= 0) {
      return const SizedBox.shrink();
    }

    final paymentItems = <Widget>[
      if (visiblePayments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppLayoutTokens.space20 + AppLayoutTokens.space4,
            horizontal: AppLayoutTokens.space16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius16 - 2),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  size: 32, color: AppColors.textTertiary),
              SizedBox(height: AppLayoutTokens.space10),
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
      ...visiblePayments.map(
        (payment) => DetailPaymentItemRow(
          method: payment.method,
          bank: payment.bank,
          amountText: currencyFormatter(payment.amount),
          receiptImageUrl: payment.image,
          verified: payment.verified ?? false,
          paperStatusLabel:
              payment.isPaperPayment ? payment.paperStatusLabel : null,
          paperStatusPaid: payment.isPaperPaid,
          onPayViaPaper: payment.canPayViaPaper && onTapPayPaper != null
              ? () => onTapPayPaper!(payment)
              : null,
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
      // Saat masih ada invoice Paper unpaid, arahkan user ke Paper dulu —
      // jangan buka form multipart "Tambah Pembayaran".
      onTapAddPayment:
          remaining > 0 && !hasUnpaidPaper ? onTapAddPayment : null,
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
          padding: const EdgeInsets.all(AppLayoutTokens.space14),
          decoration: BoxDecoration(
            color: isFullyPaid
                ? AppColors.success.withValues(alpha: 0.06)
                : AppColors.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius10 + 2),
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
                      color:
                          isFullyPaid ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!isFullyPaid) ...[
                const SizedBox(height: AppLayoutTokens.space8),
                Container(
                    height: 1, color: AppColors.border.withValues(alpha: 0.5)),
                const SizedBox(height: AppLayoutTokens.space8),
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
                const SizedBox(height: AppLayoutTokens.space6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    SizedBox(width: AppLayoutTokens.space4),
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
          const SizedBox(height: AppLayoutTokens.space12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTapAddPayment,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Pembayaran'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(
                  vertical: AppLayoutTokens.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayoutTokens.radius10 + 2),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
