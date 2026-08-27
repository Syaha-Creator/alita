import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_client.dart';
import '../../../../core/utils/log.dart';
import '../utils/region_api_parser.dart';

/// Fetches Indonesian administrative regions from Wilayah ID
/// ([AppConfig.regionApiBaseUrl], default `https://geo.velrox.cloud`)
/// and caches each endpoint on disk.
///
/// Uses [ApiClient.getExternal] (public API, no Alita auth).
class RegionService {
  RegionService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Bump when response shape changes so stale EMSIFA caches are ignored.
  static const _cachePrefix = 'geo_v1_';

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

  Future<void> _writeFile(String cacheKey, List<RegionItem> items) async {
    try {
      final f = await _cacheFile(cacheKey);
      await f.writeAsString(RegionApiParser.toCacheJson(items), flush: true);
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService._writeFile');
    }
  }

  Future<List<RegionItem>> _fetchAndCache({
    required String path,
    required String cacheKey,
  }) async {
    final key = '$_cachePrefix$cacheKey';
    try {
      final f = await _cacheFile(key);
      if (f.existsSync()) {
        final cached = await f.readAsString();
        if (cached.isNotEmpty) {
          final items = RegionApiParser.parseListBody(cached);
          if (items.isNotEmpty) return items;
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService read file cache');
    }

    try {
      final base = AppConfig.regionApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await _api.getExternal(
        '$base/$path',
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final items = RegionApiParser.parseListBody(response.body);
        if (items.isNotEmpty) {
          await _writeFile(key, items);
          return items;
        }
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'RegionService._fetchAndCache');
    }
    return const [];
  }

  Future<List<RegionItem>> getProvinces() => _fetchAndCache(
        path: 'api/provinsi',
        cacheKey: 'provinsi',
      );

  Future<List<RegionItem>> getRegencies(String provinceKode) =>
      _fetchAndCache(
        path: 'api/kabupaten?provinsi=$provinceKode',
        cacheKey: 'kabupaten_$provinceKode',
      );

  Future<List<RegionItem>> getDistricts(String regencyKode) => _fetchAndCache(
        path: 'api/kecamatan?kabupaten=$regencyKode',
        cacheKey: 'kecamatan_$regencyKode',
      );

  Future<List<RegionItem>> getVillages(String districtKode) => _fetchAndCache(
        path: 'api/desa?kecamatan=$districtKode',
        cacheKey: 'desa_$districtKode',
      );
}
