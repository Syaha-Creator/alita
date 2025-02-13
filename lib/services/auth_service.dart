import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService {
  static final ValueNotifier<bool> authChangeNotifier = ValueNotifier(false);
  static const String _isLoggedInKey = "is_logged_in";
  static const String _loginTimestampKey = "login_timestamp";
  static const String _tokenKey = "auth_token";
  static const String _refreshTokenKey = "refresh_token";
  static const int _sessionDuration = 24 * 60 * 60 * 1000;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    int? loginTimestamp = prefs.getInt(_loginTimestampKey);
    String? token = prefs.getString(_tokenKey);

    if (isLoggedIn && loginTimestamp != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - loginTimestamp > _sessionDuration || token == null) {
        print("⏳ Session expired, logging out...");
        await logout();
        return false;
      }
    }

    authChangeNotifier.value = isLoggedIn;
    return isLoggedIn;
  }

  static Future<bool> login(String token, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setInt(
          _loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);

      print("🔐 Token saved successfully!");
      authChangeNotifier.value = true;
      return true;
    } catch (e) {
      print("❌ Failed to save token: $e");
      return false;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_tokenKey);
    print("🔑 Retrieved Token: $token");
    return token;
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) {
      print("⚠️ No refresh token found, logging out...");
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

        final success = await login(newToken, newRefreshToken);
        if (!success) throw Exception("Failed to store new token.");

        return newToken;
      } else {
        throw Exception("Invalid response: ${response.data}");
      }
    } catch (e) {
      print("❌ Refresh token failed, logging out...");
      await logout();
      return null;
    }
  }

  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_loginTimestampKey);
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);

      print("🚪 User logged out successfully!");
      authChangeNotifier.value = false;
      return true;
    } catch (e) {
      print("❌ Failed to log out: $e");
      return false;
    }
  }
}
