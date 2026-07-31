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

  /// Fully transparent — formalized so `Colors.transparent` never needs to
  /// be referenced directly outside the 2 exempted cases (see coding rules).
  static const Color transparent = Colors.transparent;

  // Overlays & shadows
  static const Color shadow = Color(0x0F000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x1F000000);
  static const Color overlay = Color(0x8A000000);
  static const Color onPrimaryHigh = Color(0xE6FFFFFF);
  static const Color onPrimaryMedium = Color(0xB3FFFFFF);

  // Checkout approval-reason badges — one hue per distinct reason so users
  // scan multiple simultaneous badges at a glance. Values match Flutter's
  // Colors.orange/purple/indigo Material swatch exactly (formalized here
  // instead of referencing Colors.* directly, so they can't silently drift).
  static const Color reasonBonus = Color(0xFFFF9800); // Colors.orange
  static const Color reasonBonusIcon = Color(0xFFF57C00); // .shade700
  static const Color reasonBonusText = Color(0xFFEF6C00); // .shade800

  static const Color reasonCustomSize = Color(0xFF9C27B0); // Colors.purple
  static const Color reasonCustomSizeIcon = Color(0xFF7B1FA2); // .shade700
  static const Color reasonCustomSizeText = Color(0xFF6A1B9A); // .shade800

  static const Color reasonKlaus = Color(0xFF3F51B5); // Colors.indigo
  static const Color reasonKlausIcon = Color(0xFF3949AB); // .shade600
  static const Color reasonKlausText = Color(0xFF303F9F); // .shade700
}
