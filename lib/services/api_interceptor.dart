import 'package:dio/dio.dart';

import 'auth_service.dart';

class ApiInterceptor extends InterceptorsWrapper {
  final Dio dio;

  ApiInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
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

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      String? newToken = await AuthService.refreshToken();

      if (newToken != null) {
        // For ngrok endpoints, we need to update the URL with new token
        if (err.requestOptions.path.contains('ngrok-free.app')) {
          // Extract the current URL and replace the token
          String currentUrl = err.requestOptions.path;
          String? oldToken = await AuthService.getToken();
          if (oldToken != null) {
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
        return handler.next(err);
      }
    } catch (e) {
      return handler.next(err);
    }
  }
}
