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

  /// True if [url] points at an AVIF-encoded image.
  static bool isAvifUrl(String url) => url.toLowerCase().contains('.avif');

  /// Rewrites AVIF image URLs through a JPEG-converting proxy before display.
  ///
  /// Flutter's Skia decoder often mishandles AVIF color profiles, causing
  /// washed-out colors in-app even though the source looks correct in a
  /// browser. Since we don't control the vendor CDNs serving these photos,
  /// AVIF URLs are routed through wsrv.nl to convert them to JPEG on the fly.
  /// Non-AVIF URLs, asset URIs, and synthetic placeholders pass through unchanged.
  static String resolveDisplayUrl(String url) {
    if (!isNetworkProductPhoto(url) || !isAvifUrl(url)) return url;
    return Uri.https('wsrv.nl', '/', {
      'url': url,
      'output': 'jpg',
      'q': '85',
    }).toString();
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
