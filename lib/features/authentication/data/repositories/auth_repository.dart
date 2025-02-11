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
      print("📩 Password: $password");

      final response = await apiClient.post(
        "/oauth/token",
        queryParameters: {
          "grant_type": "password",
          "email": email,
          "password": password,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
      );

      print("✅ Response: ${response.data}");

      return AuthModel.fromJson(response.data);
    } catch (e) {
      print("❌ Error: $e");
      throw Exception("Login gagal: ${e.toString()}");
    }
  }
}
