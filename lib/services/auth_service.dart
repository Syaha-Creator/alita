import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../config/app_constant.dart';

class AuthService {
  static final ValueNotifier<bool> authChangeNotifier = ValueNotifier(false);
  static const int _sessionDuration = 24 * 60 * 60 * 1000;
  static const String _userNameKey = "current_user_name";
  static const String _userAreaIdKey = "current_user_area_id";

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

  static Future<bool> login(String token, String refreshToken, int userId,
      String userName, int? areaId) async {
    try {
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
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.rememberedEmail, email);
  }

  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.rememberedEmail);
  }

  static Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.rememberedEmail);
  }

  static Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.currentUserId);
  }

  static Future<int?> getCurrentUserAreaId() async {
    final prefs = await SharedPreferences.getInstance();
    final areaId = prefs.getInt(_userAreaIdKey);
    return areaId;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.authToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.refreshToken);
  }

  static Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString(StorageKeys.refreshToken);

    if (refreshToken == null) {
      await logout();
      return null;
    }

    try {
      Dio dio = Dio();
      final response = await dio.post(
        "${ApiConfig.baseUrl}oauth/token",
        data: {
          "grant_type": "refresh_token",
          "refresh_token": refreshToken,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200) {
        final newToken = response.data["access_token"];
        final newRefreshToken = response.data["refresh_token"];
        final userName = response.data["name"];
        final userId = response.data["id"];

        if (userId == null) {
          throw Exception("User ID not found in refresh token response.");
        }

        final success = await login(
            newToken, newRefreshToken, userId as int, userName as String, null);

        if (!success) throw Exception("Failed to store new token.");

        return newToken;
      } else {
        throw Exception("Invalid response: ${response.data}");
      }
    } catch (e) {
      await logout();
      return null;
    }
  }

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
}
