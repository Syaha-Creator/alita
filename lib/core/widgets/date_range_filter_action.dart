import 'package:flutter/material.dart';

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
    this.accentColor = Colors.pink,
    this.padding = const EdgeInsets.only(right: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasActiveFilter && onClear != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
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
    );
  }
}
