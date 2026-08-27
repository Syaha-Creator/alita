/// Staging vs production environment labels and pure resolution helpers.
///
/// Kept free of [String.fromEnvironment] / dotenv so unit tests can cover
/// URL ↔ env consistency and Paper payment path selection without compile flags.
class AppEnv {
  AppEnv._();

  static const String staging = 'staging';
  static const String production = 'production';

  /// Known Alita hosts (documentation / guards).
  static const String stagingApiBaseUrl =
      'https://staging.alitav2.massindo.com/api';
  static const String productionApiBaseUrl =
      'https://alitav2.massindo.com/api';

  /// Normalizes `APP_ENV` aliases → [staging] | [production] | `''`.
  static String normalize(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'production':
      case 'prod':
        return production;
      case 'staging':
      case 'stage':
      case 'dev':
      case 'development':
        return staging;
      default:
        return '';
    }
  }

  /// Prefer explicit `APP_ENV`; otherwise infer from `API_BASE_URL` host.
  static String resolve({
    required String explicit,
    required String apiBaseUrl,
  }) {
    final normalized = normalize(explicit);
    if (normalized.isNotEmpty) return normalized;
    final url = apiBaseUrl.trim().toLowerCase();
    if (url.contains('staging')) return staging;
    if (url.isEmpty) return staging; // safest default for local/dev
    return production;
  }

  /// Paper.id Alita path segment (not full URL).
  ///
  /// Staging: `paper_id_staging` — Production: `payper_id`
  /// (backend naming; override with non-empty [overridePath]).
  static String paperPaymentPath({
    required String appEnv,
    String overridePath = '',
  }) {
    final override = overridePath.trim();
    if (override.isNotEmpty) return override;
    return appEnv == production ? 'payper_id' : 'paper_id_staging';
  }

  /// Throws [StateError] when `APP_ENV` contradicts `API_BASE_URL`.
  static void assertConsistent({
    required String appEnv,
    required String apiBaseUrl,
  }) {
    final url = apiBaseUrl.trim().toLowerCase();
    if (url.isEmpty) return;

    if (appEnv == production && url.contains('staging')) {
      throw StateError(
        'APP_ENV=production tapi API_BASE_URL mengandung "staging" '
        '($apiBaseUrl). Pack production harus memakai '
        '$productionApiBaseUrl — atau set APP_ENV=staging.',
      );
    }
    if (appEnv == staging && !url.contains('staging')) {
      throw StateError(
        'APP_ENV=staging tapi API_BASE_URL tidak mengandung "staging" '
        '($apiBaseUrl). Dev/staging harus memakai $stagingApiBaseUrl — '
        'atau set APP_ENV=production.',
      );
    }
  }
}
