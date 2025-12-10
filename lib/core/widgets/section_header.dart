import 'package:flutter/material.dart';

/// Widget untuk menampilkan header section dengan icon dan title.
/// Digunakan di berbagai tempat seperti cart_item, approval, checkout, dll.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? iconColor;
  final double iconSize;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconSize = 18,
    this.titleStyle,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize,
            color: iconColor ??
                (isDark
                    ? theme.colorScheme.primary
                    : theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: titleStyle ??
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Widget untuk container section dengan header, content, dan styling
class SectionContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const SectionContainer({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.trailing,
    this.padding,
    this.margin,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBgColor =
        isDark ? theme.colorScheme.surface : Colors.grey.shade50;

    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? defaultBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: icon,
            title: title,
            iconColor: iconColor,
            trailing: trailing,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
