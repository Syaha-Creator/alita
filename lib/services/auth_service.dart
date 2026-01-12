import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';
import '../config/dependency_injection.dart';
import '../core/constants/timeouts.dart';
import '../features/approval/data/cache/approval_cache.dart';
import '../features/authentication/data/repositories/auth_repository.dart';
import 'notification_service.dart';
import 'firebase_error_service.dart';

/// Service untuk autentikasi, penyimpanan token, dan session user.
class AuthService {
  static final ValueNotifier<bool> authChangeNotifier = ValueNotifier(false);

  static const String _userNameKey = "current_user_name";
  static const String _userAreaIdKey = "current_user_area_id";
  static const String _userAreaNameKey = "current_user_area_name";

  /// Mengecek apakah user masih login dan session masih valid.
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<bool> isLoggedIn() async {
    try {
      final repository = locator<AuthRepository>();
      final isLoggedIn = await repository.isLoggedIn();
      authChangeNotifier.value = isLoggedIn;
      return isLoggedIn;
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
      authChangeNotifier.value = isLoggedIn;
      return isLoggedIn;
    }
  }

  /// Menyimpan data login ke SharedPreferences.
  static Future<bool> login(String token, String refreshToken, int userId,
      String userName, int? areaId,
      {String? areaName}) async {
    try {
      // Clear all caches from ALL users BEFORE saving new login data
      // This prevents data leakage between different users
      ApprovalCache.clearAllCacheForAllUsers();

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
      if (areaName != null && areaName.isNotEmpty) {
        await prefs.setString(_userAreaNameKey, areaName);
      }
      authChangeNotifier.value = true;

      // Set user ID untuk error tracking di Firebase
      await FirebaseErrorService().setUserId(userId.toString());

      // Register FCM token ke backend setelah login berhasil
      try {
        final notificationService = NotificationService();
        await notificationService.registerTokenToBackend();
      } catch (e, stackTrace) {
        // Jangan gagalkan login jika register token gagal
        FirebaseErrorService().logFcmError(
          'register_token_after_login',
          e,
          stackTrace: stackTrace,
          context: {'user_id': userId.toString()},
        );
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
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<int?> getCurrentUserId() async {
    try {
      final repository = locator<AuthRepository>();
      return await repository.getCurrentUserId();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(StorageKeys.currentUserId);
    }
  }

  /// Mengambil area ID user yang sedang login.
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<int?> getCurrentUserAreaId() async {
    try {
      final repository = locator<AuthRepository>();
      return await repository.getCurrentUserAreaId();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userAreaIdKey);
    }
  }

  /// Mengambil area name user yang sedang login (dari CWE).
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<String?> getCurrentUserAreaName() async {
    try {
      final repository = locator<AuthRepository>();
      return await repository.getCurrentUserAreaName();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userAreaNameKey);
    }
  }

  /// Mengambil token autentikasi.
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<String?> getToken() async {
    try {
      final repository = locator<AuthRepository>();
      return await repository.getToken();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.authToken);
    }
  }

  /// Mengambil refresh token.
  /// Uses AuthRepository if available, otherwise falls back to SharedPreferences
  static Future<String?> getRefreshToken() async {
    try {
      final repository = locator<AuthRepository>();
      return await repository.getRefreshToken();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(StorageKeys.refreshToken);
    }
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
      dio.options.connectTimeout = ApiTimeouts.standardConnectTimeout;
      dio.options.receiveTimeout = ApiTimeouts.standardReceiveTimeout;
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
      dio.options.connectTimeout = ApiTimeouts.standardConnectTimeout;
      dio.options.receiveTimeout = ApiTimeouts.standardReceiveTimeout;
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
      await prefs.remove(_userAreaNameKey);

      authChangeNotifier.value = false;

      // Clear all approval cache for security and privacy
      // Clear cache for current user first, then clear all
      final userId = await getCurrentUserId();
      if (userId != null) {
        ApprovalCache.clearAllCache(userId);
      }
      // Also clear all cache to ensure no data leakage
      ApprovalCache.clearAllCacheForAllUsers();

      return true;
    } catch (e) {
      return false;
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
      dio.options.connectTimeout = ApiTimeouts.standardConnectTimeout;
      dio.options.receiveTimeout = ApiTimeouts.standardReceiveTimeout;
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
