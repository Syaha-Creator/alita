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

      // ✅ Ambil token dari AuthService
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception("Token tidak tersedia. Harap login ulang.");
      }

      // 🔹 Panggil API dengan token
      final response = await apiClient.get(
        ApiConfig.rawdataPriceLists,
        params: {
          "access_token": token,
          "client_id": ApiConfig.clientId,
          "client_secret": ApiConfig.clientSecret,
        },
      );

      print("✅ API Response: ${response.data}");

      // 🔹 Pastikan `response.data` adalah Map<String, dynamic>
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey("result")) {
        final rawData = response.data["result"];

        // 🔹 Pastikan "result" berupa List sebelum parsing
        if (rawData is List) {
          return rawData
              .map(
                  (item) => ProductModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception("Format JSON tidak sesuai: result bukan List.");
        }
      } else {
        throw Exception("Format JSON tidak sesuai: Data utama bukan Map.");
      }
    } catch (e) {
      print("❌ Error fetching products: $e");
      throw Exception("Gagal mengambil data produk: ${e.toString()}");
    }
  }
}
