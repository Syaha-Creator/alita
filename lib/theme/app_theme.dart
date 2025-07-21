import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.cardLight,
    dividerColor: AppColors.borderLight,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      background: AppColors.backgroundLight,
      onBackground: AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      bodyLarge: GoogleFonts.montserrat(
        color: AppColors.textPrimaryLight,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.montserrat(
        color: AppColors.textSecondaryLight,
        fontSize: 14,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonLight,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle:
            GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardLight, // Warna latar belakang input
      labelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryLight,
      ),
      hintStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryLight.withOpacity(0.7),
      ),
      // Border saat tidak di-klik
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
      ),
      // Border saat di-klik
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
      ),
      // Border saat terjadi error validasi
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryLight,
      ),
      contentTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryLight,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceLight,
      textStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textPrimaryLight,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.borderDark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: Colors.white,
      secondary: AppColors.secondaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      background: AppColors.backgroundDark,
      onBackground: AppColors.textPrimaryDark,
      error: AppColors.error,
      onError: Colors.white,
    ),
    textTheme: GoogleFonts.montserratTextTheme().copyWith(
      bodyLarge: GoogleFonts.montserrat(
        color: AppColors.textPrimaryDark,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.montserrat(
        color: AppColors.textSecondaryDark,
        fontSize: 14,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle:
            GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryDark.withOpacity(0.7),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderDark, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.buttonDark, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 2.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
      contentTextStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textSecondaryDark,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceDark,
      textStyle: GoogleFonts.montserrat(
        fontSize: 14,
        color: AppColors.textPrimaryDark,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}
