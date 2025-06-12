import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({required this.apiClient});

  Future<List<ProductModel>> fetchProducts() async {
    try {
      logger.i("📡 Fetching products from API...");

      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token tidak tersedia. Harap login ulang.");
      }

      final response = await apiClient.get(ApiConfig.rawdataPriceLists);

      if (response.statusCode != 200) {
        throw Exception("API Error: ${response.statusCode}");
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception("Format JSON tidak sesuai: Data utama bukan Map.");
      }

      final rawData = response.data["result"];
      if (rawData is! List) {
        throw Exception("Format JSON tidak sesuai: result bukan List.");
      }

      return rawData
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException(
            "Gagal terhubung ke server. Periksa koneksi Anda.");
      } else {
        throw ServerException("Gagal mengambil data produk dari server.");
      }
    } catch (e) {
      logger.e("❌ Unexpected error in ProductRepository: $e");
      throw ServerException(
          "Terjadi kesalahan yang tidak diketahui saat memproses data.");
    }
  }
}
