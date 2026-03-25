import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/log.dart';

/// Fetches Indonesian administrative region data from the Emsifa open API
/// and caches each endpoint on disk (not SharedPreferences) to avoid large
/// platform-channel payloads / OOM on low-memory devices.
///
/// Uses [ApiClient.getExternal] because this is a third-party public API
/// (no auth required, different host from the main backend).
class RegionService {
  static final ApiClient _api = ApiClient.instance;

  Future<Directory> _ensureCacheDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}/region_cache');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _cacheFile(String cacheKey) async {
    final dir = await _ensureCacheDir();
    return File('${dir.path}/$cacheKey.json');
  }

  Future<void> _writeFile(String cacheKey, String body) async {
    try {
      final f = await _cacheFile(cacheKey);
      await f.writeAsString(body, flush: true);
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService._writeFile');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAndCache(
    String endpoint,
    String cacheKey,
  ) async {
    try {
      final f = await _cacheFile(cacheKey);
      if (f.existsSync()) {
        final cached = await f.readAsString();
        if (cached.isNotEmpty) {
          final decoded = json.decode(cached);
          if (decoded is List) {
            return decoded.cast<Map<String, dynamic>>();
          }
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService read file cache');
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(cacheKey);
    if (legacy != null && legacy.isNotEmpty) {
      try {
        final decoded = json.decode(legacy);
        if (decoded is List) {
          final list = decoded.cast<Map<String, dynamic>>();
          await _writeFile(cacheKey, legacy);
          try {
            await prefs.remove(cacheKey);
          } catch (_) {}
          return list;
        }
      } catch (e, st) {
        Log.error(e, st, reason: 'RegionService legacy prefs decode');
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
          await _writeFile(cacheKey, response.body);
          try {
            await prefs.remove(cacheKey);
          } catch (_) {}
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService._fetchAndCache');
    }
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
