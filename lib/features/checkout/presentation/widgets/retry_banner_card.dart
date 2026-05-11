import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Banner shown when some detail rows failed and can be retried.
class RetryBannerCard extends StatefulWidget {
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
  State<RetryBannerCard> createState() => _RetryBannerCardState();
}

class _RetryBannerCardState extends State<RetryBannerCard> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry();
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _isRetrying = false);
    });
  }

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
                  'SP ${widget.retryNoSp} — ${widget.failedCount} item gagal dikirim',
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
            widget.failedLabels.map((e) => '• $e').join('\n'),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _isRetrying ? null : _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor:
                    AppColors.warning.withValues(alpha: 0.6),
                disabledForegroundColor:
                    AppColors.onPrimary.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isRetrying
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.onPrimary),
                        ),
                      )
                    : const Row(
                        key: ValueKey('label'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Coba Lagi Kirim Barang Gagal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
