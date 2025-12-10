import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../utils/responsive_helper.dart';

/// Widget TextField modern dengan styling konsisten
/// Dapat digunakan di seluruh aplikasi untuk input form
class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? hintText;
  final Widget? suffixIcon;
  final bool obscureText;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
    this.hintText,
    this.suffixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      obscureText: obscureText,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      onFieldSubmitted: onFieldSubmitted ??
          (_) {
            // Move focus to next field or dismiss keyboard
            FocusScope.of(context).nextFocus();
          },
      onEditingComplete: onEditingComplete,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          size: ResponsiveHelper.getResponsiveIconSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight, // 30% - Border
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight, // 30% - Border
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: const BorderSide(color: AppColors.error), // Status color
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: const BorderSide(color: AppColors.error, width: 2), // Status color
        ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
            ),
        errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.error, // Status color
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
            ),
        filled: true,
        fillColor: enabled
            ? (isDark ? AppColors.cardDark : AppColors.surfaceLight) // 30% - Card/Surface
            : (isDark ? AppColors.disabledDark : AppColors.disabledLight.withValues(alpha: 0.1)),
        contentPadding: ResponsiveHelper.getResponsivePaddingWithZoom(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

