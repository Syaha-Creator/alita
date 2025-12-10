import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Enum untuk jenis styled container
enum ContainerType {
  /// Container dengan background primary yang subtle
  primary,

  /// Container dengan background surface
  surface,

  /// Container dengan background success
  success,

  /// Container dengan background warning
  warning,

  /// Container dengan background error
  error,

  /// Container dengan background info
  info,

  /// Container dengan gradient primary
  gradient,

  /// Container dengan background transparent dan border
  outlined,
}

/// Widget container yang sudah di-style untuk konsistensi UI.
/// Mengurangi boilerplate Container + BoxDecoration yang sering diulang.
class StyledContainer extends StatelessWidget {
  final Widget child;
  final ContainerType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? borderWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;

  const StyledContainer({
    super.key,
    required this.child,
    this.type = ContainerType.surface,
    this.padding,
    this.margin,
    this.borderRadius = 12,
    this.borderWidth,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = false,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
  });

  /// Factory untuk container primary
  factory StyledContainer.primary({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
    bool showShadow = false,
  }) {
    return StyledContainer(
      type: ContainerType.primary,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      showShadow: showShadow,
      child: child,
    );
  }

  /// Factory untuk container surface (background subtle)
  factory StyledContainer.surface({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
    bool showShadow = false,
  }) {
    return StyledContainer(
      type: ContainerType.surface,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      showShadow: showShadow,
      child: child,
    );
  }

  /// Factory untuk container success
  factory StyledContainer.success({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
  }) {
    return StyledContainer(
      type: ContainerType.success,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      child: child,
    );
  }

  /// Factory untuk container warning
  factory StyledContainer.warning({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
  }) {
    return StyledContainer(
      type: ContainerType.warning,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      child: child,
    );
  }

  /// Factory untuk container error
  factory StyledContainer.error({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
  }) {
    return StyledContainer(
      type: ContainerType.error,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      child: child,
    );
  }

  /// Factory untuk container info
  factory StyledContainer.info({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double? borderWidth,
  }) {
    return StyledContainer(
      type: ContainerType.info,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      child: child,
    );
  }

  /// Factory untuk container outlined (transparent dengan border)
  factory StyledContainer.outlined({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    double borderWidth = 1,
    Color? borderColor,
  }) {
    return StyledContainer(
      type: ContainerType.outlined,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      borderWidth: borderWidth,
      borderColor: borderColor,
      child: child,
    );
  }

  /// Factory untuk container gradient
  factory StyledContainer.gradient({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double borderRadius = 12,
    bool showShadow = true,
  }) {
    return StyledContainer(
      type: ContainerType.gradient,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      showShadow: showShadow,
      child: child,
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;

    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ContainerType.primary:
        return colorScheme.primary.withValues(alpha: 0.05);
      case ContainerType.surface:
        return colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
      case ContainerType.success:
        return AppColors.success.withValues(alpha: 0.1);
      case ContainerType.warning:
        return AppColors.warning.withValues(alpha: 0.1);
      case ContainerType.error:
        return AppColors.error.withValues(alpha: 0.1);
      case ContainerType.info:
        return AppColors.info.withValues(alpha: 0.1);
      case ContainerType.gradient:
      case ContainerType.outlined:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(BuildContext context) {
    if (borderColor != null) return borderColor!;

    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case ContainerType.primary:
        return colorScheme.primary.withValues(alpha: 0.1);
      case ContainerType.surface:
        return colorScheme.outline.withValues(alpha: 0.1);
      case ContainerType.success:
        return AppColors.success.withValues(alpha: 0.2);
      case ContainerType.warning:
        return AppColors.warning.withValues(alpha: 0.2);
      case ContainerType.error:
        return AppColors.error.withValues(alpha: 0.2);
      case ContainerType.info:
        return AppColors.info.withValues(alpha: 0.2);
      case ContainerType.gradient:
        return Colors.transparent;
      case ContainerType.outlined:
        return colorScheme.outline.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Handle gradient type separately
    if (type == ContainerType.gradient) {
      return Container(
        width: width,
        height: height,
        alignment: alignment,
        constraints: constraints,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: showShadow
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      constraints: constraints,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth != null || type == ContainerType.outlined
            ? Border.all(
                color: _getBorderColor(context),
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Widget card dengan section header yang konsisten
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final bool showBorder;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
    this.trailing,
    this.padding,
    this.contentPadding,
    this.borderRadius = 12,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),

          const SizedBox(height: 16),

          // Content
          Padding(
            padding: contentPadding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}
