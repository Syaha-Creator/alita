import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/api_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthModel> login(String email, String password) async {
    try {
      final response = await apiClient.post(
        "/api/sign_in",
        data: {
          "email": email,
          "password": password,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
      );

      print(response.data);

      if (response.statusCode != 200 || response.data == null) {
        throw Exception("Login gagal: Respon tidak valid.");
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception("Format JSON tidak sesuai.");
      }

      // Jika response API baru, pastikan field token sesuai
      return AuthModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException(
            "Gagal terhubung ke server. Periksa koneksi Anda.");
      } else if (e.response != null) {
        throw ServerException("Email atau password salah. Silakan coba lagi.");
      } else {
        throw ServerException("Terjadi kesalahan yang tidak diketahui.");
      }
    }
  }
}
