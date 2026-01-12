import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/app_constant.dart';

/// Local data source untuk session management (SharedPreferences)
abstract class AuthLocalDataSource {
  Future<bool> isLoggedIn();
  Future<bool> saveLoginData({
    required String token,
    required String refreshToken,
    required int userId,
    required String userName,
    int? areaId,
    String? areaName,
  });
  Future<void> clearLoginData();
  Future<String?> getToken();
  Future<String?> getRefreshToken();
  Future<int?> getCurrentUserId();
  Future<String?> getCurrentUserName();
  Future<int?> getCurrentUserAreaId();
  Future<String?> getCurrentUserAreaName();
  Future<void> saveEmail(String email);
  Future<String?> getSavedEmail();
  Future<void> clearSavedEmail();
  ValueNotifier<bool> get authChangeNotifier;
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  SharedPreferences? _sharedPreferences;
  final ValueNotifier<bool> _authChangeNotifier = ValueNotifier(false);

  static const String _userNameKey = "current_user_name";
  static const String _userAreaIdKey = "current_user_area_id";
  static const String _userAreaNameKey = "current_user_area_name";

  AuthLocalDataSourceImpl({SharedPreferences? sharedPreferences})
      : _sharedPreferences = sharedPreferences;

  /// Lazy initialization of SharedPreferences
  Future<SharedPreferences> get _prefs async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  @override
  ValueNotifier<bool> get authChangeNotifier => _authChangeNotifier;

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    final isLoggedIn = prefs.getBool(StorageKeys.isLoggedIn) ?? false;
    _authChangeNotifier.value = isLoggedIn;
    return isLoggedIn;
  }

  @override
  Future<bool> saveLoginData({
    required String token,
    required String refreshToken,
    required int userId,
    required String userName,
    int? areaId,
    String? areaName,
  }) async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(StorageKeys.isLoggedIn, true);
      await prefs.setInt(
        StorageKeys.loginTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      );
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

      _authChangeNotifier.value = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> clearLoginData() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.isLoggedIn);
    await prefs.remove(StorageKeys.loginTimestamp);
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.refreshToken);
    await prefs.remove(StorageKeys.currentUserId);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userAreaIdKey);
    await prefs.remove(_userAreaNameKey);
    _authChangeNotifier.value = false;
  }

  @override
  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.authToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.refreshToken);
  }

  @override
  Future<int?> getCurrentUserId() async {
    final prefs = await _prefs;
    return prefs.getInt(StorageKeys.currentUserId);
  }

  @override
  Future<String?> getCurrentUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_userNameKey);
  }

  @override
  Future<int?> getCurrentUserAreaId() async {
    final prefs = await _prefs;
    return prefs.getInt(_userAreaIdKey);
  }

  @override
  Future<String?> getCurrentUserAreaName() async {
    final prefs = await _prefs;
    return prefs.getString(_userAreaNameKey);
  }

  @override
  Future<void> saveEmail(String email) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.rememberedEmail, email);
  }

  @override
  Future<String?> getSavedEmail() async {
    final prefs = await _prefs;
    return prefs.getString(StorageKeys.rememberedEmail);
  }

  @override
  Future<void> clearSavedEmail() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.rememberedEmail);
  }
}

