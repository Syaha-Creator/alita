import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/platform_utils.dart';

/// Direct (S1) payment mode: default manual form, opt-in to Paper.id.
///
/// Shown only when checkout channel can opt into Paper (not MM / not indirect).
///
/// - Manual: prominent [onSelectPaper] CTA.
/// - Paper: short explainer + [onSelectManual] to return to the receipt form.
class CheckoutDirectPaymentModePanel extends StatelessWidget {
  const CheckoutDirectPaymentModePanel({
    super.key,
    required this.usePaper,
    required this.onSelectPaper,
    required this.onSelectManual,
  });

  final bool usePaper;
  final VoidCallback onSelectPaper;
  final VoidCallback onSelectManual;

  @override
  Widget build(BuildContext context) {
    if (!usePaper) {
      return Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () {
            hapticTap();
            onSelectPaper();
          },
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayoutTokens.space16,
              vertical: AppLayoutTokens.space14,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
              boxShadow: [AppLayoutTokens.cardShadowSoft],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 22,
                  color: AppColors.accent,
                ),
                SizedBox(width: AppLayoutTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bayar via Paper.id',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Buat invoice online otomatis setelah SP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppLayoutTokens.space8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppLayoutTokens.space16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppLayoutTokens.radius8),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppLayoutTokens.space12),
              Expanded(
                child: Text(
                  'Pembayaran via Paper.id',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayoutTokens.space12),
          Text(
            'Invoice Paper.id akan dibuat otomatis setelah Surat Pesanan berhasil. '
            'Tidak perlu upload bukti pembayaran di sini.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: AppLayoutTokens.space12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                hapticTap();
                onSelectManual();
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Kembali ke pembayaran manual'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppLayoutTokens.space12,
                  horizontal: AppLayoutTokens.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayoutTokens.radius10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
