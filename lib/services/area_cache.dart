import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/product/data/models/area_model.dart';

/// Service untuk cache areas di SharedPreferences
/// Digunakan sebagai fallback ketika API gagal
class AreaCache {
  static const String _cacheKey = 'cached_areas';
  static const String _cacheTimestampKey = 'cached_areas_timestamp';
  static const Duration _cacheExpiry = Duration(days: 7); // Cache valid 7 hari

  /// Simpan areas ke cache
  static Future<void> cacheAreas(List<AreaModel> areas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final areasJson = areas.map((area) => area.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(areasJson));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Silent fail - cache adalah fitur opsional
    }
  }

  /// Ambil areas dari cache
  static Future<List<AreaModel>?> getCachedAreas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);

      if (cachedString == null || cachedString.isEmpty) {
        return null;
      }

      // Check if cache is expired
      final timestamp = prefs.getInt(_cacheTimestampKey);
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(cacheTime) > _cacheExpiry) {
          // Cache expired, clear it
          await clearCache();
          return null;
        }
      }

      final List<dynamic> areasJson = jsonDecode(cachedString);
      return areasJson
          .map((json) => AreaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Ambil nama-nama area dari cache
  static Future<List<String>?> getCachedAreaNames() async {
    final areas = await getCachedAreas();
    if (areas == null || areas.isEmpty) return null;
    return areas.map((area) => area.name).toList();
  }

  /// Clear cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Check apakah ada cache yang valid
  static Future<bool> hasValidCache() async {
    final areas = await getCachedAreas();
    return areas != null && areas.isNotEmpty;
  }
}
