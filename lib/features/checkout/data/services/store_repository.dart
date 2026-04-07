import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/services/api_client.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/retry.dart';
import '../models/store_model.dart';

/// Fetches the store master list from `/all_stores` with a 24-hour
/// file-based cache so the list survives app restarts without hitting
/// the API on every checkout.
class StoreRepository {
  StoreRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  static const String _cacheFileName = 'stores_cache_v1.json';
  static const String _cacheTimestampKey = 'ts';
  static const String _cacheDataKey = 'data';
  static const Duration _cacheTtl = Duration(hours: 24);

  static Directory? _cacheDir;

  static Future<File> _cacheFile() async {
    _cacheDir ??= await getApplicationSupportDirectory();
    return File('${_cacheDir!.path}/$_cacheFileName');
  }

  /// Returns all stores — from local cache if fresh, otherwise from API.
  /// Set [forceRefresh] to bypass cache/TTL and hit `/all_stores` again.
  /// Sorted alphabetically by store name (case-insensitive).
  Future<List<StoreModel>> getAllStores({bool forceRefresh = false}) async {
    if (forceRefresh) {
      return await _fetchAndCache();
    }
    final cached = await _loadCache();
    if (cached != null) return _sortStoresByName(cached);

    return await _fetchAndCache();
  }

  /// Forces a fresh fetch from API, bypassing any cache.
  Future<List<StoreModel>> refreshStores() => getAllStores(forceRefresh: true);

  Future<List<StoreModel>> _fetchAndCache() async {
    final response = await retry(
      () => _api.get('/all_stores'),
      maxAttempts: 2,
      tag: 'storeRepository',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil daftar toko (Status: ${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> rawList;
    if (decoded is List<dynamic>) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      rawList = (decoded['result'] as List<dynamic>?) ??
          (decoded['data'] as List<dynamic>?) ??
          [];
    } else {
      rawList = [];
    }
    final stores = rawList
        .whereType<Map<String, dynamic>>()
        .map(StoreModel.fromJson)
        .toList();

    final sorted = _sortStoresByName(stores);
    await _saveCache(sorted);
    return sorted;
  }

  static List<StoreModel> _sortStoresByName(List<StoreModel> stores) {
    final out = List<StoreModel>.from(stores);
    out.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return out;
  }

  // ── Cache helpers ────────────────────────────────────────────

  Future<List<StoreModel>?> _loadCache() async {
    try {
      final file = await _cacheFile();
      if (!file.existsSync()) return null;

      final raw = await file.readAsString();
      if (raw.isEmpty) return null;

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = decoded[_cacheTimestampKey] as int? ?? 0;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(ts);

      if (DateTime.now().difference(cacheTime) > _cacheTtl) return null;

      final data = decoded[_cacheDataKey] as List<dynamic>? ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(StoreModel.fromJson)
          .toList();
    } catch (e, st) {
      Log.error(e, st, reason: 'StoreRepository._loadCache');
      return null;
    }
  }

  Future<void> _saveCache(List<StoreModel> stores) async {
    try {
      final file = await _cacheFile();
      final payload = jsonEncode({
        _cacheTimestampKey: DateTime.now().millisecondsSinceEpoch,
        _cacheDataKey: stores.map((s) => s.toJson()).toList(),
      });
      await file.writeAsString(payload, flush: true);
    } catch (e, st) {
      Log.error(e, st, reason: 'StoreRepository._saveCache');
    }
  }
}
