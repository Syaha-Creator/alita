import 'package:flutter/material.dart';

/// Centralized layout tokens (spacing, radius, shadow) for consistent UI.
class AppLayoutTokens {
  AppLayoutTokens._();

  // Spacing scale
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space20 = 20;

  // Radius scale
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius16 = 16;

  // Common paddings
  static const EdgeInsets cardPadding = EdgeInsets.all(space16);
  static const EdgeInsets sectionCardPadding = EdgeInsets.all(space20);
  static const EdgeInsets footerBoxPadding = EdgeInsets.symmetric(
    horizontal: space12,
    vertical: space10,
  );
  static const EdgeInsets verticalDividerPadding = EdgeInsets.symmetric(
    vertical: space12,
  );

  // Common margins/gaps
  static const EdgeInsets listCardMargin = EdgeInsets.only(bottom: space16);

  // Shadows
  static final BoxShadow cardShadowSoft = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
}
