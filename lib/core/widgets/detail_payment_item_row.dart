import 'package:flutter/material.dart';

/// Reusable payment row item for detail pages.
class DetailPaymentItemRow extends StatelessWidget {
  final String method;
  final String bank;
  final String amountText;
  final String receiptImageUrl;
  final VoidCallback? onTapReceipt;

  const DetailPaymentItemRow({
    super.key,
    required this.method,
    required this.bank,
    required this.amountText,
    required this.receiptImageUrl,
    this.onTapReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final hasReceipt = receiptImageUrl.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.account_balance_rounded,
            size: 18,
            color: Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${method.toUpperCase()} · $bank',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (hasReceipt) ...[
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: onTapReceipt,
                  child: const Text(
                    'Lihat bukti transfer →',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          amountText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}
