import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../core/error/exceptions.dart';
import '../core/constants/timeouts.dart';
import '../core/utils/error_logger.dart';
import 'api_interceptor.dart';

/// Client HTTP untuk komunikasi dengan API backend menggunakan Dio.
class ApiClient {
  late Dio _dio;

  /// Inisialisasi ApiClient dengan interceptor dan timeout.
  ApiClient() {
    _dio = Dio();
    _dio.interceptors.add(ApiInterceptor(_dio));
    // Set extended timeout for API calls
    _dio.options.connectTimeout = ApiTimeouts.extendedConnectTimeout;
    _dio.options.receiveTimeout = ApiTimeouts.extendedReceiveTimeout;
    _dio.options.sendTimeout = ApiTimeouts.extendedSendTimeout;
    // Don't set baseUrl - all URLs are already full URLs
  }

  /// Request GET ke endpoint tertentu.
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException {
      // Re-throw with original error to let caller handle it
      rethrow;
    } catch (e) {
      // For any other errors, wrap in DioException
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  /// Request POST ke endpoint tertentu.
  Future<Response> post(String path, {dynamic data}) async {
    if (kDebugMode) {
      ErrorLogger.logDebug(
        'ApiClient POST request',
        extra: {
          'path': path,
          'hasData': data != null,
        },
      );
    }

    try {
      // Ensure Content-Type is set to application/json for JSON data
      final options = Options(
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      final response = await _dio.post(
        path,
        data: data,
        options: options,
      );

      if (kDebugMode) {
        ErrorLogger.logDebug(
          'ApiClient POST response',
          extra: {
            'path': path,
            'statusCode': response.statusCode,
            'hasData': response.data != null,
          },
        );
      }

      return response;
    } on DioException catch (e, stackTrace) {
      // Log error before rethrowing
      if (kDebugMode) {
        ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'ApiClient POST failed',
          extra: {
            'path': path,
            'type': e.type.toString(),
            'message': e.message ?? 'No message',
            'error': e.error?.toString() ?? 'No error object',
            'responseStatusCode': e.response?.statusCode,
          },
          fatal: false,
        );
      }

      // Re-throw with original error to let caller handle it
      // This allows AuthRemoteDataSource to properly convert to NetworkException
      rethrow;
    } catch (e, stackTrace) {
      // Log unexpected errors
      if (kDebugMode) {
        ErrorLogger.logError(
          e,
          stackTrace: stackTrace,
          context: 'ApiClient POST unexpected error',
          extra: {
            'path': path,
            'errorType': e.runtimeType.toString(),
          },
          fatal: false,
        );
      }

      // For any other errors, wrap in DioException
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
        type: DioExceptionType.unknown,
      );
    }
  }

  Future<Map<String, dynamic>> getLeaderByUser({
    required String token,
    required String userId,
  }) async {
    try {
      final url = ApiConfig.getLeaderByUserUrl(token: token, userId: userId);
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
            'Failed to fetch leader data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> getTeamHierarchy({
    required String token,
    required String userId,
  }) async {
    try {
      final url = ApiConfig.getTeamHierarchyUrl(token: token, userId: userId);
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw ServerException(
            'Failed to fetch team hierarchy data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }
}
