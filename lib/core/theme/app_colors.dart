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
  static const Color shadowSubtle = Color(0x0D000000); // black @ 5%
  static const Color shadowSoft = Color(0x1A000000); // black @ 10%
  static const Color shadowMedium = Color(0x1F000000);
  static const Color shadowStrong = Color(0x42000000); // Colors.black26 equiv.
  static const Color overlay = Color(0x8A000000); // Colors.black54 equiv.

  /// Bottom scrim gradient over image carousels (black @ 35%).
  static const Color scrimGradient = Color(0x59000000);

  /// Full-screen loading barrier / dimming overlay (black @ 45%).
  static const Color scrimBarrier = Color(0x73000000);

  static const Color onPrimaryHigh = Color(0xE6FFFFFF);
  static const Color onPrimaryMedium = Color(0xB3FFFFFF);

  /// White overlay tint @ 35% — used over image content before text/icons.
  static const Color onPrimaryLow = Color(0x59FFFFFF);

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

  // Order status badges (OrderStatus enum) — distinct shades per status,
  // used for detail pages (pill/badge) and list rows (compact text).
  // Kept separate from the generic success/error/warning semantic colors
  // above so status-badge visuals never silently drift if those generic
  // tokens change for unrelated UI.
  static const Color statusApprovedForeground = Color(0xFF1B8B4B);
  static const Color statusApprovedBackground = Color(0xFFECFDF5);
  static const Color statusApprovedListForeground = Color(0xFF2E7D32);

  static const Color statusPendingForeground = Color(0xFFD97706);
  static const Color statusPendingBackground = Color(0xFFFFFBEB);
  /// Also reused for the "Sisa Tagihan" (shortage) accent on the checkout
  /// edit-mode selisih card — same semantic meaning (pending/outstanding).
  static const Color statusPendingListForeground = Color(0xFFE65100);

  static const Color statusRejectedForeground = Color(0xFFDC2626);
  static const Color statusRejectedBackground = Color(0xFFFEF2F2);
  static const Color statusRejectedListForeground = Color(0xFFC62828);

  static const Color statusUnknownForeground = Color(0xFF6B7280);
  static const Color statusUnknownBackground = Color(0xFFF3F4F6);
  static const Color statusUnknownListForeground = Color(0xFF9E9E9E); // Colors.grey

  // Help/support footer gradient (profile → "Masih butuh bantuan?").
  static const Color helpFooterGradientStart = Color(0xFFF0F7FF);
  static const Color helpFooterGradientEnd = Color(0xFFE8F0FE);
}
