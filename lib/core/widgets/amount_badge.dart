import 'package:flutter/material.dart';
import '../utils/format_helper.dart';
import '../../theme/app_colors.dart';

/// Enum untuk jenis tampilan amount badge
enum AmountBadgeType {
  primary,
  success,
  warning,
  error,
  info,
  neutral,
  gradient,
}

/// Widget untuk menampilkan amount/harga dalam bentuk badge yang konsisten.
/// Digunakan di approval_card, cart, invoice header, dll.
class AmountBadge extends StatelessWidget {
  final double value;
  final AmountBadgeType type;
  final String? prefix;
  final bool showCurrency;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool compact;

  const AmountBadge({
    super.key,
    required this.value,
    this.type = AmountBadgeType.primary,
    this.prefix,
    this.showCurrency = true,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius = 12,
    this.compact = false,
  });

  /// Factory untuk badge primary (warna primary app)
  factory AmountBadge.primary({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.primary,
      compact: compact,
    );
  }

  /// Factory untuk badge sukses (hijau)
  factory AmountBadge.success({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.success,
      compact: compact,
    );
  }

  /// Factory untuk badge warning (orange)
  factory AmountBadge.warning({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.warning,
      compact: compact,
    );
  }

  /// Factory untuk badge error (merah)
  factory AmountBadge.error({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.error,
      compact: compact,
    );
  }

  /// Factory untuk badge info (biru)
  factory AmountBadge.info({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.info,
      compact: compact,
    );
  }

  /// Factory untuk badge neutral (abu-abu)
  factory AmountBadge.neutral({
    required double value,
    bool compact = false,
  }) {
    return AmountBadge(
      value: value,
      type: AmountBadgeType.neutral,
      compact: compact,
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case AmountBadgeType.primary:
        return colorScheme.primary;
      case AmountBadgeType.success:
        return AppColors.success;
      case AmountBadgeType.warning:
        return AppColors.warning;
      case AmountBadgeType.error:
        return AppColors.error;
      case AmountBadgeType.info:
        return AppColors.info;
      case AmountBadgeType.neutral:
        return colorScheme.surfaceContainerHighest;
      case AmountBadgeType.gradient:
        return colorScheme.primary;
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case AmountBadgeType.primary:
      case AmountBadgeType.success:
      case AmountBadgeType.warning:
      case AmountBadgeType.error:
      case AmountBadgeType.info:
      case AmountBadgeType.gradient:
        return Colors.white;
      case AmountBadgeType.neutral:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _formatValue() {
    final prefixStr = prefix ?? (showCurrency ? 'Rp ' : '');
    final formattedValue = FormatHelper.formatNumberWithComma(value.toInt());
    return '$prefixStr$formattedValue';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectivePadding = padding ??
        (compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 6));

    final effectiveFontSize = fontSize ?? (compact ? 12.0 : 14.0);
    final effectiveFontWeight = fontWeight ?? FontWeight.w700;

    // Use gradient for gradient type
    if (type == AmountBadgeType.gradient) {
      return Container(
        padding: effectivePadding,
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
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          _formatValue(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: effectiveFontWeight,
            color: Colors.white,
            fontSize: effectiveFontSize,
          ),
        ),
      );
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        _formatValue(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: effectiveFontWeight,
          color: _getTextColor(context),
          fontSize: effectiveFontSize,
        ),
      ),
    );
  }
}

/// Widget untuk menampilkan amount dengan icon dan label
class AmountDisplay extends StatelessWidget {
  final String label;
  final double value;
  final IconData? icon;
  final Color? color;
  final bool showCurrency;
  final bool compact;

  const AmountDisplay({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
    this.showCurrency = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: effectiveColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: EdgeInsets.all(compact ? 4 : 6),
                  decoration: BoxDecoration(
                    color: effectiveColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(compact ? 4 : 6),
                  ),
                  child: Icon(
                    icon,
                    color: effectiveColor,
                    size: compact ? 12 : 14,
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
              ],
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: compact ? 10 : 12,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            showCurrency
                ? 'Rp ${FormatHelper.formatNumberWithComma(value.toInt())}'
                : FormatHelper.formatNumberWithComma(value.toInt()),
            style: theme.textTheme.titleMedium?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
