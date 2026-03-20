import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable tappable date field tile for forms.
/// Used in checkout and payment forms for consistent date picker UI.
class DatePickerFieldTile extends StatelessWidget {
  final String text;
  final String placeholder;
  final VoidCallback onTap;
  final IconData icon;
  final double iconSize;
  final bool hasError;
  final String? errorText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry contentPadding;

  const DatePickerFieldTile({
    super.key,
    required this.text,
    required this.onTap,
    this.placeholder = 'Pilih Tanggal',
    this.icon = Icons.calendar_month_outlined,
    this.iconSize = 20,
    this.hasError = false,
    this.errorText,
    this.textStyle,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: hasValue
              ? 'Pilih tanggal, dipilih: $text'
              : 'Pilih tanggal',
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: ExcludeSemantics(
              child: Container(
            padding: contentPadding,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.border,
                width: hasError ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasValue ? text : placeholder,
                  style: textStyle ??
                      TextStyle(
                        color: hasValue
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                        fontSize: 14,
                      ),
                ),
                Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          ),
          ),
        ),
        if (hasError && (errorText?.isNotEmpty ?? false))
          if (errorText case final e?)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                e,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
      ],
    );
  }
}
