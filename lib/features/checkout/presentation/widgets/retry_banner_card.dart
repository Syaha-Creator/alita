import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Banner shown when some detail rows failed and can be retried.
class RetryBannerCard extends StatelessWidget {
  final String retryNoSp;
  final int failedCount;
  final List<String> failedLabels;
  final VoidCallback onRetry;

  const RetryBannerCard({
    super.key,
    required this.retryNoSp,
    required this.failedCount,
    required this.failedLabels,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SP $retryNoSp — $failedCount item gagal dikirim',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            failedLabels.map((e) => '• $e').join('\n'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text(
                'Coba Lagi Kirim Barang Gagal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
