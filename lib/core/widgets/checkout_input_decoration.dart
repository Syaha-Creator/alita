import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared input decoration presets for checkout and payment forms.
class CheckoutInputDecoration {
  CheckoutInputDecoration._();

  static const double _radius = 12;

  static InputDecoration form({
    String? labelText,
    String? hintText,
    String? errorText,
    TextStyle? labelStyle,
    TextStyle? hintStyle,
    TextStyle? prefixStyle,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? prefixText,
    bool isDense = true,
    bool filled = true,
    Color? fillColor,
    FloatingLabelBehavior? floatingLabelBehavior,
    bool alignLabelWithHint = false,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    BorderSide enabledBorderSide = const BorderSide(color: AppColors.border),
    BorderSide focusedBorderSide = const BorderSide(
      color: AppColors.accent,
      width: 1.5,
    ),
    BorderSide errorBorderSide = const BorderSide(color: AppColors.error, width: 1.2),
    BorderSide focusedErrorBorderSide = const BorderSide(
      color: AppColors.error,
      width: 1.5,
    ),
  }) {
    OutlineInputBorder outline(BorderSide side) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: side,
        );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      labelStyle: labelStyle,
      hintStyle: hintStyle,
      prefixStyle: prefixStyle,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixText: prefixText,
      floatingLabelBehavior: floatingLabelBehavior,
      alignLabelWithHint: alignLabelWithHint,
      border: outline(const BorderSide(color: AppColors.border)),
      enabledBorder: outline(enabledBorderSide),
      focusedBorder: outline(focusedBorderSide),
      errorBorder: outline(errorBorderSide),
      focusedErrorBorder: outline(focusedErrorBorderSide),
      contentPadding: contentPadding,
      isDense: isDense,
      filled: filled,
      fillColor: fillColor ?? AppColors.surfaceLight,
    );
  }

  /// Preset for dropdown/select fields in checkout forms.
  static InputDecoration dropdown({
    String? labelText,
    String? hintText,
    String? errorText,
    TextStyle? labelStyle,
    TextStyle? hintStyle,
    bool isDense = true,
    bool filled = false,
    Color? fillColor,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
    BorderSide enabledBorderSide = const BorderSide(color: AppColors.border),
  }) {
    return form(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      labelStyle: labelStyle,
      hintStyle: hintStyle,
      isDense: isDense,
      filled: filled,
      fillColor: fillColor,
      contentPadding: contentPadding,
      enabledBorderSide: enabledBorderSide,
    );
  }
}
