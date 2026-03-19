import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A modern, pill-shaped choice chip with smooth animation.
///
/// Replaces Flutter's default [ChoiceChip] with a cleaner visual
/// that matches the app's "airy" design language.
class AppChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool showCheckmark;

  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius = 20,
    this.showCheckmark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected != null ? () => onSelected!(!selected) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheckmark && selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? AppColors.onPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
