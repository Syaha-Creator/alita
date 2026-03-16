import 'package:flutter/material.dart';

import '../../../../core/widgets/detail_payment_item_row.dart';
import '../../../../core/widgets/detail_payments_section.dart';
import '../../../../core/widgets/detail_section_label.dart';
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

    final items = <Widget>[
      if (order.payments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'Belum ada riwayat pembayaran.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
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
      if (remaining > 0)
        OutlinedButton.icon(
          onPressed: onTapAddPayment,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Tambah Pembayaran'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            foregroundColor: const Color(0xFF0F766E),
            side: const BorderSide(color: Color(0xFF5EEAD4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
    ];

    return DetailSurfaceCard(
      child: DetailPaymentsSection(
        header: const DetailSectionLabel(title: 'Informasi Pembayaran'),
        items: items,
      ),
    );
  }
}
