import 'package:dio/dio.dart';
import 'api_interceptor.dart';

/// Client HTTP untuk komunikasi dengan API backend menggunakan Dio.
class ApiClient {
  final Dio _dio;

  /// Inisialisasi ApiClient dengan interceptor dan timeout.
  ApiClient(this._dio) {
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
}
