import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/area_model.dart';

/// Remote data source untuk area API calls
abstract class AreaRemoteDataSource {
  Future<List<AreaModel>> fetchAreas();
}

class AreaRemoteDataSourceImpl implements AreaRemoteDataSource {
  final ApiClient apiClient;

  AreaRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AreaModel>> fetchAreas() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw ServerException(
          "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.",
        );
      }

      final url = ApiConfig.getPlAreasUrl(token: token);

      final response = await apiClient.get(url);

      if (response.statusCode != 200) {
        throw ServerException(
          "Gagal mengambil data area. Kode error: ${response.statusCode}",
        );
      }

      // Check API response status
      if (response.data['status'] != 'success') {
        throw ServerException(
          "API mengembalikan status error: ${response.data['status']}",
        );
      }

      // Check for both "result" and "data" keys in response
      final rawData = response.data["data"] ?? response.data["result"];

      if (rawData is! List) {
        throw ServerException("Data area tidak ditemukan. Silakan coba lagi.");
      }

      final areas = rawData.map((item) {
        try {
          return AreaModel.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          rethrow;
        }
      }).toList();

      // Filter only active areas
      final activeAreas = areas.where((area) => area.isActive ?? true).toList();

      return activeAreas;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          "Timeout saat mengambil data area. Silakan coba lagi.",
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.",
        );
      } else {
        throw ServerException("Error jaringan: ${e.message}");
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException("Error tidak terduga: $e");
    }
  }
}

