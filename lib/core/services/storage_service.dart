import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/log.dart';

/// Storage service for persistent data.
///
/// Sensitive credentials (access token) are stored in [FlutterSecureStorage]
/// (encrypted keychain / keystore). All other data uses [SharedPreferences].
class StorageService {
  static const String _cartKey = 'cart_items';
  static const String _favoritesKey = 'favorite_ids';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _defaultAreaKey = 'default_area';
  static const String _accessTokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userImageUrlKey = 'user_image_url';
  static const String _areasCacheKey = 'master_areas_cache';
  static const String _channelsCacheKey = 'master_channels_cache';
  static const String _brandsCacheKey = 'master_brands_cache';
  static const String _masterDataLastSyncKey = 'master_data_last_sync';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const String _tokenMigratedKey = 'token_migrated_v1';

  /// Save cart data
  static Future<void> saveCart(List<Map<String, dynamic>> cartData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(cartData);
    await prefs.setString(_cartKey, jsonString);
  }

  /// Load cart data
  static Future<List<Map<String, dynamic>>> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cartKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      Log.warning('StorageService decode failed: $e', tag: 'Storage');
      return [];
    }
  }

  /// Save favorites (list of product IDs)
  static Future<void> saveFavorites(List<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, favoriteIds);
  }

  /// Load favorites
  static Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // ── Auth persistence ──

  static Future<void> saveAuth({
    required bool isLoggedIn,
    required String email,
    required String defaultArea,
    String accessToken = '',
    int userId = 0,
    String userName = '',
    String userImageUrl = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_defaultAreaKey, defaultArea);
    if (accessToken.isNotEmpty) {
      await _writeSecure(_accessTokenKey, accessToken);
    }
    if (userId > 0) {
      await prefs.setInt(_userIdKey, userId);
    }
    if (userName.isNotEmpty) {
      await prefs.setString(_userNameKey, userName);
    }
    if (userImageUrl.isNotEmpty) {
      await prefs.setString(_userImageUrlKey, userImageUrl);
    }
  }

  static Future<int> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey) ?? 0;
  }

  static Future<String> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  static Future<String> loadUserImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userImageUrlKey) ?? '';
  }

  static Future<bool> loadIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String> loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? '';
  }

  static Future<String> loadDefaultArea() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAreaKey) ?? 'Jakarta';
  }

  /// Loads the access token from encrypted secure storage.
  ///
  /// On first call after upgrade, migrates the token from SharedPreferences
  /// into secure storage and removes the plain-text copy.
  static Future<String> loadAccessToken() async {
    await _migrateTokenIfNeeded();
    return await _readSecure(_accessTokenKey) ?? '';
  }

  /// One-time migration: moves token from SharedPreferences → secure storage.
  static Future<void> _migrateTokenIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_tokenMigratedKey) == true) return;

    final legacyToken = prefs.getString(_accessTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _writeSecure(_accessTokenKey, legacyToken);
      await prefs.remove(_accessTokenKey);
    }
    await prefs.setBool(_tokenMigratedKey, true);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_defaultAreaKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userImageUrlKey);
    await _deleteSecure(_accessTokenKey);
  }

  // ── Master Data Cache ──

  /// Save master data JSON strings to local cache and record sync timestamp.
  /// Pass only the keys you want to update; others remain untouched.
  static Future<void> saveMasterData({
    String? areas,
    String? channels,
    String? brands,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (areas != null) await prefs.setString(_areasCacheKey, areas);
    if (channels != null) await prefs.setString(_channelsCacheKey, channels);
    if (brands != null) await prefs.setString(_brandsCacheKey, brands);
    await prefs.setInt(
      _masterDataLastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns the last time master data was successfully synced from API.
  /// Returns null if never synced.
  static Future<DateTime?> loadMasterDataLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_masterDataLastSyncKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Load cached areas JSON. Returns '[]' if nothing is cached.
  static Future<String> loadCachedAreas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_areasCacheKey) ?? '[]';
  }

  /// Load cached channels JSON. Returns '[]' if nothing is cached.
  static Future<String> loadCachedChannels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_channelsCacheKey) ?? '[]';
  }

  /// Load cached brands JSON. Returns '[]' if nothing is cached.
  static Future<String> loadCachedBrands() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_brandsCacheKey) ?? '[]';
  }

  /// Clear all stored data (including secure storage).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (e, st) {
      Log.error(e, st, reason: 'SecureStorage.deleteAll failed');
    }
  }

  // ── Secure storage helpers (defensive against Keystore failures) ──

  static Future<String?> _readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e, st) {
      Log.error(e, st, reason: 'SecureStorage.read($key) failed');
      return null;
    }
  }

  static Future<void> _writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e, st) {
      Log.error(e, st, reason: 'SecureStorage.write($key) failed');
    }
  }

  static Future<void> _deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e, st) {
      Log.error(e, st, reason: 'SecureStorage.delete($key) failed');
    }
  }

  // ── Pricelist snapshot cache (file-based) ──────────────────
  //
  // Large JSON pricelist data is written to individual files instead of
  // SharedPreferences to avoid OOM when the platform channel serialises
  // the entire preference map at once (~162 MB crash on low-end devices).

  static Directory? _plCacheDir;

  static Future<Directory> _ensurePlCacheDir() async {
    if (_plCacheDir != null) return _plCacheDir!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/pl_cache');
    if (!dir.existsSync()) await dir.create(recursive: true);
    _plCacheDir = dir;
    return dir;
  }

  /// Stable storage key for one pricelist filter combination.
  static String pricelistCacheStorageKey(
    String area,
    String channel,
    String brand,
  ) {
    final h = Object.hash(
      area.trim().toLowerCase(),
      channel.trim().toLowerCase(),
      brand.trim().toLowerCase(),
    );
    return 'alita_pl_v1_$h';
  }

  /// Persists mapped [Product.toJson()] rows for offline / error fallback.
  static Future<void> savePricelistProductRows(
    String storageKey,
    List<Map<String, dynamic>> rows,
  ) async {
    try {
      final dir = await _ensurePlCacheDir();
      final file = File('${dir.path}/$storageKey.json');
      final json = jsonEncode(<String, dynamic>{'v': 1, 'items': rows});
      await file.writeAsString(json, flush: true);
    } catch (e) {
      Log.warning('savePricelistProductRows: $e', tag: 'Storage');
    }
  }

  /// Returns cached JSON rows, or `null` if missing / invalid.
  static Future<List<Map<String, dynamic>>?> loadPricelistProductRows(
    String storageKey,
  ) async {
    try {
      final dir = await _ensurePlCacheDir();
      final file = File('${dir.path}/$storageKey.json');
      if (!file.existsSync()) return null;

      final raw = await file.readAsString();
      if (raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final list = decoded['items'];
      if (list is! List<dynamic>) return null;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e, st) {
      Log.error(e, st, reason: 'StorageService.loadPricelistProductRows');
      return null;
    }
  }

  /// Remove legacy pricelist data from SharedPreferences (one-time migration).
  /// Call once at startup to reclaim memory.
  static Future<void> migratePricelistCacheFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove =
        prefs.getKeys().where((k) => k.startsWith('alita_pl_v1_')).toList();
    if (keysToRemove.isEmpty) return;
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    Log.warning(
      'Removed ${keysToRemove.length} legacy pricelist keys from SharedPreferences',
      tag: 'Storage',
    );
  }
}
