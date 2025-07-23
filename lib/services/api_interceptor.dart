import 'package:dio/dio.dart';

import 'auth_service.dart';

/// Interceptor Dio untuk menambah header, handle auth, dan refresh token otomatis.
class ApiInterceptor extends InterceptorsWrapper {
  final Dio dio;

  /// Inisialisasi interceptor dengan dependency Dio.
  ApiInterceptor(this.dio);

  /// Menambah header dan auth token pada setiap request.
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Add ngrok-specific headers for all requests
    options.headers['ngrok-skip-browser-warning'] = 'true';
    options.headers['User-Agent'] = 'AlitaPricelist/1.0';

    // Only add Authorization header for non-ngrok and non-filtered_pl endpoints
    if (!options.path.contains('ngrok-free.app') &&
        !options.path.contains('/api/filtered_pl')) {
      String? token = await AuthService.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    options.headers['Accept'] = 'application/json';

    return handler.next(options);
  }

  /// Handle error 401 (unauthorized) dan refresh token otomatis.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only handle 401 errors for token refresh
    if (err.response?.statusCode == 401) {
      try {
        String? newToken = await AuthService.refreshToken();

        if (newToken != null) {
          // For ngrok endpoints, we need to update the URL with new token
          if (err.requestOptions.path.contains('ngrok-free.app')) {
            // Extract the current URL and replace the token
            String currentUrl = err.requestOptions.path;
            String? oldToken = await AuthService.getToken();
            if (oldToken != null) {
              // Replace the old token with new token in the URL
              currentUrl = currentUrl.replaceFirst(
                  'access_token=$oldToken', 'access_token=$newToken');
              err.requestOptions.path = currentUrl;
            }
          } else if (!err.requestOptions.path.contains('/api/filtered_pl')) {
            // For non-ngrok and non-filtered_pl endpoints, update Authorization header
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          }

          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } else {
          // Token refresh failed, user needs to login again
          return handler.next(err);
        }
      } catch (e) {
        // Token refresh failed, user needs to login again
        return handler.next(err);
      }
    } else {
      // For non-401 errors, just pass through
      return handler.next(err);
    }
  }
}
