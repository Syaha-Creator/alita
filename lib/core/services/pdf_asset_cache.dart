import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/log.dart';

/// Pre-loads and caches all PDF assets (fonts, logos) in memory so that
/// subsequent PDF generation calls are instant — no repeated [rootBundle.load].
///
/// Call [warmUp] once at app startup (e.g. after login) to pre-populate.
/// Both [InvoicePdfGenerator] and [QuotationPdfGenerator] should read from
/// this cache instead of loading assets from scratch each time.
class PdfAssetCache {
  PdfAssetCache._();

  // ─── Fonts ─────────────────────────────────────────────────
  static pw.Font? _fontBase;
  static pw.Font? _fontBold;
  static pw.Font? _fontItalic;

  static pw.Font get fontBase => _fontBase ?? pw.Font.helvetica();
  static pw.Font get fontBold => _fontBold ?? pw.Font.helveticaBold();
  static pw.Font get fontItalic => _fontItalic ?? pw.Font.helveticaOblique();

  // ─── Logos ─────────────────────────────────────────────────
  static pw.ImageProvider? _sleepCenterLogo;
  static final Map<String, pw.ImageProvider> _logoCache = {};

  static pw.ImageProvider? get sleepCenterLogo => _sleepCenterLogo;

  static pw.ImageProvider? logo(String path) => _logoCache[path];

  static List<pw.ImageProvider?> get brandLogos => _brandPaths
      .map((p) => _logoCache[p])
      .toList();

  // ─── Misc images ───────────────────────────────────────────
  static pw.ImageProvider? _approveStamp;
  static pw.ImageProvider? get approveStamp => _approveStamp;

  // ─── Asset paths ───────────────────────────────────────────
  static const _brandPaths = [
    'assets/logo/sleepspa_logo.png',
    'assets/logo/springair_logo.png',
    'assets/logo/therapedic_logo.png',
    'assets/logo/comforta_logo.png',
    'assets/logo/superfit_logo.png',
    'assets/logo/isleep_logo.png',
  ];

  static bool _warmedUp = false;
  static bool get isWarmedUp => _warmedUp;

  /// Pre-load all PDF assets into memory. Safe to call multiple times.
  static Future<void> warmUp() async {
    if (_warmedUp) return;

    await Future.wait([
      _loadFonts(),
      _loadAllLogos(),
      _loadMiscImages(),
    ]);

    _warmedUp = true;
  }

  // ─── Internal loaders ──────────────────────────────────────

  static Future<void> _loadFonts() async {
    _fontBase = await _tryLoadFont(
        'assets/fonts/Inter-VariableFont_opsz,wght.ttf');
    _fontBold = await _tryLoadFont('assets/fonts/Inter-Bold.ttf') ??
        await _tryLoadFont('assets/fonts/Inter_18pt-Bold.ttf');
    _fontItalic = await _tryLoadFont(
        'assets/fonts/Inter-Italic-VariableFont_opsz,wght.ttf');
  }

  static Future<void> _loadAllLogos() async {
    _sleepCenterLogo = await _tryLoadImage('assets/logo/sleepcenter_logo.png');

    await Future.wait(
      _brandPaths.map((p) async {
        final img = await _tryLoadImage(p);
        if (img != null) _logoCache[p] = img;
      }),
    );
  }

  static Future<void> _loadMiscImages() async {
    _approveStamp = await _tryLoadImage('assets/images/approve.png');
  }

  static Future<pw.Font?> _tryLoadFont(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.Font.ttf(data);
    } catch (e) {
      Log.warning('Font load failed: $path — $e', tag: 'PdfAssetCache');
      return null;
    }
  }

  static Future<pw.ImageProvider?> _tryLoadImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      Log.warning('Image load failed: $path — $e', tag: 'PdfAssetCache');
      return null;
    }
  }
}
