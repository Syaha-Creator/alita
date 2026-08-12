import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Single source of truth for all environment-based configuration.
///
/// Reads credentials in this order:
/// 1. `--dart-define` (nilai non-kosong di-compile ke binary — release/CI)
/// 2. `flutter_dotenv` setelah [dotenv.load] di `main` (asset `.env` di bundle)
///
/// Catatan: [String.fromEnvironment] hanya memakai lingkungan **waktu compile**.
/// Menaruh `dotenv.env` sebagai `defaultValue` dari [String.fromEnvironment] tidak
/// akan memuat `.env` di runtime; makanya urutan dibalik eksplisit di [_fromEnv].
///
/// Untuk build yang **tidak** meng-bundle `.env`, wajib pass secrets via
/// `--dart-define` (lihat `scripts/release.sh`).
///
/// Client credentials are platform-aware: Android and iOS each have their own
/// `client_id` / `client_secret` pair registered on the backend.
class AppConfig {
  AppConfig._();

  // `String.fromEnvironment` HANYA terbaca kalau dipanggil `const` dengan
  // key literal — dipanggil lewat variabel/parameter (non-const) selalu
  // balik defaultValue, walau --dart-define diisi saat build. Makanya tiap
  // key wajib const terpisah di sini, bukan lewat helper yang menerima
  // `String key` sebagai parameter.
  static String _pick(String fromDefine, String dotenvKey,
      [String defaultValue = '']) {
    if (fromDefine.isNotEmpty) return fromDefine;
    if (!dotenv.isInitialized) return defaultValue;
    return dotenv.env[dotenvKey] ?? defaultValue;
  }

  // ── App identity ────────────────────────────────────────────────

  static const String appName = 'Alita Pricelist';

  // ── Alita (Ruby) API ────────────────────────────────────────────

  static const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl => _pick(_apiBaseUrlDefine, 'API_BASE_URL');

  static const _clientIdAndroidDefine =
      String.fromEnvironment('CLIENT_ID_ANDROID');
  static const _clientIdIosDefine = String.fromEnvironment('CLIENT_ID_IOS');
  static String get clientId => Platform.isAndroid
      ? _pick(_clientIdAndroidDefine, 'CLIENT_ID_ANDROID')
      : _pick(_clientIdIosDefine, 'CLIENT_ID_IOS');

