import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/label_value_row.dart';
import 'retry_banner_card.dart';

/// Bottom bar di checkout: total pesanan, retry banner (opsional), tombol Buat Surat Pesanan.
class CheckoutBottomBar extends ConsumerWidget {
  final String totalFormatted;
  final bool showRetryBanner;
  final String retryNoSp;
  final int failedCount;
  final List<String> failedLabels;
  final VoidCallback onRetry;
  final VoidCallback onSubmit;
  final bool submitButtonEnabled;

  const CheckoutBottomBar({
    super.key,
    required this.totalFormatted,
    required this.showRetryBanner,
    required this.retryNoSp,
    required this.failedCount,
    required this.failedLabels,
    required this.onRetry,
    required this.onSubmit,
    this.submitButtonEnabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final canSubmit = submitButtonEnabled && !isOffline;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabelValueRow(
                label: 'Total Pesanan',
                value: totalFormatted,
                labelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                valueStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
              ),
              if (showRetryBanner) ...[
                const SizedBox(height: 12),
                RetryBannerCard(
                  retryNoSp: retryNoSp,
                  failedCount: failedCount,
                  failedLabels: failedLabels,
                  onRetry: onRetry,
                ),
              ],
              const SizedBox(height: 16),
              if (isOffline)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 14, color: AppColors.warning),
                      SizedBox(width: 6),
                      Text(
                        'Fungsi ini membutuhkan internet',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canSubmit ? onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Buat Surat Pesanan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
