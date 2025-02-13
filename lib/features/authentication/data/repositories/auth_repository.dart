import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../services/api_client.dart';
import '../models/auth_model.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository({required this.apiClient});

  Future<AuthModel> login(String email, String password) async {
    try {
      print("🔵 Sending login request...");
      print("📩 Email: $email");

      final response = await apiClient.post(
        "/oauth/token",
        data: {
          "grant_type": "password",
          "email": email,
          "password": password,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception("Login gagal: Respon tidak valid.");
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception("Format JSON tidak sesuai.");
      }

      print("✅ Response: ${response.data}");
      return AuthModel.fromJson(response.data);
    } on DioException catch (e) {
      print("❌ API Error: ${e.response?.data ?? e.message}");
      throw Exception("Login gagal: ${e.response?.data ?? e.message}");
    } catch (e) {
      print("❌ Unexpected Error: $e");
      throw Exception("Terjadi kesalahan saat login.");
    }
  }
}
