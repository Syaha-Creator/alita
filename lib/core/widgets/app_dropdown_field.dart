import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'checkout_input_decoration.dart';

/// A beautifully styled dropdown form field that wraps [DropdownButtonFormField]
/// with consistent visual treatment: rounded popup, subtle shadow, custom
/// chevron icon, and selected-item checkmark indicator.
class AppDropdownField<T> extends StatelessWidget {
  final T? value;
  final String hintText;
  final List<T> items;
  final String Function(T) labelBuilder;
  final Widget Function(T)? leadingBuilder;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final InputDecoration? decoration;
  final bool filled;
  final Color? fillColor;

  const AppDropdownField({
    super.key,
    this.value,
    this.hintText = '',
    required this.items,
    required this.labelBuilder,
    this.leadingBuilder,
    this.onChanged,
    this.validator,
    this.decoration,
    this.filled = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration = decoration ??
        CheckoutInputDecoration.form(
          filled: filled,
          fillColor: fillColor ?? AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    return DropdownButtonFormField<T>(
      initialValue: value,
      hint: Text(
        hintText,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
      ),
      isExpanded: true,
      icon: const _DropdownChevron(),
      iconSize: 20,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: AppColors.surface,
      menuMaxHeight: 320,
      elevation: 3,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: effectiveDecoration,
      selectedItemBuilder: (context) {
        return items.map((item) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              labelBuilder(item),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList();
      },
      items: items.map((item) {
        final isSelected = item == value;
        return DropdownMenuItem<T>(
          value: item,
          child: _DropdownItemTile(
            label: labelBuilder(item),
            leading: leadingBuilder?.call(item),
            isSelected: isSelected,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Individual item row inside the dropdown popup.
class _DropdownItemTile extends StatelessWidget {
  final String label;
  final Widget? leading;
  final bool isSelected;

  const _DropdownItemTile({
    required this.label,
    this.leading,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ],
        ],
      ),
    );
  }
}

/// Animated chevron icon for the dropdown trigger.
class _DropdownChevron extends StatelessWidget {
  const _DropdownChevron();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppColors.textSecondary,
      ),
    );
  }
}
