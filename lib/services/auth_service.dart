import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';

/// Service untuk autentikasi, penyimpanan token, dan session user.
class AuthService {
  static final ValueNotifier<bool> authChangeNotifier = ValueNotifier(false);
  static const int _sessionDuration = 24 * 60 * 60 * 1000;
  static const String _userNameKey = "current_user_name";
  static const String _userAreaIdKey = "current_user_area_id";

  /// Mengecek apakah user masih login dan session masih valid.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    int? loginTimestamp = prefs.getInt(StorageKeys.loginTimestamp);
    String? token = prefs.getString(StorageKeys.authToken);

    if (isLoggedIn && loginTimestamp != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - loginTimestamp > _sessionDuration || token == null) {
        await logout();
        return false;
      }
    }

    authChangeNotifier.value = isLoggedIn;
    return isLoggedIn;
  }

  /// Menyimpan data login ke SharedPreferences.
  static Future<bool> login(String token, String refreshToken, int userId,
      String userName, int? areaId) async {
    try {
      print("AuthService: Storing login data...");
      print(
          "AuthService: Token: ${token.length >= 10 ? "${token.substring(0, 10)}..." : token}");
      if (refreshToken.isNotEmpty) {
        print(
            "AuthService: Refresh token: ${refreshToken.length >= 10 ? "${refreshToken.substring(0, 10)}..." : refreshToken}");
      } else {
        print("AuthService: Refresh token: (empty)");
      }
      print("AuthService: User ID: $userId");
      print("AuthService: User name: $userName");

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

      print("AuthService: Login data stored successfully");
      return true;
    } catch (e) {
      print("AuthService: Error storing login data: $e");
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
    print(
        "AuthService: Retrieved token: ${token != null ? '${token.substring(0, 10)}...' : 'null'}");
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
        print("AuthService: Token or userId is null");
        return null;
      }

      final url = ApiConfig.getContactWorkExperienceUrl(
        token: token,
        userId: userId,
      );

      print("AuthService: Fetching job level from: $url");

      Dio dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.headers['ngrok-skip-browser-warning'] = 'true';
      dio.options.headers['User-Agent'] = 'AlitaPricelist/1.0';

      final response = await dio.get(url);

      print("AuthService: Job level response status: ${response.statusCode}");
      print("AuthService: Job level response data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic>? resultList = data is Map ? data['result'] : null;
        if (resultList != null && resultList.isNotEmpty) {
          final workExp = resultList.first;
          final jobLevel = workExp['job_level'];
          final jobLevelName =
              jobLevel is Map ? jobLevel['name'] : jobLevel?.toString();
          print("AuthService: Job level determined: $jobLevelName");
          return jobLevelName;
        }
      }

      print("AuthService: No job level found in response");
      return null;
    } catch (e) {
      print("AuthService: Error fetching job level: $e");
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

    print("AuthService: User job level: $jobLevel, isManager: $isManager");
    return isManager;
  }

  /// Melakukan refresh token dan update session.
  static Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString(StorageKeys.refreshToken);

    if (refreshToken == null) {
      print("AuthService: Refresh token is null, logging out user");
      await logout();
      return null;
    }

    print("AuthService: Attempting to refresh token...");
    print("AuthService: Refresh token: ${refreshToken.substring(0, 10)}...");
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

      print(
          "AuthService: Refresh token response status: ${response.statusCode}");
      print("AuthService: Refresh token response data: ${response.data}");

      if (response.statusCode == 200) {
        final newToken = response.data["access_token"];
        final newRefreshToken = response.data["refresh_token"];
        final userName = response.data["name"];
        final userId = response.data["id"];

        if (userId == null) {
          print("AuthService: User ID not found in refresh token response");
          throw Exception("User ID not found in refresh token response.");
        }

        print("AuthService: Storing new token...");
        final success = await login(
            newToken, newRefreshToken, userId as int, userName as String, null);

        if (!success) {
          print("AuthService: Failed to store new token after refresh");
          throw Exception("Failed to store new token.");
        }

        print("AuthService: Token refreshed successfully");
        return newToken;
      } else {
        print(
            "AuthService: Invalid response from refresh token endpoint: ${response.statusCode}");
        throw Exception("Invalid response: ${response.data}");
      }
    } catch (e) {
      print("AuthService: Error refreshing token: $e");
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
      print("AuthService: Error fetching leaders: $e");
      return null;
    }
  }
}
