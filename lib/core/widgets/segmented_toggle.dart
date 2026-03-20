import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A modern two-option segmented toggle with a sliding active indicator.
///
/// Used for binary choices like "Lunas / DP", "Bayar Lunas / Nominal Lain", etc.
class SegmentedToggle extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final IconData? leftIcon;
  final IconData? rightIcon;
  final bool isLeftSelected;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;
  final double height;
  final double borderRadius;

  const SegmentedToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    this.leftIcon,
    this.rightIcon,
    required this.isLeftSelected,
    this.onTapLeft,
    this.onTapRight,
    this.height = 46,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Sliding indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: isLeftSelected ? 0 : halfWidth,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(borderRadius - 2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Labels
              Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: leftLabel,
                      icon: leftIcon,
                      isActive: isLeftSelected,
                      onTap: onTapLeft,
                    ),
                  ),
                  Expanded(
                    child: _ToggleOption(
                      label: rightLabel,
                      icon: rightIcon,
                      isActive: !isLeftSelected,
                      onTap: onTapRight,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _ToggleOption({
    required this.label,
    this.icon,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      toggled: isActive,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.textTertiary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color:
                        isActive ? AppColors.accent : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
