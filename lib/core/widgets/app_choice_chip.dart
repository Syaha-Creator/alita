import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// A refined choice chip with "Soft Selection" pattern.
///
/// - **Unselected**: `surfaceLight` bg + subtle border + secondary text
/// - **Selected**: `accentLight` bg + accent border + accent text + soft glow
/// - **Press**: scale 0.95 + haptic feedback
///
/// Works beautifully on both iOS and Android without relying on
/// platform-specific visuals.
class AppChoiceChip extends StatefulWidget {
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
    this.borderRadius = 12,
    this.showCheckmark = false,
  });

  @override
  State<AppChoiceChip> createState() => _AppChoiceChipState();
}

class _AppChoiceChipState extends State<AppChoiceChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _scaleCtrl.forward();

  void _handleTapUp(TapUpDetails _) => _scaleCtrl.reverse();

  void _handleTapCancel() => _scaleCtrl.reverse();

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onSelected?.call(!widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;

    return Semantics(
      button: true,
      selected: sel,
      label: widget.label,
      child: GestureDetector(
      onTap: widget.onSelected != null ? _handleTap : null,
      onTapDown: widget.onSelected != null ? _handleTapDown : null,
      onTapUp: widget.onSelected != null ? _handleTapUp : null,
      onTapCancel: widget.onSelected != null ? _handleTapCancel : null,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: sel ? AppColors.accentLight : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: sel ? AppColors.accent : AppColors.border,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showCheckmark && sel) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: sel ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
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
