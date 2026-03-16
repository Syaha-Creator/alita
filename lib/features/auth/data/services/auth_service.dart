import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/api_client.dart';

/// Parsed result from a successful login API call.
class AuthLoginResult {
  final String accessToken;
  final String userEmail;
  final int userId;
  final String userName;
  final String userImageUrl;
  final int areaId;

  const AuthLoginResult({
    required this.accessToken,
    required this.userEmail,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    required this.areaId,
  });
}

/// Encapsulates all authentication HTTP calls.
///
/// The login endpoint uses client_credentials (not a bearer token),
/// so it builds the URI via [ApiClient.buildUri] but performs the POST
/// directly — the only endpoint in the app that works this way.
class AuthService {
  AuthService({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /// Authenticates [email]/[password] against the on-premise API.
  ///
  /// Returns an [AuthLoginResult] on success.
  /// Throws a user-facing [String] message on any failure.
  Future<AuthLoginResult> login(String email, String password) async {
    if (AppConfig.apiBaseUrl.isEmpty || AppConfig.clientId.isEmpty) {
      throw 'Konfigurasi API tidak lengkap. Periksa file .env';
    }

    final uri = _api.buildUri('/sign_in', AppConfig.clientCredentials);

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );
    } on SocketException {
      throw 'Periksa koneksi internet Anda.';
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return _parseSuccessResponse(response.body, email);
    }

    throw _parseErrorResponse(response);
  }

  // ── Response parsing ─────────────────────────────────────────

  AuthLoginResult _parseSuccessResponse(String body, String fallbackEmail) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      throw 'Format response tidak valid dari server.';
    }

    final token = data['token'];
    if (token == null || token.toString().isEmpty) {
      throw 'Token tidak ditemukan dalam response server.';
    }

    final user = data['user'];
    if (user == null || user is! Map<String, dynamic>) {
      throw 'Data user tidak ditemukan dalam response server.';
    }

    final rawUserId = user['id'];
    final imageObj = user['image'];

    return AuthLoginResult(
      accessToken: token.toString(),
      userEmail: user['email']?.toString() ?? fallbackEmail,
      userId: rawUserId is int
          ? rawUserId
          : int.tryParse(rawUserId?.toString() ?? '') ?? 0,
      userName:
          user['name']?.toString() ?? user['user_name']?.toString() ?? '',
      userImageUrl: imageObj is Map<String, dynamic>
          ? (imageObj['url']?.toString() ?? '')
          : '',
      areaId: (user['area_id'] as num?)?.toInt() ?? 0,
    );
  }

  String _parseErrorResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Email atau Password yang Anda masukkan salah.';
    }
    if (response.statusCode >= 500) {
      return 'Terjadi masalah pada server. Silakan coba lagi nanti.';
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['error']?.toString() ??
          data['message']?.toString() ??
          'Login gagal (${response.statusCode})';
    } catch (_) {
      return 'Login gagal (${response.statusCode})';
    }
  }
}
