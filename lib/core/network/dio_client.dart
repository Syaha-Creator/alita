import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioClientProvider = Provider((ref) => DioClient());

class DioClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.example.com',
    headers: {'Content-Type': 'application/json'},
  ));

  DioClient() {
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  Dio get instance => _dio;
}