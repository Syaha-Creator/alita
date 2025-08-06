import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/error/exceptions.dart';
import 'api_interceptor.dart';

/// Client HTTP untuk komunikasi dengan API backend menggunakan Dio.
class ApiClient {
  late Dio _dio;

  /// Inisialisasi ApiClient dengan interceptor dan timeout.
  ApiClient() {
    _dio = Dio();
    _dio.interceptors.add(ApiInterceptor(_dio));
    // Set longer timeout for API calls
    _dio.options.connectTimeout = const Duration(seconds: 60); // 60 seconds
    _dio.options.receiveTimeout = const Duration(seconds: 60); // 60 seconds
    _dio.options.sendTimeout = const Duration(seconds: 60); // 60 seconds
  }

  /// Request GET ke endpoint tertentu.
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              "Request timeout. Server mungkin sedang sibuk. Silakan coba lagi.",
          type: e.type,
        );
      }
      rethrow;
    }
  }

  /// Request POST ke endpoint tertentu.
  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw DioException(
          requestOptions: e.requestOptions,
          error:
              "Request timeout. Server mungkin sedang sibuk. Silakan coba lagi.",
          type: e.type,
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLeaderByUser({
    required String token,
    required int userId,
  }) async {
    try {
      final url = ApiConfig.getLeaderByUserUrl(token: token, userId: userId);
      print('ApiClient: Making request to: $url');

      final response = await _dio.get(url);
      print('ApiClient: Response status: ${response.statusCode}');
      print('ApiClient: Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('ApiClient: Non-200 status code: ${response.statusCode}');
        throw ServerException(
            'Failed to fetch leader data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('ApiClient: DioException occurred: ${e.type} - ${e.message}');
      print('ApiClient: DioException response: ${e.response?.data}');
      throw ServerException('Network error: ${e.message}');
    } catch (e) {
      print('ApiClient: Unexpected error: $e');
      throw ServerException('Unexpected error: $e');
    }
  }
}
