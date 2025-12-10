import 'package:flutter/material.dart';
import 'app_colors.dart';

/// AppTheme - Theme Configuration dengan Komposisi Warna 60-30-10
///
/// Komposisi Warna:
/// - 60%: Dominant (Background utama)
/// - 30%: Secondary (Cards, containers, surface)
/// - 10%: Accent (Primary, buttons, highlights, CTA)

class AppTheme {
  // ============================================================================
  // LIGHT THEME (60-30-10 Composition)
  // ============================================================================
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    // 10% - Accent Color (Primary, buttons, highlights)
    primaryColor: AppColors.accentLight,

    // 60% - Dominant Color (Background utama)
    scaffoldBackgroundColor: AppColors.dominantLight,

    // 30% - Secondary Color (Cards, containers)
    cardColor: AppColors.cardLight,
    dividerColor: AppColors.borderLight,

    // ColorScheme dengan komposisi 60-30-10
    colorScheme: ColorScheme.light(
      // 10% - Accent
      primary: AppColors.accentLight,
      onPrimary: Colors.white,

      // 30% - Secondary
      secondary: AppColors.secondaryAccentLight,
      surface: AppColors.surfaceLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,

      // Text colors
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,

      // Utility
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderLight,
    ),

    // Text Theme
    textTheme: const TextTheme().copyWith(
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSecondaryLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryLight,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryLight,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    // AppBar Theme (10% - Accent)
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.accentLight,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.shadowLight,
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Elevated Button Theme (10% - Accent)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Input Decoration Theme (30% - Secondary untuk background, 10% - Accent untuk focus)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight, // 30% - Secondary
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.accentLight, width: 2.0), // 10% - Accent
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Dialog Theme (30% - Secondary)
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.surfaceLight,
      elevation: 8,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryLight,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Popup Menu Theme (30% - Secondary)
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceLight,
      elevation: 8,
      shadowColor: AppColors.shadowLight,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textPrimaryLight,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Bottom Sheet Theme (30% - Secondary)
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.surfaceLight,
      elevation: 8,
      shadowColor: AppColors.shadowLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Card Theme (30% - Secondary)
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // ============================================================================
  // DARK THEME (60-30-10 Composition)
  // ============================================================================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    // 10% - Accent Color (Primary, buttons, highlights)
    primaryColor: AppColors.accentDark,

    // 60% - Dominant Color (Background utama)
    scaffoldBackgroundColor: AppColors.dominantDark,

    // 30% - Secondary Color (Cards, containers)
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.borderDark,

    // ColorScheme dengan komposisi 60-30-10
    colorScheme: ColorScheme.dark(
      // 10% - Accent
      primary: AppColors.accentDark,
      onPrimary: Colors.white,

      // 30% - Secondary
      secondary: AppColors.secondaryAccentDark,
      surface: AppColors.surfaceDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,

      // Text colors
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,

      // Utility
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.borderDark,
    ),

    // Text Theme
    textTheme: const TextTheme().copyWith(
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textSecondaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryDark,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        color: AppColors.textPrimaryDark,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    // AppBar Theme (10% - Accent)
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.accentDark,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: AppColors.shadowDark,
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // Elevated Button Theme (10% - Accent)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    // Input Decoration Theme (30% - Secondary untuk background, 10% - Accent untuk focus)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark, // 30% - Secondary
      labelStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryDark,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryDark.withValues(alpha: 0.6),
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.accentDark, width: 2.0), // 10% - Accent
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Dialog Theme (30% - Secondary)
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      elevation: 8,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textSecondaryDark,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Popup Menu Theme (30% - Secondary)
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceDark,
      elevation: 8,
      shadowColor: AppColors.shadowDark,
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: AppColors.textPrimaryDark,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Bottom Sheet Theme (30% - Secondary)
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      elevation: 8,
      shadowColor: AppColors.shadowDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Card Theme (30% - Secondary)
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 2,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
