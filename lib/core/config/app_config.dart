import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single source of truth for all environment-based configuration.
///
/// Reads credentials in this order: `--dart-define` (release/CI) → `.env` (dev).
/// For production builds, pass secrets via `--dart-define` so `.env` is never baked in.
///
/// Client credentials are platform-aware: Android and iOS each have their own
/// `client_id` / `client_secret` pair registered on the backend.
class AppConfig {
  AppConfig._();

  static String _fromEnv(String key, [String defaultValue = '']) =>
      String.fromEnvironment(key, defaultValue: dotenv.env[key] ?? defaultValue);

  // ── Alita (Ruby) API ────────────────────────────────────────────

  static String get apiBaseUrl => _fromEnv('API_BASE_URL');

  static String get clientId =>
      Platform.isAndroid ? _fromEnv('CLIENT_ID_ANDROID') : _fromEnv('CLIENT_ID_IOS');

  static String get clientSecret =>
      Platform.isAndroid ? _fromEnv('CLIENT_SECRET_ANDROID') : _fromEnv('CLIENT_SECRET_IOS');

  /// Shared query map used by almost every API call.
  static Map<String, String> authQuery(String accessToken) => {
        'access_token': accessToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      };

  /// Query params without access_token (for login endpoint).
  static Map<String, String> get clientCredentials => {
        'client_id': clientId,
        'client_secret': clientSecret,
      };

  /// Quick validation — throws if essential keys are missing.
  static void assertConfigured() {
    if (apiBaseUrl.isEmpty || clientId.isEmpty || clientSecret.isEmpty) {
      throw StateError(
        'Konfigurasi API tidak lengkap. '
        'Pastikan API_BASE_URL, CLIENT_ID, dan CLIENT_SECRET '
        'sudah diisi di .env (dev) atau via --dart-define (release).',
      );
    }
  }

  // ── Comforta (Brand Spec) API ──────────────────────────────────

  static String get comfortaHost =>
      _fromEnv('COMFORTA_API_HOST', 'comforta.co.id');

  static String get comfortaAccessToken =>
      _fromEnv('COMFORTA_ACCESS_TOKEN');

  static String get comfortaClientId =>
      _fromEnv('COMFORTA_CLIENT_ID');

  static String get comfortaClientSecret =>
      _fromEnv('COMFORTA_CLIENT_SECRET');

  // ── Region API ─────────────────────────────────────────────────

  static String get regionApiBaseUrl =>
      _fromEnv('REGION_API_BASE_URL',
          'https://www.emsifa.com/api-wilayah-indonesia/api');

  // ── Placeholder Images ────────────────────────────────────────

  static const String placeholderProductImage =
      'https://images.unsplash.com/photo-1505693416022-14c1c9240ce4?q=80&w=800&auto=format&fit=crop';

  static const List<String> placeholderCarouselImages = [
    'https://images.unsplash.com/photo-1631679706909-1844bbd07221?q=80&w=800&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?q=80&w=800&auto=format&fit=crop',
  ];

  static String placeholderProductImageById(dynamic id) =>
      'https://picsum.photos/seed/${id ?? 0}/400/600';
}
