import 'package:flutter/material.dart';

/// Widget untuk menampilkan empty state atau loading state.
/// Digunakan ketika data kosong, loading, atau error.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double iconSize;
  final double iconPadding;
  final double iconBorderRadius;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.iconBackgroundColor,
    this.iconSize = 48,
    this.iconPadding = 20,
    this.iconBorderRadius = 20,
    this.titleStyle,
    this.subtitleStyle,
    this.action,
    this.padding,
  });

  /// Factory untuk empty data state
  factory EmptyState.noData({
    IconData icon = Icons.inbox_outlined,
    String title = 'No Data Found',
    String? subtitle = 'There is no data to display at the moment',
    Widget? action,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  /// Factory untuk loading state
  factory EmptyState.loading({
    String title = 'Loading...',
    String? subtitle,
  }) {
    return EmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: title,
      subtitle: subtitle,
    );
  }

  /// Factory untuk error state
  factory EmptyState.error({
    IconData icon = Icons.error_outline_rounded,
    String title = 'Something went wrong',
    String? subtitle = 'Please try again later',
    Widget? action,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: action ??
          (actionLabel != null && onAction != null
              ? Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(actionLabel),
                  ),
                )
              : null),
    );
  }

  /// Factory untuk search not found state
  factory EmptyState.searchNotFound({
    String title = 'No Results Found',
    String? subtitle = 'Try adjusting your search criteria',
    Widget? action,
  }) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: title,
      subtitle: subtitle,
      action: action,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final effectiveIconBgColor = iconBackgroundColor ?? 
        colorScheme.primary.withValues(alpha: 0.1);

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              title,
              style: titleStyle ?? TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                style: subtitleStyle ?? TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan loading state dengan CircularProgressIndicator
class LoadingState extends StatelessWidget {
  final String? message;
  final Color? color;
  final double strokeWidth;

  const LoadingState({
    super.key,
    this.message,
    this.color,
    this.strokeWidth = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: color ?? colorScheme.primary,
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

