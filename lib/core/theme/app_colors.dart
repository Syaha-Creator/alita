import 'package:flutter/material.dart';

/// Massindo Group brand color palette — extracted from massindo.com
class AppColors {
  AppColors._();

  // Brand (from massindo.com logo, headings, statistics)
  /// Slate Blue — logo, headings, nav links on massindo.com
  static const Color primary = Color(0xFF344767);

  /// Massindo Blue — statistics, highlights, CTA on massindo.com
  static const Color accent = Color(0xFF1A73E8);

  /// Text/icon on primary or accent (ensure contrast)
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Background & surface
  /// Ice blue tint — scaffold & app bar (derived from massindo.com #E6F2FF)
  static const Color background = Color(0xFFEFF6FF);
  static const Color surface = Color(0xFFFFFFFF);
  /// Website body blue — used for light surface variant
  static const Color surfaceLight = Color(0xFFE6F2FF);

  // Text
  /// Slate Blue — matches massindo.com heading color
  static const Color textPrimary = Color(0xFF344767);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Border & divider (soft border)
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Accent tints (blue-based to match brand)
  static const Color accentLight = Color(0xFFDBEAFE);
  static const Color accentBorder = Color(0xFF93C5FD);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFE68A00);

  // Semantic tints (light backgrounds & borders for semantic colors)
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFFE082);

  // Overlays & shadows
  static const Color shadow = Color(0x0F000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1F000000);
  static const Color overlay = Color(0x8A000000);
  static const Color onPrimaryHigh = Color(0xE6FFFFFF);
  static const Color onPrimaryMedium = Color(0xB3FFFFFF);
}
