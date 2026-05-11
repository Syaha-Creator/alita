import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_card.dart';

/// Kartu "Persetujuan Surat Pesanan": loading, error+retry, atau [child] (dropdown SPV/ASM + Manager).
class CheckoutApprovalCard extends StatefulWidget {
  final bool isLoading;
  final bool hasError;

  /// Judul error; jika null dipakai fallback generik.
  final String? errorTitle;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Widget child;

  const CheckoutApprovalCard({
    super.key,
    required this.isLoading,
    required this.hasError,
    this.errorTitle,
    this.errorMessage,
    required this.onRetry,
    required this.child,
  });

  @override
  State<CheckoutApprovalCard> createState() => _CheckoutApprovalCardState();
}

class _CheckoutApprovalCardState extends State<CheckoutApprovalCard> {
  bool _isRetrying = false;

  @override
  void didUpdateWidget(CheckoutApprovalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent started loading → reset local retrying flag.
    if (widget.isLoading && !oldWidget.isLoading) {
      _isRetrying = false;
    }
    // Error cleared → reset too (in case parent resolved without loading phase).
    if (!widget.hasError && oldWidget.hasError) {
      _isRetrying = false;
    }
  }

  void _handleRetry() {
    if (_isRetrying || widget.isLoading) return;
    setState(() => _isRetrying = true);
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Persetujuan Surat Pesanan',
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading || _isRetrying) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      );
    }
    if (widget.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorTitle ?? 'Gagal memuat daftar approver.',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.errorMessage case final err? when err.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                err,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handleRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                minimumSize: const Size(120, 36),
              ),
            ),
          ],
        ),
      );
    }
    return widget.child;
  }
}
