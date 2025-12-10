import 'package:flutter/material.dart';
import '../utils/format_helper.dart';
import '../../theme/app_colors.dart';

/// Enum untuk jenis tampilan harga
enum PriceType {
  normal,
  strikethrough,
  discount,
  total,
  success,
  warning,
  info,
}

/// Widget untuk menampilkan row harga yang konsisten.
/// Digunakan di cart_item, checkout, invoice, dll.
class PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final PriceType type;
  final String? prefix;
  final bool showCurrency;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final EdgeInsetsGeometry? padding;

  const PriceRow({
    super.key,
    required this.label,
    required this.value,
    this.type = PriceType.normal,
    this.prefix,
    this.showCurrency = true,
    this.labelStyle,
    this.valueStyle,
    this.padding,
  });

  /// Factory untuk harga dengan strikethrough (harga asli)
  factory PriceRow.strikethrough({
    required String label,
    required double value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return PriceRow(
      label: label,
      value: value,
      type: PriceType.strikethrough,
      labelStyle: labelStyle,
      valueStyle: valueStyle,
    );
  }

  /// Factory untuk diskon (nilai negatif, warna warning)
  factory PriceRow.discount({
    required String label,
    required double value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return PriceRow(
      label: label,
      value: value,
      type: PriceType.discount,
      prefix: '-',
      labelStyle: labelStyle,
      valueStyle: valueStyle,
    );
  }

  /// Factory untuk total (bold, warna sukses)
  factory PriceRow.total({
    required String label,
    required double value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return PriceRow(
      label: label,
      value: value,
      type: PriceType.total,
      labelStyle: labelStyle,
      valueStyle: valueStyle,
    );
  }

  TextStyle _getValueStyle(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = valueStyle ?? theme.textTheme.bodyMedium ?? const TextStyle();

    switch (type) {
      case PriceType.strikethrough:
        return baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          color: AppColors.error,
        );
      case PriceType.discount:
        return baseStyle.copyWith(
          color: AppColors.warning,
        );
      case PriceType.total:
      case PriceType.success:
        return baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        );
      case PriceType.warning:
        return baseStyle.copyWith(
          color: AppColors.warning,
        );
      case PriceType.info:
        return baseStyle.copyWith(
          color: AppColors.info,
        );
      case PriceType.normal:
        return baseStyle;
    }
  }

  String _formatValue() {
    final formattedValue = FormatHelper.formatCurrency(value);
    final prefixStr = prefix ?? '';
    return showCurrency ? '$prefixStr$formattedValue' : prefixStr + value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: labelStyle ?? theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _formatValue(),
            style: _getValueStyle(context),
          ),
        ],
      ),
    );
  }
}

/// Widget container untuk menampilkan total harga dengan background
class TotalPriceContainer extends StatelessWidget {
  final String label;
  final double value;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  const TotalPriceContainer({
    super.key,
    this.label = 'Total Harga:',
    required this.value,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark 
            ? AppColors.surfaceDark 
            : AppColors.success.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark 
                  ? AppColors.textPrimaryDark 
                  : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            FormatHelper.formatCurrency(value),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

