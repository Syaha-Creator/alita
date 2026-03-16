import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single source of truth for all environment-based configuration.
///
/// Every API call across the app should read credentials from here
/// instead of calling `dotenv.env[...]` directly. This makes it easy to
/// swap between environments (dev / staging / prod) by changing only
/// the `.env` file — or by passing `--dart-define` at build time.
class AppConfig {
  AppConfig._();

  // ── Alita (Ruby) API ────────────────────────────────────────────

  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get clientId => dotenv.env['CLIENT_ID'] ?? '';

  static String get clientSecret => dotenv.env['CLIENT_SECRET'] ?? '';

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
        'sudah diisi di file .env',
      );
    }
  }

  // ── Comforta (Brand Spec) API ──────────────────────────────────

  static String get comfortaHost =>
      dotenv.env['COMFORTA_API_HOST'] ?? 'comforta.co.id';

  static String get comfortaAccessToken =>
      dotenv.env['COMFORTA_ACCESS_TOKEN'] ?? '';

  static String get comfortaClientId =>
      dotenv.env['COMFORTA_CLIENT_ID'] ?? '';

  static String get comfortaClientSecret =>
      dotenv.env['COMFORTA_CLIENT_SECRET'] ?? '';

  // ── Region API ─────────────────────────────────────────────────

  static String get regionApiBaseUrl =>
      dotenv.env['REGION_API_BASE_URL'] ??
      'https://www.emsifa.com/api-wilayah-indonesia/api';
}
