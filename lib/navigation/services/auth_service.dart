import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = "is_logged_in";
  static const String _loginTimestampKey = "login_timestamp";
  static const String _tokenKey = "auth_token";
  static const int _sessionDuration = 24 * 60 * 60 * 1000;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    int? loginTimestamp = prefs.getInt(_loginTimestampKey);
    String? token = prefs.getString(_tokenKey);

    if (isLoggedIn && loginTimestamp != null) {
      int currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - loginTimestamp > _sessionDuration || token == null) {
        await logout();
        return false;
      }
    }
    return isLoggedIn;
  }

  static Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(
        _loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_loginTimestampKey);
    await prefs.remove(_tokenKey);
  }
}
