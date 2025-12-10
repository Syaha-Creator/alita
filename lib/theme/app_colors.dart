import 'package:flutter/material.dart';

/// AppColors - Sistem Warna Branding dengan Komposisi 60-30-10
///
/// Komposisi Warna:
/// - 60%: Warna Dominan (Background utama, scaffold background)
/// - 30%: Warna Sekunder (Cards, containers, surface, elemen penting)
/// - 10%: Warna Aksen (Primary, buttons, highlights, CTA, elemen yang perlu menonjol)
///
/// Aturan ini berlaku untuk Light Mode dan Dark Mode dengan proporsi yang sama.

class AppColors {
  // ============================================================================
  // LIGHT MODE - Branding Colors (60-30-10)
  // ============================================================================

  /// 60% - Warna Dominan (Light Mode)
  /// Digunakan untuk: Background utama, scaffold background
  static const Color dominantLight = Color(0xFFF8FAFC); // Background utama
  static const Color backgroundLight = dominantLight;

  /// 30% - Warna Sekunder (Light Mode)
  /// Digunakan untuk: Cards, containers, surface, elemen penting
  static const Color secondaryLight = Color(0xFFF1F5F9); // Card background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Surface putih
  static const Color cardLight = secondaryLight;
  static const Color surfaceVariantLight = secondaryLight;

  /// 10% - Warna Aksen (Light Mode)
  /// Digunakan untuk: Primary, buttons, highlights, CTA, elemen yang perlu menonjol
  static const Color accentLight = Color(0xFF2563EB); // Primary blue
  static const Color primaryLight = accentLight;
  static const Color buttonLight = accentLight;

  // Light Mode - Supporting Colors
  static const Color secondaryAccentLight =
      Color(0xFF0EA5E9); // Secondary blue untuk variasi
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color disabledLight = Color(0xFF94A3B8);

  // ============================================================================
  // DARK MODE - Branding Colors (60-30-10)
  // ============================================================================

  /// 60% - Warna Dominan (Dark Mode)
  /// Digunakan untuk: Background utama, scaffold background
  static const Color dominantDark = Color(0xFF0F172A); // Background utama dark
  static const Color backgroundDark = dominantDark;

  /// 30% - Warna Sekunder (Dark Mode)
  /// Digunakan untuk: Cards, containers, surface, elemen penting
  static const Color secondaryDark = Color(0xFF1E293B); // Surface dark
  static const Color surfaceDark = secondaryDark;
  static const Color cardDark =
      Color(0xFF334155); // Card dark (sedikit lebih terang dari surface)
  static const Color surfaceVariantDark = cardDark;

  /// 10% - Warna Aksen (Dark Mode)
  /// Digunakan untuk: Primary, buttons, highlights, CTA, elemen yang perlu menonjol
  static const Color accentDark =
      Color(0xFF3B82F6); // Primary blue untuk dark mode
  static const Color primaryDark = accentDark;
  static const Color buttonDark = accentDark;

  // Dark Mode - Supporting Colors
  static const Color secondaryAccentDark =
      Color(0xFF60A5FA); // Secondary blue untuk variasi
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF475569);
  static const Color disabledDark = Color(0xFF64748B);

  // ============================================================================
  // STATUS COLORS (Universal - tidak mengikuti 60-30-10)
  // ============================================================================
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);
  static const Color purple = Color(0xFF8B5CF6);

  // ============================================================================
  // UTILITY COLORS
  // ============================================================================
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // ============================================================================
  // BRAND COLORS (External Services)
  // ============================================================================
  static const Color whatsapp = Color(0xFF25D366);

  // ============================================================================
  // HELPER METHODS - Untuk mendapatkan warna berdasarkan komposisi 60-30-10
  // ============================================================================

  /// Mendapatkan warna dominan (60%) berdasarkan theme
  static Color getDominantColor(bool isDark) {
    return isDark ? dominantDark : dominantLight;
  }

  /// Mendapatkan warna sekunder (30%) berdasarkan theme
  static Color getSecondaryColor(bool isDark) {
    return isDark ? secondaryDark : secondaryLight;
  }

  /// Mendapatkan warna aksen (10%) berdasarkan theme
  static Color getAccentColor(bool isDark) {
    return isDark ? accentDark : accentLight;
  }

  /// Mendapatkan warna card berdasarkan theme (30%)
  static Color getCardColor(bool isDark) {
    return isDark ? cardDark : cardLight;
  }

  /// Mendapatkan warna surface berdasarkan theme (30%)
  static Color getSurfaceColor(bool isDark) {
    return isDark ? surfaceDark : surfaceLight;
  }

  /// Mendapatkan warna primary berdasarkan theme (10%)
  static Color getPrimaryColor(bool isDark) {
    return isDark ? primaryDark : primaryLight;
  }
}
