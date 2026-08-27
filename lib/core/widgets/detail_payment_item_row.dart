import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';
import 'status_chip.dart';

/// Reusable payment row item for detail pages.
class DetailPaymentItemRow extends StatelessWidget {
  final String method;
  final String bank;
  final String amountText;
  final String receiptImageUrl;
  final bool verified;
  final VoidCallback? onTapReceipt;

  /// Optional Paper.id status label (e.g. "Belum bayar" / "Sudah bayar").
  final String? paperStatusLabel;
  final bool paperStatusPaid;
  final VoidCallback? onPayViaPaper;

  const DetailPaymentItemRow({
    super.key,
    required this.method,
    required this.bank,
    required this.amountText,
    required this.receiptImageUrl,
    this.verified = false,
    this.onTapReceipt,
    this.paperStatusLabel,
    this.paperStatusPaid = false,
    this.onPayViaPaper,
  });

  IconData get _methodIcon {
    final m = method.toLowerCase();
    if (m.contains('paper')) return Icons.link_rounded;
    if (m.contains('cash') || m.contains('tunai')) return Icons.payments_rounded;
    if (m.contains('giro')) return Icons.receipt_long_rounded;
    return Icons.account_balance_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt = receiptImageUrl.isNotEmpty;
    final paperLabel = paperStatusLabel?.trim() ?? '';
    final showPaperStatus = paperLabel.isNotEmpty;

    return Semantics(
      container: true,
      label: '$method $amountText',
      child: Container(
        padding: const EdgeInsets.all(AppLayoutTokens.space14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius16 - 2),
          border: Border.all(
            color: (verified || paperStatusPaid)
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.border,
          ),
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
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.radius10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_methodIcon, size: 20, color: AppColors.accent),
                ),
                const SizedBox(width: AppLayoutTokens.space14),
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
                      if (showPaperStatus) ...[
                        const SizedBox(height: AppLayoutTokens.space4),
                        StatusChip(
                          label: paperLabel,
                          icon: paperStatusPaid
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          backgroundColor: paperStatusPaid
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                          foregroundColor: paperStatusPaid
                              ? AppColors.success
                              : AppColors.warning,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppLayoutTokens.space8,
                            vertical: AppLayoutTokens.space4,
                          ),
                          borderRadius: AppLayoutTokens.radius10,
                        ),
                      ] else if (verified) ...[
                        const SizedBox(height: AppLayoutTokens.space4),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                size: 12, color: AppColors.success),
                            SizedBox(width: 3),
                            Text(
                              'Terverifikasi',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
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
            if (onPayViaPaper != null) ...[
              const SizedBox(height: AppLayoutTokens.space12),
              GestureDetector(
                onTap: onPayViaPaper,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppLayoutTokens.space10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.radius10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 16, color: AppColors.accent),
                      SizedBox(width: AppLayoutTokens.space6),
                      Text(
                        'Bayar via Paper.id',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (hasReceipt) ...[
              const SizedBox(height: AppLayoutTokens.space12),
              GestureDetector(
                onTap: onTapReceipt,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppLayoutTokens.space10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.radius10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_rounded,
                          size: 16, color: AppColors.accent),
                      SizedBox(width: AppLayoutTokens.space6),
                      Text(
                        'Lihat Bukti Transfer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: AppLayoutTokens.space4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.accent),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
