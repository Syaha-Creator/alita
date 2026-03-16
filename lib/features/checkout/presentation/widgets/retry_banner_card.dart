import 'package:flutter/material.dart';

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
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'SP $retryNoSp — $failedCount item gagal dikirim',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            failedLabels.map((e) => '• $e').join('\n'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
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
