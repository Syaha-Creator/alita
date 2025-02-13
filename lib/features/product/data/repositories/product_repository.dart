import '../../../../config/api_config.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({required this.apiClient});

  Future<List<ProductModel>> fetchProducts() async {
    try {
      print("📡 Fetching products from API...");

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
    } catch (e) {
      print("❌ Error fetching products: $e");
      throw Exception("Gagal mengambil data produk: ${e.toString()}");
    }
  }
}