  static const _clientSecretAndroidDefine =
      String.fromEnvironment('CLIENT_SECRET_ANDROID');
  static const _clientSecretIosDefine =
      String.fromEnvironment('CLIENT_SECRET_IOS');
  static String get clientSecret => Platform.isAndroid
      ? _pick(_clientSecretAndroidDefine, 'CLIENT_SECRET_ANDROID')
      : _pick(_clientSecretIosDefine, 'CLIENT_SECRET_IOS');

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
  ///
  /// **Penting:** credential OAuth per platform. Di iOS yang dibaca adalah
  /// `CLIENT_ID_IOS` / `CLIENT_SECRET_IOS`, bukan nama generik `CLIENT_ID`.
  static void assertConfigured() {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'Konfigurasi API tidak lengkap: API_BASE_URL kosong. '
        'Isi di .env (dev) atau --dart-define=API_BASE_URL=... (release).',
      );
    }
    // `access_token`/`client_id`/`client_secret` dikirim lewat query string
    // (format API backend, lihat [authQuery]) — WAJIB HTTPS supaya credential
    // itu tetap terenkripsi in-transit, tidak bisa disadap di jaringan.
    if (!apiBaseUrl.startsWith('https://')) {
      throw StateError(
        'API_BASE_URL harus https:// — credential (access_token/client_id/'
        'client_secret) dikirim lewat query string, wajib terenkripsi TLS.',
      );
    }
    if (clientId.isEmpty || clientSecret.isEmpty) {
      final platformKeys = Platform.isAndroid
          ? 'CLIENT_ID_ANDROID dan CLIENT_SECRET_ANDROID'
          : 'CLIENT_ID_IOS dan CLIENT_SECRET_IOS';
      throw StateError(
        'Konfigurasi API tidak lengkap untuk ${Platform.operatingSystem}: '
        'isi $platformKeys (plus API_BASE_URL) di .env atau --dart-define. '
        'Hanya mengisi CLIENT_ID_ANDROID tidak cukup saat menjalankan di iPhone/Simulator.',
      );
    }
  }

  // ── Brand Spec APIs (Comforta, Spring Air, Therapedic, iSleep) ──
  // Semua berbagi bentuk endpoint yang sama: `/api/types_with_features`
  // dengan query access_token/client_id/client_secret. Tambah brand baru:
  // tambah 4 getter host/token/id/secret di bawah + satu entri di [brandSpecApis].

  static const _comfortaHostDefine =
      String.fromEnvironment('COMFORTA_API_HOST');
  static String get comfortaHost =>
      _pick(_comfortaHostDefine, 'COMFORTA_API_HOST', 'comforta.co.id');
  static const _comfortaAccessTokenDefine =
      String.fromEnvironment('COMFORTA_ACCESS_TOKEN');
  static String get comfortaAccessToken =>
      _pick(_comfortaAccessTokenDefine, 'COMFORTA_ACCESS_TOKEN');
  static const _comfortaClientIdDefine =
      String.fromEnvironment('COMFORTA_CLIENT_ID');
  static String get comfortaClientId =>
      _pick(_comfortaClientIdDefine, 'COMFORTA_CLIENT_ID');
  static const _comfortaClientSecretDefine =
      String.fromEnvironment('COMFORTA_CLIENT_SECRET');
  static String get comfortaClientSecret =>
      _pick(_comfortaClientSecretDefine, 'COMFORTA_CLIENT_SECRET');

  static const _springAirHostDefine =
      String.fromEnvironment('SPRINGAIR_API_HOST');
  static String get springAirHost =>
      _pick(_springAirHostDefine, 'SPRINGAIR_API_HOST', 'springair.co.id');
  static const _springAirAccessTokenDefine =
      String.fromEnvironment('SPRINGAIR_ACCESS_TOKEN');
  static String get springAirAccessToken =>
      _pick(_springAirAccessTokenDefine, 'SPRINGAIR_ACCESS_TOKEN');
  static const _springAirClientIdDefine =
      String.fromEnvironment('SPRINGAIR_CLIENT_ID');
  static String get springAirClientId =>
      _pick(_springAirClientIdDefine, 'SPRINGAIR_CLIENT_ID');
  static const _springAirClientSecretDefine =
      String.fromEnvironment('SPRINGAIR_CLIENT_SECRET');
  static String get springAirClientSecret =>
      _pick(_springAirClientSecretDefine, 'SPRINGAIR_CLIENT_SECRET');

  static const _therapedicHostDefine =
      String.fromEnvironment('THERAPEDIC_API_HOST');
  static String get therapedicHost => _pick(
      _therapedicHostDefine, 'THERAPEDIC_API_HOST', 'therapedic.co.id');
  static const _therapedicAccessTokenDefine =
      String.fromEnvironment('THERAPEDIC_ACCESS_TOKEN');
  static String get therapedicAccessToken =>
      _pick(_therapedicAccessTokenDefine, 'THERAPEDIC_ACCESS_TOKEN');
  static const _therapedicClientIdDefine =
      String.fromEnvironment('THERAPEDIC_CLIENT_ID');
  static String get therapedicClientId =>
      _pick(_therapedicClientIdDefine, 'THERAPEDIC_CLIENT_ID');
  static const _therapedicClientSecretDefine =
      String.fromEnvironment('THERAPEDIC_CLIENT_SECRET');
  static String get therapedicClientSecret =>
      _pick(_therapedicClientSecretDefine, 'THERAPEDIC_CLIENT_SECRET');

  static const _isleepHostDefine = String.fromEnvironment('ISLEEP_API_HOST');
  static String get isleepHost =>
      _pick(_isleepHostDefine, 'ISLEEP_API_HOST', 'isleep.co.id');
  static const _isleepAccessTokenDefine =
      String.fromEnvironment('ISLEEP_ACCESS_TOKEN');
  static String get isleepAccessToken =>
      _pick(_isleepAccessTokenDefine, 'ISLEEP_ACCESS_TOKEN');
  static const _isleepClientIdDefine =
      String.fromEnvironment('ISLEEP_CLIENT_ID');
  static String get isleepClientId =>
      _pick(_isleepClientIdDefine, 'ISLEEP_CLIENT_ID');
  static const _isleepClientSecretDefine =
      String.fromEnvironment('ISLEEP_CLIENT_SECRET');
  static String get isleepClientSecret =>
      _pick(_isleepClientSecretDefine, 'ISLEEP_CLIENT_SECRET');

  /// Semua brand spec API yang didukung. [brandSpecProvider] fetch tiap
  /// entri yang [BrandSpecApiConfig.isConfigured] lalu gabungkan hasilnya.
  static List<BrandSpecApiConfig> get brandSpecApis => [
        BrandSpecApiConfig(
          brand: 'Comforta',
          host: comfortaHost,
          accessToken: comfortaAccessToken,
          clientId: comfortaClientId,
          clientSecret: comfortaClientSecret,
        ),
        BrandSpecApiConfig(
          brand: 'Spring Air',
          host: springAirHost,
          accessToken: springAirAccessToken,
          clientId: springAirClientId,
          clientSecret: springAirClientSecret,
        ),
        BrandSpecApiConfig(
          brand: 'Therapedic',
          host: therapedicHost,
          accessToken: therapedicAccessToken,
          clientId: therapedicClientId,
          clientSecret: therapedicClientSecret,
        ),
        BrandSpecApiConfig(
          brand: 'iSleep',
          host: isleepHost,
          accessToken: isleepAccessToken,
          clientId: isleepClientId,
          clientSecret: isleepClientSecret,
        ),
      ];

  // ── Region API ─────────────────────────────────────────────────

  static const _regionApiBaseUrlDefine =
      String.fromEnvironment('REGION_API_BASE_URL');
  static String get regionApiBaseUrl => _pick(
        _regionApiBaseUrlDefine,
        'REGION_API_BASE_URL',
        'https://www.emsifa.com/api-wilayah-indonesia/api',
      );

  // ── Indirect sales: assigned toko (host terpisah + header API key) ──
  /// Base URL tanpa trailing slash, contoh: `http://host:8000`
  static const _indirectStoresBaseUrlDefine =
      String.fromEnvironment('INDIRECT_STORES_BASE_URL');
  static String get indirectStoresBaseUrl =>
      _pick(_indirectStoresBaseUrlDefine, 'INDIRECT_STORES_BASE_URL');

  static const _indirectApiKeyDefine =
      String.fromEnvironment('INDIRECT_API_KEY');
  static String get indirectApiKey =>
      _pick(_indirectApiKeyDefine, 'INDIRECT_API_KEY');

  static const _indirectClientKeyDefine =
      String.fromEnvironment('INDIRECT_CLIENT_KEY');
  static String get indirectClientKey =>
      _pick(_indirectClientKeyDefine, 'INDIRECT_CLIENT_KEY');

  /// True jika konfigurasi fetch daftar toko assign sudah lengkap.
  static bool get isIndirectStoresConfigured =>
      indirectStoresBaseUrl.isNotEmpty &&
      indirectApiKey.isNotEmpty &&
      indirectClientKey.isNotEmpty;

  // ── Product image fallbacks (see [ProductImageUtils] + [productDisplayImageProvider]) ──
  //
  // Jangan pakai URL random (picsum/unsplash) sebagai "isi" model: boros jaringan, tidak
  // on-brand, dan sulit di-cache. Pola yang dipakai app:
  // - [Product.imageUrl] = URL foto asli dari API, atau kosong bila tidak ada.
  // - Tampilan kartu/detail/keranjang = [productDisplayImageProvider] → spec Comforta,
  //   foto API, atau logo brand lokal (`asset://…`).
  // - Saat loading/error: shimmer/spinner + [NetworkImageView.errorWidget].

  /// Legacy neutral fallback (hindari untuk produk baru; prefer string kosong + provider).
  @Deprecated('Use empty imageUrl + productDisplayImageProvider')
  static const String placeholderProductImage =
      'https://images.unsplash.com/photo-1505693416022-14c1c9240ce4?q=80&w=800&auto=format&fit=crop';

  @Deprecated('Carousel no longer appends random stock photos')
  static const List<String> placeholderCarouselImages = [
    'https://images.unsplash.com/photo-1631679706909-1844bbd07221?q=80&w=800&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1583847268964-b28dc8f51f92?q=80&w=800&auto=format&fit=crop',
  ];

  /// When API row has no image field: empty string (synthetic → logo in UI via provider).
  static String placeholderProductImageById(dynamic id) => '';
}

/// Kredensial satu brand spec API (Comforta/Spring Air/Therapedic/dst).
/// Lihat [AppConfig.brandSpecApis].
class BrandSpecApiConfig {
  const BrandSpecApiConfig({
    required this.brand,
    required this.host,
    required this.accessToken,
    required this.clientId,
    required this.clientSecret,
  });

  final String brand;
  final String host;
  final String accessToken;
  final String clientId;
  final String clientSecret;

  bool get isConfigured =>
      accessToken.isNotEmpty && clientId.isNotEmpty && clientSecret.isNotEmpty;
}
