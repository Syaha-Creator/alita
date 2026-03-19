import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/app_feedback.dart';
import '../utils/log.dart';
import 'loading_overlay.dart';

/// A reusable bottom sheet for print/share PDF actions.
///
/// Usage:
/// ```dart
/// PdfActionSheet.show(
///   context: context,
///   label: 'Customer',
///   onPrint: () => InvoicePdfGenerator.generateExternalPdfFromOrder(order),
///   onShare: () => InvoicePdfGenerator.shareExternalPdfFromOrder(order),
/// );
/// ```
class PdfActionSheet {
  PdfActionSheet._();

  static void show(
    BuildContext context, {
    required String label,
    required Future<void> Function() onPrint,
    required Future<void> Function() onShare,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Surat Pesanan ($label)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PdfActionButton(
                      icon: Icons.print_rounded,
                      label: 'Cetak PDF',
                      color: AppColors.accent,
                      onTap: () {
                        Navigator.pop(ctx);
                        _executePdfAction(context, action: onPrint);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PdfActionButton(
                      icon: Icons.share_rounded,
                      label: 'Bagikan PDF',
                      color: AppColors.success,
                      onTap: () {
                        Navigator.pop(ctx);
                        _executePdfAction(context, action: onShare);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _executePdfAction(
    BuildContext context, {
    required Future<void> Function() action,
  }) async {
    _showLoadingDialog(context);
    await Future.delayed(Duration.zero);
    try {
      await action();
    } catch (e, st) {
      Log.error(e, st, reason: 'PdfActionSheet.executePdfAction');
      if (context.mounted) {
        AppFeedback.show(
          context,
          message: 'Gagal membuat PDF: $e',
          type: AppFeedbackType.error,
          floating: true,
        );
      }
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    LoadingOverlay.show(
      context,
      title: 'Membuat PDF...',
      subtitle: 'Harap tunggu sebentar',
    );
  }
}

class _PdfActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PdfActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
