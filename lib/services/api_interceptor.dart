import 'package:dio/dio.dart';

import '../core/utils/logger.dart';
import 'auth_service.dart';

class ApiInterceptor extends InterceptorsWrapper {
  final Dio dio;

  ApiInterceptor(this.dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    String? token = await AuthService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    logger.i(
        'REQUEST[${options.method}] => PATH: ${options.path} | DATA: ${options.data}');
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    logger.e(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path} | MESSAGE: ${err.message}');

    if (err.response?.statusCode == 401) {
      logger.e('INTERCEPTOR: Token expired or invalid. Refreshing token...');
      try {
        String? newToken = await AuthService.refreshToken();

        if (newToken != null) {
          logger.e(
              'INTERCEPTOR: Token refreshed successfully. Retrying original request...');

          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } else {
          return handler.next(err);
        }
      } catch (e) {
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
