/// Helpers for product thumbnails: synthetic placeholders vs real photos, brand logos.
abstract final class ProductImageUtils {
  /// Prefix for bundled assets consumed by [NetworkImageView].
  static const String assetUriPrefix = 'asset://';

  /// True for app-generated placeholders (not real mattress photos).
  static bool isSyntheticProductImageUrl(String url) {
    if (url.isEmpty) return true;
    final u = url.toLowerCase().trim();
    if (u.contains('picsum.photos')) return true;
    if (u.contains('images.unsplash.com')) return true;
    return false;
  }

  /// User-visible product photo: network URL, not synthetic, not an asset URI.
  static bool isNetworkProductPhoto(String url) {
    if (url.isEmpty) return false;
    if (url.startsWith(assetUriPrefix)) return false;
    if (isSyntheticProductImageUrl(url)) return false;
    final u = url.toLowerCase();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  /// [assetUriPrefix] + path for [NetworkImageView], e.g. `asset://assets/logo/...`.
  static String brandLogoAssetUri(String brand) =>
      '$assetUriPrefix${brandLogoAssetPath(brand)}';

  /// Bundled logo path under [assetUriPrefix] (no scheme).
  static String brandLogoAssetPath(String brand) {
    final b = brand.toLowerCase().trim();
    if (b.contains('spring air')) return 'assets/logo/springair_logo.png';
    if (b.contains('therapedic')) return 'assets/logo/therapedic_logo.png';
    if (b.contains('comforta')) return 'assets/logo/comforta_logo.png';
    if (b.contains('sleep spa') || b.contains('sleepspa')) {
      return 'assets/logo/sleepspa_logo.png';
    }
    if (b.contains('superfit')) return 'assets/logo/superfit_logo.png';
    if (b.contains('isleep')) return 'assets/logo/isleep_logo.png';
    return 'assets/logo/sleepcenter_logo.png';
  }
}
