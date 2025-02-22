import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? dioClient})
      : dio = dioClient ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    setupInterceptors();
  }

  void setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await AuthService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          print("🌍 API Request: ${options.method} ${options.path}");
          print("📦 Request Headers: ${options.headers}");
          return handler.next(options);
        } catch (e) {
          print("❌ Error in Request Interceptor: $e");
          return handler.reject(DioException(
            requestOptions: options,
            error: "Gagal mendapatkan token",
            type: DioExceptionType.unknown,
          ));
        }
      },
      onResponse: (response, handler) {
        print("✅ API Response: ${response.statusCode}");
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print("❌ API Error: ${e.response?.statusCode} - ${e.message}");

        if (e.response?.statusCode == 401) {
          try {
            print("🔄 Refreshing token...");
            final newToken = await AuthService.refreshToken();
            if (newToken != null) {
              e.requestOptions.headers["Authorization"] = "Bearer $newToken";
              final newResponse = await dio.fetch(e.requestOptions);
              return handler.resolve(newResponse);
            }
          } catch (refreshError) {
            print("❌ Failed to refresh token: $refreshError");
          }
        }

        return handler.next(e);
      },
    ));
  }

  Future<Response> post(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters}) async {
    return await dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) async {
    print("🌍 GET Request: $path");
    return await dio.get(path, queryParameters: params);
  }
}
