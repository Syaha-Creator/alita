import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Polished full-screen loading overlay.
///
/// Two modes:
/// - **Dialog** — call [LoadingOverlay.show] / [LoadingOverlay.dismiss].
///   Blocks interaction and is dismissed programmatically.
/// - **Inline** — embed [LoadingOverlay] directly inside a [Stack].
///   Controlled by a boolean flag in the parent widget.
class LoadingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;

  const LoadingOverlay({
    super.key,
    required this.title,
    this.subtitle,
  });

  // ── Dialog API ───────────────────────────────────────────────

  /// Show a modal loading overlay that blocks all interaction.
  static void show(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Loading',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
      pageBuilder: (_, __, ___) => PopScope(
        canPop: false,
        child: LoadingOverlay(title: title, subtitle: subtitle),
      ),
    );
  }

  /// Dismiss the topmost loading overlay shown via [show].
  static void dismiss(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Inline build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      liveRegion: true,
      child: Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
              if (subtitle case final s?) ...[
                const SizedBox(height: 4),
                Text(
                  s,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }
}
