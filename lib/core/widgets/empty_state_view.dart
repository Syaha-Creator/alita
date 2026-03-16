import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable empty state section for list/grid/screen content.
///
/// Function:
/// - Menampilkan pesan saat data kosong dengan struktur konsisten:
///   `icon -> title -> subtitle -> optional action`.
/// - Mengurangi deklarasi ulang `Center + Column + Text` di banyak halaman.
/// - Menjaga visual empty state tetap seragam lintas fitur.
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final double iconSize;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.padding = const EdgeInsets.all(24),
    this.iconSize = 80,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTitleStyle =
        titleStyle ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    final resolvedSubtitleStyle =
        subtitleStyle ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textTertiary,
          height: 1.5,
        );

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(title, style: resolvedTitleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: resolvedSubtitleStyle,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
