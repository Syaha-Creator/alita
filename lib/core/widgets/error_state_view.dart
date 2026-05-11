import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable error state with optional retry action.
///
/// Function:
/// - Menampilkan error secara konsisten (icon, title, message).
/// - Menyediakan tombol retry yang bisa dipakai ulang lintas halaman.
/// - Mengurangi duplikasi blok `Center + Column + ElevatedButton`.
///
/// After the retry button is tapped, the button switches to a loading spinner
/// so the user has immediate feedback. The loading state auto-resets after 8s
/// as a safety net if the parent hasn't unmounted the widget (e.g. fast re-error).
class ErrorStateView extends StatefulWidget {
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
    this.buttonColor = AppColors.accent,
    this.buttonTextColor = AppColors.onPrimary,
    this.padding = const EdgeInsets.all(24),
    this.titleStyle,
    this.messageStyle,
  });

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry?.call();
    // Safety reset in case the parent widget hasn't unmounted yet
    // (e.g. provider returns error again very quickly).
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _isRetrying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: ${widget.title}. ${widget.message}',
      child: Center(
        child: Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 56, color: widget.iconColor),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: widget.titleStyle ??
                    const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: widget.messageStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
              ),
              if (widget.onRetry != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _isRetrying ? null : _handleRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.buttonColor,
                      foregroundColor: widget.buttonTextColor,
                      disabledBackgroundColor:
                          widget.buttonColor.withValues(alpha: 0.6),
                      disabledForegroundColor:
                          widget.buttonTextColor.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isRetrying
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    widget.buttonTextColor),
                              ),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(widget.retryLabel),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
