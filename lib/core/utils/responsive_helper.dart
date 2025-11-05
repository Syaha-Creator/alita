import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Breakpoints untuk berbagai ukuran layar
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Zoom level thresholds
  static const double normalZoom = 1.0;
  static const double largeZoom = 1.2;
  static const double extraLargeZoom = 1.4;

  // Mendapatkan ukuran layar saat ini
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  // Mendapatkan lebar layar
  static double getScreenWidth(BuildContext context) {
    return getScreenSize(context).width;
  }

  // Mendapatkan tinggi layar
  static double getScreenHeight(BuildContext context) {
    return getScreenSize(context).height;
  }

  // Cek apakah layar mobile
  static bool isMobile(BuildContext context) {
    return getScreenWidth(context) < mobileBreakpoint;
  }

  // Cek apakah layar tablet
  static bool isTablet(BuildContext context) {
    final width = getScreenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Cek apakah layar desktop
  static bool isDesktop(BuildContext context) {
    return getScreenWidth(context) >= tabletBreakpoint;
  }

  // Mendapatkan padding yang responsif
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Mendapatkan margin yang responsif
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  // Mendapatkan jumlah kolom untuk grid yang responsif
  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Mendapatkan max width untuk content yang responsif
  static double getResponsiveMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 800;
    }
  }

  // Mendapatkan spacing yang responsif
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Mendapatkan border radius yang responsif
  static double getResponsiveBorderRadius(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Mendapatkan elevation yang responsif
  static double getResponsiveElevation(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Mendapatkan padding untuk AppBar yang responsif
  static EdgeInsets getAppBarPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    }
  }

  // Mendapatkan padding untuk card yang responsif
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  // Mendapatkan padding untuk button yang responsif
  static EdgeInsets getButtonPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  // Mendapatkan size untuk logo yang responsif
  static double getLogoSize(BuildContext context) {
    if (isMobile(context)) {
      return 32;
    } else if (isTablet(context)) {
      return 40;
    } else {
      return 48;
    }
  }

  // Mendapatkan height untuk AppBar yang responsif
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else if (isTablet(context)) {
      return kToolbarHeight + 8;
    } else {
      return kToolbarHeight + 12;
    }
  }

  // Mendapatkan width untuk drawer yang responsif
  static double getDrawerWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) * 0.8;
    } else if (isTablet(context)) {
      return 300;
    } else {
      return 350;
    }
  }

  // Mendapatkan max width untuk dialog yang responsif
  static double getDialogMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) * 0.9;
    } else if (isTablet(context)) {
      return 500;
    } else {
      return 600;
    }
  }

  // Mendapatkan max height untuk dialog yang responsif
  static double getDialogMaxHeight(BuildContext context) {
    if (isMobile(context)) {
      return getScreenHeight(context) * 0.8;
    } else if (isTablet(context)) {
      return getScreenHeight(context) * 0.7;
    } else {
      return getScreenHeight(context) * 0.6;
    }
  }

  // ===== ZOOM & ACCESSIBILITY METHODS =====

  // Mendapatkan text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  // Cek apakah user menggunakan zoom besar
  static bool isLargeZoom(BuildContext context) {
    return getTextScaleFactor(context) >= largeZoom;
  }

  // Cek apakah user menggunakan zoom sangat besar
  static bool isExtraLargeZoom(BuildContext context) {
    return getTextScaleFactor(context) >= extraLargeZoom;
  }

  // Mendapatkan font size yang responsif terhadap zoom
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
    double? largeZoomMultiplier,
    double? extraLargeZoomMultiplier,
  }) {
    double baseSize;
    if (isMobile(context)) {
      baseSize = mobile;
    } else if (isTablet(context)) {
      baseSize = tablet;
    } else {
      baseSize = desktop;
    }

    if (isExtraLargeZoom(context) && extraLargeZoomMultiplier != null) {
      return baseSize * extraLargeZoomMultiplier;
    } else if (isLargeZoom(context) && largeZoomMultiplier != null) {
      return baseSize * largeZoomMultiplier;
    }

    return baseSize;
  }

  // Mendapatkan icon size yang responsif
  static double getResponsiveIconSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    double baseSize;
    if (isMobile(context)) {
      baseSize = mobile;
    } else if (isTablet(context)) {
      baseSize = tablet;
    } else {
      baseSize = desktop;
    }

    // Scale dengan text scale factor untuk accessibility
    final textScaleFactor = getTextScaleFactor(context);
    if (textScaleFactor > 1.0) {
      return baseSize * (1.0 + (textScaleFactor - 1.0) * 0.5);
    }

    return baseSize;
  }

  // Mendapatkan button height yang responsif
  static double getResponsiveButtonHeight(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    double baseHeight;
    if (isMobile(context)) {
      baseHeight = mobile;
    } else if (isTablet(context)) {
      baseHeight = tablet;
    } else {
      baseHeight = desktop;
    }

    // Tambahkan padding ekstra untuk zoom
    if (isLargeZoom(context)) {
      return baseHeight + 8;
    } else if (isExtraLargeZoom(context)) {
      return baseHeight + 16;
    }

    return baseHeight;
  }

  // Mendapatkan padding yang responsif terhadap zoom
  static EdgeInsets getResponsivePaddingWithZoom(
    BuildContext context, {
    required EdgeInsets mobile,
    required EdgeInsets tablet,
    required EdgeInsets desktop,
  }) {
    EdgeInsets basePadding;
    if (isMobile(context)) {
      basePadding = mobile;
    } else if (isTablet(context)) {
      basePadding = tablet;
    } else {
      basePadding = desktop;
    }

    // Scale padding dengan zoom
    final textScaleFactor = getTextScaleFactor(context);
    if (textScaleFactor > 1.0) {
      final multiplier = 1.0 + (textScaleFactor - 1.0) * 0.3;
      return EdgeInsets.only(
        left: basePadding.left * multiplier,
        top: basePadding.top * multiplier,
        right: basePadding.right * multiplier,
        bottom: basePadding.bottom * multiplier,
      );
    }

    return basePadding;
  }

  // Mendapatkan spacing yang responsif terhadap zoom
  static double getResponsiveSpacingWithZoom(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    double baseSpacing;
    if (isMobile(context)) {
      baseSpacing = mobile;
    } else if (isTablet(context)) {
      baseSpacing = tablet;
    } else {
      baseSpacing = desktop;
    }

    // Scale spacing dengan zoom
    final textScaleFactor = getTextScaleFactor(context);
    if (textScaleFactor > 1.0) {
      return baseSpacing * (1.0 + (textScaleFactor - 1.0) * 0.2);
    }

    return baseSpacing;
  }

  // Mendapatkan safe area yang responsif
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Mendapatkan available height yang aman
  static double getSafeAvailableHeight(BuildContext context,
      {double extraMargin = 20}) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        extraMargin;
  }

  // Mendapatkan available width yang aman
  static double getSafeAvailableWidth(BuildContext context,
      {double extraMargin = 20}) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right -
        extraMargin;
  }

  // ===== DIALOG & MODAL METHODS =====

  // Mendapatkan max height untuk modal yang aman
  static double getSafeModalHeight(BuildContext context,
      {double maxRatio = 0.9}) {
    final availableHeight = getSafeAvailableHeight(context);
    final maxHeight = availableHeight * maxRatio;

    // Pastikan minimum height untuk usability
    final minHeight = isMobile(context) ? 400.0 : 500.0;
    return maxHeight > minHeight ? maxHeight : minHeight;
  }

  // Mendapatkan padding untuk modal yang responsif
  static EdgeInsets getModalPadding(BuildContext context) {
    final safePadding = getSafeAreaPadding(context);
    final basePadding = getResponsivePadding(context);

    return EdgeInsets.only(
      left: basePadding.left + safePadding.left,
      right: basePadding.right + safePadding.right,
      top: basePadding.top,
      bottom: basePadding.bottom + safePadding.bottom,
    );
  }

  // ===== BUTTON & INTERACTIVE ELEMENTS =====

  // Mendapatkan minimum touch target size (44x44 dp minimum)
  static double getMinTouchTargetSize(BuildContext context) {
    const double minSize = 44.0;
    final textScaleFactor = getTextScaleFactor(context);

    // Scale dengan zoom untuk accessibility
    if (textScaleFactor > 1.0) {
      return minSize * (1.0 + (textScaleFactor - 1.0) * 0.3);
    }

    return minSize;
  }

  // Mendapatkan button style yang responsif
  static ButtonStyle getResponsiveButtonStyle(
    BuildContext context, {
    required Color backgroundColor,
    required Color foregroundColor,
    double? borderRadius,
  }) {
    final minHeight = getMinTouchTargetSize(context);
    final padding = getResponsivePaddingWithZoom(
      context,
      mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      desktop: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    );

    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: Size(double.infinity, minHeight),
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ??
            getResponsiveBorderRadius(
              context,
              mobile: 8,
              tablet: 10,
              desktop: 12,
            )),
      ),
      elevation: 0,
    );
  }
}
