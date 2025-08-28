import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../core/error/exceptions.dart';
import '../features/product/data/models/brand_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

class BrandService {
  final ApiClient apiClient;

  BrandService({required this.apiClient});

  /// Fetch brands from the pl_brands API endpoint
  Future<List<BrandModel>> fetchBrands() async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
      }

      final url = ApiConfig.getPlBrandsUrl(token: token);
      print("BrandService: Making request to: $url");

      final response = await apiClient.get(url);

      if (response.statusCode != 200) {
        throw Exception(
            "Gagal mengambil data brand. Kode error: ${response.statusCode}");
      }

      // Debug: Log response structure
      print("BrandService: API Response keys: ${response.data.keys.toList()}");
      print("BrandService: API Response status: ${response.data['status']}");

      // Check API response status
      if (response.data['status'] != 'success') {
        throw Exception(
            "API mengembalikan status error: ${response.data['status']}");
      }

      // Check for both "result" and "data" keys in response
      final rawData = response.data["data"] ?? response.data["result"];

      if (rawData is! List) {
        print("BrandService: Raw data type: ${rawData.runtimeType}");
        print("BrandService: Raw data content: $rawData");
        throw Exception("Data brand tidak ditemukan. Silakan coba lagi.");
      }

      final brands = rawData.map((item) {
        try {
          return BrandModel.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          print("BrandService: Error parsing brand item: $e");
          print("BrandService: Item data: $item");
          rethrow;
        }
      }).toList();

      // Filter only active brands
      final activeBrands =
          brands.where((brand) => brand.isActive ?? true).toList();

      print("BrandService: Successfully fetched ${activeBrands.length} brands");
      return activeBrands;
    } on DioException catch (e) {
      print("BrandService: DioException occurred: ${e.type} - ${e.message}");
      print("BrandService: DioException response: ${e.response?.data}");

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
            "Timeout saat mengambil data brand. Silakan coba lagi.");
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
            "Tidak dapat terhubung ke server. Periksa koneksi internet Anda.");
      } else {
        throw ServerException("Error jaringan: ${e.message}");
      }
    } catch (e) {
      print("BrandService: Unexpected error: $e");
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException("Error tidak terduga: $e");
    }
  }

  /// Get brand by ID
  Future<BrandModel?> getBrandById(int id) async {
    try {
      final brands = await fetchBrands();
      return brands.firstWhere((brand) => brand.id == id);
    } catch (e) {
      print("BrandService: Error getting brand by ID $id: $e");
      return null;
    }
  }

  /// Get brand by name
  Future<BrandModel?> getBrandByName(String name) async {
    try {
      final brands = await fetchBrands();
      return brands.firstWhere(
        (brand) => brand.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      print("BrandService: Error getting brand by name '$name': $e");
      return null;
    }
  }
}
