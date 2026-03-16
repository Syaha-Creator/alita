import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persistent data
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
      // If decode fails, return empty list
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
      await prefs.setString(_accessTokenKey, accessToken);
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

  static Future<String> loadAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey) ?? '';
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_defaultAreaKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userImageUrlKey);
  }

  // ── Master Data Cache ──

  /// Save master data JSON strings to local cache.
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

  /// Clear all stored data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
