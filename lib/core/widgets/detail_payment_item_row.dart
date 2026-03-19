import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

  IconData get _methodIcon {
    final m = method.toLowerCase();
    if (m.contains('cash') || m.contains('tunai')) return Icons.payments_rounded;
    if (m.contains('giro')) return Icons.receipt_long_rounded;
    return Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt = receiptImageUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: 0.12),
                      AppColors.accent.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(_methodIcon, size: 20, color: AppColors.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bank,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (hasReceipt) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onTapReceipt,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_rounded, size: 16, color: AppColors.accent),
                    SizedBox(width: 6),
                    Text(
                      'Lihat Bukti Transfer',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
