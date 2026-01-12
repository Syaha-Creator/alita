import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/auth_model.dart';

/// Repository implementation untuk authentikasi
/// Menggunakan remote dan local datasources sesuai Clean Architecture
class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Login user dengan email dan password
  Future<AuthModel> login(String email, String password) async {
    try {
      // Call remote data source untuk login
      final authModel = await remoteDataSource.login(email, password);

      // Save login data to local storage
      await localDataSource.saveLoginData(
        token: authModel.accessToken,
        refreshToken: authModel.refreshToken,
        userId: authModel.id,
        userName: authModel.name,
        areaId: authModel.areaId,
        areaName: authModel.area,
      );

      return authModel;
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException("Terjadi kesalahan saat login: ${e.toString()}");
    }
  }

  /// Refresh token
  Future<String?> refreshToken() async {
    try {
      final refreshTokenValue = await localDataSource.getRefreshToken();

      if (refreshTokenValue == null) {
        await localDataSource.clearLoginData();
        return null;
      }

      final response = await remoteDataSource.refreshToken(refreshTokenValue);

      final newToken = response["access_token"] as String?;
      final newRefreshToken = response["refresh_token"] as String?;
      final userName = response["name"] as String?;
      final userId = response["id"] as int?;

      if (userId == null || newToken == null || newRefreshToken == null) {
        throw ServerException(
          "User ID atau token tidak ditemukan dalam response refresh token.",
        );
      }

      // Save new login data
      await localDataSource.saveLoginData(
        token: newToken,
        refreshToken: newRefreshToken,
        userId: userId,
        userName: userName ?? '',
      );

      return newToken;
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      await localDataSource.clearLoginData();
      return null;
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  /// Get current user ID
  Future<int?> getCurrentUserId() async {
    return await localDataSource.getCurrentUserId();
  }

  /// Get current user name
  Future<String?> getCurrentUserName() async {
    return await localDataSource.getCurrentUserName();
  }

  /// Get current user area ID
  Future<int?> getCurrentUserAreaId() async {
    return await localDataSource.getCurrentUserAreaId();
  }

  /// Get current user area name
  Future<String?> getCurrentUserAreaName() async {
    return await localDataSource.getCurrentUserAreaName();
  }

  /// Get auth token
  Future<String?> getToken() async {
    return await localDataSource.getToken();
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await localDataSource.getRefreshToken();
  }

  /// Logout user
  Future<bool> logout() async {
    try {
      await localDataSource.clearLoginData();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save email (remember me)
  Future<void> saveEmail(String email) async {
    await localDataSource.saveEmail(email);
  }

  /// Get saved email
  Future<String?> getSavedEmail() async {
    return await localDataSource.getSavedEmail();
  }

  /// Clear saved email
  Future<void> clearSavedEmail() async {
    await localDataSource.clearSavedEmail();
  }

  /// Get auth change notifier
  ValueNotifier<bool> get authChangeNotifier =>
      localDataSource.authChangeNotifier;

  /// Save login data (wrapper for local data source)
  Future<bool> saveLoginData({
    required String token,
    required String refreshToken,
    required int userId,
    required String userName,
    int? areaId,
    String? areaName,
  }) async {
    return await localDataSource.saveLoginData(
      token: token,
      refreshToken: refreshToken,
      userId: userId,
      userName: userName,
      areaId: areaId,
      areaName: areaName,
    );
  }
}
