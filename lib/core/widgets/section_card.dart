import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout_tokens.dart';

/// Reusable elevated section card with optional title and trailing action.
///
/// Function:
/// - Menyatukan pola container section (`surface + radius + soft shadow`).
/// - Mendukung header standar (title + trailing) untuk form/summary sections.
/// - Mengurangi duplikasi style card di halaman besar seperti checkout/detail.
class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double contentSpacing;
  final TextStyle? titleStyle;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = AppLayoutTokens.sectionCardPadding,
    this.borderRadius = AppLayoutTokens.radius16,
    this.contentSpacing = AppLayoutTokens.space16,
    this.titleStyle,
    this.backgroundColor = AppColors.surface,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              const BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                spreadRadius: 0,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title!,
                  style: titleStyle ??
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: contentSpacing),
          ],
          child,
        ],
      ),
    );
  }
}
