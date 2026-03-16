import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared modal sheet scaffold with handle bar and safe-area footer padding.
class SheetScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? contentPadding;
  final double topRadius;
  final bool showHandle;
  final Color backgroundColor;
  final bool includeBottomSafePadding;
  final double bottomSpacing;

  const SheetScaffold({
    super.key,
    required this.child,
    this.contentPadding,
    this.topRadius = 24,
    this.showHandle = true,
    this.backgroundColor = AppColors.surface,
    this.includeBottomSafePadding = true,
    this.bottomSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = includeBottomSafePadding
        ? MediaQuery.of(context).padding.bottom
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: Padding(
              padding: contentPadding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
          SizedBox(height: bottomInset + bottomSpacing),
        ],
      ),
    );
  }
}
