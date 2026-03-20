import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable app-bar action for date range filtering.
class DateRangeFilterAction extends StatelessWidget {
  final String label;
  final bool hasActiveFilter;
  final Color accentColor;
  final VoidCallback onPick;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;

  const DateRangeFilterAction({
    super.key,
    required this.label,
    required this.hasActiveFilter,
    required this.onPick,
    this.onClear,
    this.accentColor = AppColors.accent,
    this.padding = const EdgeInsets.only(right: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter tanggal',
      button: true,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasActiveFilter && onClear != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Reset Filter',
            onPressed: onClear,
          ),
        Padding(
          padding: padding,
          child: TextButton.icon(
            icon: Icon(
              Icons.calendar_month_outlined,
              size: 18,
              color: accentColor,
            ),
            label: Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: onPick,
          ),
        ),
      ],
      ),
    );
  }
}
