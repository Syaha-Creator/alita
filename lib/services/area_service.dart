import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/error/exceptions.dart';
import '../features/product/data/models/area_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class AreaService {
  final ApiClient apiClient;

  AreaService({required this.apiClient});

  /// Fetch areas from the pl_areas API endpoint
  Future<List<AreaModel>> fetchAreas() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
      }

      final url = ApiConfig.getPlAreasUrl(token: token);

      final response = await apiClient.get(url);

      if (response.statusCode != 200) {
        throw Exception(
            "Gagal mengambil data area. Kode error: ${response.statusCode}");
      }

      // Debug: Log response structure

      // Check API response status
      if (response.data['status'] != 'success') {
        throw Exception(
            "API mengembalikan status error: ${response.data['status']}");
      }

      // Check for both "result" and "data" keys in response
      final rawData = response.data["data"] ?? response.data["result"];

      if (rawData is! List) {
        throw Exception("Data area tidak ditemukan. Silakan coba lagi.");
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
            "Timeout saat mengambil data area. Silakan coba lagi.");
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
            "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.");
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

  /// Get area by ID
  Future<AreaModel?> getAreaById(int id) async {
    try {
      final areas = await fetchAreas();
      return areas.firstWhere((area) => area.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get area by name
  Future<AreaModel?> getAreaByName(String name) async {
    try {
      final areas = await fetchAreas();
      return areas.firstWhere(
        (area) => area.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
