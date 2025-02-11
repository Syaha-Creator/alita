import 'package:alita_pricelist/services/auth_service.dart';
import 'package:dio/dio.dart';

import '../config/api_config.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? dioClient})
      : dio = dioClient ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)) {
    setupInterceptors();
  }

  void setupInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // ✅ Ambil token sebelum mengirim request
        final token = await AuthService.getToken();
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        print("🌍 API Request: ${options.method} ${options.path}");
        print("📦 Request Headers: ${options.headers}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print("✅ API Response: ${response.statusCode}");
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        print("❌ API Error: ${e.response?.statusCode}");

        // ✅ Jika token expired (401), coba refresh token
        if (e.response?.statusCode == 401) {
          final newToken = await AuthService.refreshToken();
          if (newToken != null) {
            e.requestOptions.headers["Authorization"] = "Bearer $newToken";
            final newResponse = await dio.fetch(e.requestOptions);
            return handler.resolve(newResponse);
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
