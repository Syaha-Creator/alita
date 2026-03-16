import 'package:flutter/material.dart';
import 'action_button_bar.dart';
import '../theme/app_colors.dart';

/// Reusable error state with optional retry action.
///
/// Function:
/// - Menampilkan error secara konsisten (icon, title, message).
/// - Menyediakan tombol retry yang bisa dipakai ulang lintas halaman.
/// - Mengurangi duplikasi blok `Center + Column + ElevatedButton`.
class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Color iconColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  const ErrorStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = 'Coba Lagi',
    this.iconColor = AppColors.textTertiary,
    this.buttonColor = AppColors.primary,
    this.buttonTextColor = Colors.white,
    this.padding = const EdgeInsets.all(24),
    this.titleStyle,
    this.messageStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style:
                  titleStyle ??
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  messageStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ActionButtonBar(
                fullWidth: false,
                mainAxisSize: MainAxisSize.min,
                height: 42,
                borderRadius: 10,
                primaryLabel: retryLabel,
                primaryLeading: const Icon(Icons.refresh_rounded),
                primaryBackgroundColor: buttonColor,
                primaryForegroundColor: buttonTextColor,
                onPrimaryPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
