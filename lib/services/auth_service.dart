import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';
import '../config/dependency_injection.dart';
import '../features/approval/data/cache/approval_cache.dart';
import 'cart_storage_service.dart';
import 'team_hierarchy_service.dart';
import 'notification_service.dart';

/// Service untuk autentikasi, penyimpanan token, dan session user.
class AuthService {
  static final ValueNotifier<bool> authChangeNotifier = ValueNotifier(false);

  static const String _userNameKey = "current_user_name";
  static const String _userAreaIdKey = "current_user_area_id";

  /// Mengecek apakah user masih login dan session masih valid.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;

    authChangeNotifier.value = isLoggedIn;
    return isLoggedIn;
  }

  /// Menyimpan data login ke SharedPreferences.
  static Future<bool> login(String token, String refreshToken, int userId,
      String userName, int? areaId) async {
    try {
      // Clear all caches from previous user BEFORE saving new login data
      _clearAllUserRelatedCaches();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.isLoggedIn, true);
      await prefs.setInt(
          StorageKeys.loginTimestamp, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(StorageKeys.authToken, token);
      await prefs.setString(StorageKeys.refreshToken, refreshToken);
      await prefs.setInt(StorageKeys.currentUserId, userId);
      await prefs.setString(_userNameKey, userName);

      if (areaId != null) {
        await prefs.setInt(_userAreaIdKey, areaId);
      }
      authChangeNotifier.value = true;

      // Register FCM token ke backend setelah login berhasil
      try {
        final notificationService = NotificationService();
        await notificationService.registerTokenToBackend();
      } catch (e) {
        // Jangan gagalkan login jika register token gagal
        if (kDebugMode) {
          print('Error registering FCM token after login: $e');
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mengambil nama user yang sedang login.
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Menyimpan email yang diingat (remember me).
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.rememberedEmail, email);
  }

  /// Mengambil email yang diingat (remember me).
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.rememberedEmail);
  }

  /// Menghapus email yang diingat (remember me).
  static Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.rememberedEmail);
  }

  /// Mengambil user ID yang sedang login.
  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.currentUserId);
  }

  /// Mengambil area ID user yang sedang login.
  static Future<int?> getCurrentUserAreaId() async {
    final prefs = await SharedPreferences.getInstance();
    final areaId = prefs.getInt(_userAreaIdKey);
    return areaId;
  }

  /// Mengambil token autentikasi.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.authToken);
    return token;
  }

  /// Mengambil refresh token.
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.refreshToken);
  }

  /// Mengambil job level dari contact work experiences API
  static Future<String?> getJobLevel() async {
    try {
      final token = await getToken();
      final userId = await getCurrentUserId();

      if (token == null || userId == null) {
        return null;
      }

      final url = ApiConfig.getContactWorkExperienceUrl(
        token: token,
        userId: userId,
      );

      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.headers['ngrok-skip-browser-warning'] = 'true';
      dio.options.headers['User-Agent'] = 'AlitaPricelist/1.0';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic>? resultList = data is Map ? data['result'] : null;
        if (resultList != null && resultList.isNotEmpty) {
          final workExp = resultList.first;
          final jobLevel = workExp['job_level'];
          final jobLevelName =
              jobLevel is Map ? jobLevel['name'] : jobLevel?.toString();
          return jobLevelName;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user is manager level
  static Future<bool> isManagerLevel() async {
    final jobLevel = await getJobLevel();
    if (jobLevel == null) return false;

    // Define manager level keywords (adjust based on your job level naming)
    final managerKeywords = [
      'manager',
      'supervisor',
      'head',
      'chief',
      'director',
      'vp',
      'vice president',
      'senior',
      'lead',
      'coordinator'
    ];

    final isManager = managerKeywords.any(
        (keyword) => jobLevel.toLowerCase().contains(keyword.toLowerCase()));

    return isManager;
  }

  /// Melakukan refresh token dan update session.
  static Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString(StorageKeys.refreshToken);

    if (refreshToken == null) {
      await logout();
      return null;
    }

    final url = ApiConfig.signIn;

    try {
      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.headers['ngrok-skip-browser-warning'] = 'true';
      dio.options.headers['User-Agent'] = 'AlitaPricelist/1.0';

      final response = await dio.post(
        url,
        data: {
          "grant_type": "refresh_token",
          "refresh_token": refreshToken,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
      );

      if (response.statusCode == 200) {
        final newToken = response.data["access_token"];
        final newRefreshToken = response.data["refresh_token"];
        final userName = response.data["name"];
        final userId = response.data["id"];

        if (userId == null) {
          throw Exception("User ID not found in refresh token response.");
        }

        await login(
            newToken, newRefreshToken, userId as int, userName as String, null);

        return newToken;
      } else {
        throw Exception("Invalid response: ${response.data}");
      }
    } catch (e) {
      await logout();
      return null;
    }
  }

  /// Logout user dan hapus semua data session.
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.isLoggedIn);
      await prefs.remove(StorageKeys.loginTimestamp);
      await prefs.remove(StorageKeys.authToken);
      await prefs.remove(StorageKeys.refreshToken);
      await prefs.remove(StorageKeys.currentUserId);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userAreaIdKey);

      authChangeNotifier.value = false;

      // Clear all approval cache for security and privacy
      _clearAllUserRelatedCaches();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all user-related caches when logging out
  static void _clearAllUserRelatedCaches() {
    try {
      // Clear approval cache to prevent data leakage between users
      ApprovalCache.clearAllCache();

      // Clear cart storage (optional but recommended for clean logout)
      CartStorageService.clearCart();

      // Clear team hierarchy cache
      final teamHierarchyService = locator<TeamHierarchyService>();
      teamHierarchyService.clearCache();

      // Add other cache clearing here if needed in the future
      // Example: ProductCache.clear(), DraftCache.clear(), etc.
    } catch (e) {
      // Silent error - cache clearing is not critical for logout
      if (kDebugMode) {
        print('AuthService: Warning - Failed to clear caches on logout: $e');
      }
    }
  }

  /// Mengambil direct leader dan indirect leader dari contact work experiences API
  static Future<Map<String, dynamic>?> getLeaders() async {
    try {
      final token = await getToken();
      final userId = await getCurrentUserId();
      if (token == null || userId == null) return null;
      final url =
          ApiConfig.getContactWorkExperienceUrl(token: token, userId: userId);
      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.headers['ngrok-skip-browser-warning'] = 'true';
      dio.options.headers['User-Agent'] = 'AlitaPricelist/1.0';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic>? resultList = data is Map ? data['result'] : null;
        if (resultList != null && resultList.isNotEmpty) {
          final workExp = resultList.first;
          final directLeader = workExp['direct_leader'];
          final indirectLeader = workExp['indirect_leader'];
          return {
            'directLeader': directLeader,
            'indirectLeader': indirectLeader,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
