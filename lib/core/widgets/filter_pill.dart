import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable dropdown-style filter pill with active state.
class FilterPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isActive;
  final IconData trailingIcon;

  const FilterPill({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    required this.isActive,
    this.trailingIcon = Icons.keyboard_arrow_down,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.accent : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? AppColors.accent : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
