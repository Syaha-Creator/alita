import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App theme configuration with **bundled Inter** (no runtime fetch).
/// Avoids crashes when offline: `google_fonts` + gstatic.com would throw
/// [SocketException] / network unreachable on first paint.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  static TextStyle _text(
    double fontSize,
    FontWeight fontWeight,
    Color color, {
    double? height,
  }) =>
      TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static ThemeData get lightTheme {
    final baseText = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    ).textTheme.apply(
      fontFamily: _fontFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme — Massindo brand; onPrimary/onSecondary ensure contrast
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.onPrimary,
      ),

      // Scaffold & AppBar — same background so header and body blend
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: _text(
          20,
          FontWeight.w600,
          AppColors.textPrimary,
        ),
      ),

      // Typography — bundled Inter (works offline)
      textTheme: baseText.copyWith(
        displayLarge: _text(32, FontWeight.w700, AppColors.textPrimary),
        displayMedium: _text(28, FontWeight.w600, AppColors.textPrimary),
        displaySmall: _text(24, FontWeight.w600, AppColors.textPrimary),
        headlineLarge: _text(22, FontWeight.w600, AppColors.textPrimary),
        headlineMedium: _text(20, FontWeight.w600, AppColors.textPrimary),
        titleLarge: _text(18, FontWeight.w600, AppColors.textPrimary),
        titleMedium: _text(16, FontWeight.w500, AppColors.textPrimary),
        titleSmall: _text(14, FontWeight.w500, AppColors.textSecondary),
        bodyLarge: _text(16, FontWeight.w400, AppColors.textPrimary),
        bodyMedium: _text(14, FontWeight.w400, AppColors.textPrimary),
        bodySmall: _text(12, FontWeight.w400, AppColors.textSecondary),
        labelLarge: _text(14, FontWeight.w500, AppColors.textPrimary),
        labelMedium: _text(12, FontWeight.w500, AppColors.textSecondary),
        labelSmall: _text(11, FontWeight.w400, AppColors.textTertiary),
      ),

      // Card theme - soft shadows
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: AppColors.surface,
        margin: EdgeInsets.zero,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Checkbox — rounded, branded
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.onPrimary),
        splashRadius: 16,
        visualDensity: VisualDensity.compact,
      ),

      // PopupMenu — rounded, subtle shadow
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 3,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: _text(14, FontWeight.w400, AppColors.textPrimary),
      ),

      // Dialog — rounded, clean surface
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 4,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _text(17, FontWeight.w600, AppColors.textPrimary),
        contentTextStyle: _text(
          14,
          FontWeight.w400,
          AppColors.textSecondary,
          height: 1.5,
        ),
      ),

      // DatePicker — branded colors
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        headerBackgroundColor: AppColors.accent,
        headerForegroundColor: AppColors.onPrimary,
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return null;
        }),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.textPrimary;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return AppColors.accent;
        }),
        todayBorder: const BorderSide(color: AppColors.accent, width: 1.5),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return null;
        }),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.onPrimary;
          return AppColors.textPrimary;
        }),
        rangePickerBackgroundColor: AppColors.surface,
        rangePickerHeaderBackgroundColor: AppColors.accent,
        rangePickerHeaderForegroundColor: AppColors.onPrimary,
        rangeSelectionBackgroundColor: AppColors.accentLight,
      ),

      // ElevatedButton — rounded, accent default
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _text(14, FontWeight.w600, AppColors.onPrimary),
        ),
      ),

      // TextButton — branded
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: _text(14, FontWeight.w600, AppColors.accent),
        ),
      ),

      // SnackBar — floating, rounded
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        contentTextStyle: _text(13, FontWeight.w500, AppColors.onPrimary),
      ),
    );
  }
}
