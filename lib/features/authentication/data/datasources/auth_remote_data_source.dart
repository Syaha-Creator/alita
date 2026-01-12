import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/error_logger.dart';
import '../../../../services/api_client.dart';
import '../models/auth_model.dart';

/// Remote data source untuk authentikasi API calls
abstract class AuthRemoteDataSource {
  Future<AuthModel> login(String email, String password);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AuthModel> login(String email, String password) async {
    try {
      final loginUrl = ApiConfig.getLoginUrl();

      if (kDebugMode) {
        ErrorLogger.logDebug(
          'Attempting login',
          extra: {
            'email': email,
            'url': loginUrl,
            'hasClientId': ApiConfig.clientId.isNotEmpty,
            'hasClientSecret': ApiConfig.clientSecret.isNotEmpty,
          },
        );
      }

      // Use full URL for login (not relative path) to ensure proper connection
      // client_id and client_secret are already in the URL query parameters
      final response = await apiClient.post(
        loginUrl,
        data: {
          "email": email,
          "password": password,
        },
      );

      if (kDebugMode) {
        ErrorLogger.logDebug(
          'Login response received',
          extra: {
            'statusCode': response.statusCode,
            'hasData': response.data != null,
          },
        );
      }

      if (kDebugMode) {
        ErrorLogger.logDebug(
          'Login response validation',
          extra: {
            'statusCode': response.statusCode,
            'hasData': response.data != null,
            'dataType': response.data?.runtimeType.toString(),
            'dataPreview': response.data?.toString().substring(
                0,
                response.data.toString().length > 200
                    ? 200
                    : response.data.toString().length),
          },
        );
      }

      if (response.statusCode != 200) {
        final errorMessage = response.data is Map
            ? (response.data['message'] ??
                response.data['error'] ??
                'Login gagal')
            : 'Login gagal: Status code ${response.statusCode}';
        throw ServerException(errorMessage.toString());
      }

      if (response.data == null) {
        throw ServerException("Login gagal: Respon tidak valid (data null).");
      }

      if (response.data is! Map<String, dynamic>) {
        if (kDebugMode) {
          ErrorLogger.logError(
            Exception('Invalid response format'),
            context: 'Login response is not Map',
            extra: {
              'dataType': response.data.runtimeType.toString(),
              'data': response.data.toString(),
            },
            fatal: false,
          );
        }
        throw ServerException("Format JSON tidak sesuai.");
      }

      try {
        return AuthModel.fromJson(response.data);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to parse AuthModel from response',
            extra: {
              'responseData': response.data.toString(),
            },
            fatal: false,
          );
        }
        throw ServerException("Gagal memproses data login: ${e.toString()}");
      }
    } on DioException catch (e, stackTrace) {
      // Log error details for debugging
      if (kDebugMode) {
        ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Login failed - DioException',
          extra: {
            'type': e.type.toString(),
            'message': e.message ?? 'No message',
            'error': e.error?.toString() ?? 'No error object',
            'responseStatusCode': e.response?.statusCode,
            'responseData': e.response?.data?.toString(),
            'requestPath': e.requestOptions.path,
          },
          fatal: false,
        );
      }

      // Handle all network-related errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        // Check if it's actually a network error
        final errorMessage = e.message?.toLowerCase() ?? '';
        final isNetworkError = errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('timeout') ||
            errorMessage.contains('failed host lookup') ||
            errorMessage.contains('socket') ||
            e.error?.toString().toLowerCase().contains('network') == true ||
            e.error?.toString().toLowerCase().contains('connection') == true;

        if (isNetworkError || e.type == DioExceptionType.connectionError) {
          throw NetworkException(
            "Gagal terhubung ke server. Periksa koneksi Anda.",
          );
        }
      }

      // Handle server response errors (4xx, 5xx)
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        // Try to extract error message from response
        String? errorMessage;
        if (responseData is Map) {
          errorMessage = responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              responseData['errors']?.toString();
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        if (statusCode == 401 || statusCode == 403) {
          throw ServerException(
            errorMessage ?? "Email atau password salah. Silakan coba lagi.",
          );
        } else if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500) {
          throw ServerException(
            errorMessage ?? "Permintaan tidak valid. Silakan coba lagi.",
          );
        } else if (statusCode != null && statusCode >= 500) {
          throw ServerException(
            errorMessage ??
                "Server sedang mengalami masalah. Silakan coba lagi nanti.",
          );
        } else {
          throw ServerException(
            errorMessage ?? "Email atau password salah. Silakan coba lagi.",
          );
        }
      }

      // Handle other DioException types
      if (e.type == DioExceptionType.badResponse) {
        throw ServerException("Respon server tidak valid.");
      }

      // Default: treat as network error if no response
      if (e.response == null) {
        final errorMsg = e.message ?? e.error?.toString() ?? 'Unknown error';
        if (kDebugMode) {
          ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Login failed - No response from server',
            extra: {
              'errorMessage': errorMsg,
              'errorType': e.type.toString(),
            },
            fatal: false,
          );
        }
        throw NetworkException(
          "Gagal terhubung ke server. Periksa koneksi Anda.\nError: $errorMsg",
        );
      }

      throw ServerException(
          "Terjadi kesalahan yang tidak diketahui: ${e.message ?? e.error?.toString() ?? 'Unknown'}");
    } catch (e, stackTrace) {
      // Log unexpected errors
      if (kDebugMode) {
        ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'Login failed - Unexpected error',
          extra: {
            'errorType': e.runtimeType.toString(),
            'errorMessage': e.toString(),
          },
          fatal: false,
        );
      }

      // Handle any other exceptions
      if (e is NetworkException || e is ServerException) {
        rethrow;
      }
      throw ServerException("Terjadi kesalahan saat login: ${e.toString()}");
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final url = ApiConfig.signIn;

      final dio = Dio();
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

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException("Invalid response: ${response.data}");
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          "Gagal terhubung ke server. Periksa koneksi Anda.",
        );
      } else {
        throw ServerException("Gagal refresh token: ${e.message}");
      }
    }
  }
}
