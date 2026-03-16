import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_client.dart';

/// Fetches Indonesian administrative region data from the Emsifa open API
/// and caches each endpoint in SharedPreferences to avoid repeated network calls.
///
/// Uses [ApiClient.getExternal] because this is a third-party public API
/// (no auth required, different host from the main backend).
class RegionService {
  static final ApiClient _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> _fetchAndCache(
    String endpoint,
    String cacheKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final decoded = json.decode(cached);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    }

    try {
      final response = await _api.getExternal(
        '${AppConfig.regionApiBaseUrl}/$endpoint',
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          await prefs.setString(cacheKey, response.body);
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> getProvinces() =>
      _fetchAndCache('provinces.json', 'cache_provinces');

  Future<List<Map<String, dynamic>>> getRegencies(String provinceId) =>
      _fetchAndCache(
        'regencies/$provinceId.json',
        'cache_regencies_$provinceId',
      );

  Future<List<Map<String, dynamic>>> getDistricts(String regencyId) =>
      _fetchAndCache(
        'districts/$regencyId.json',
        'cache_districts_$regencyId',
      );
}
