import '../../config/api_config.dart';
import '../../config/app_constant.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../features/product/data/models/product_model.dart';

class ProductOptionsService {
  final ApiClient apiClient;

  ProductOptionsService({required this.apiClient});

  /// Get available divan options based on filter
  Future<List<String>> getDivanOptions({
    required String area,
    required String channel,
    required String brand,
    required String kasur,
  }) async {
    try {
      final products = await _fetchProductsWithFilter(
        area: area,
        channel: channel,
        brand: brand,
      );

      // Filter products by kasur
      final filteredProducts = kasur == AppStrings.noKasur
          ? products
              .where((p) => p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
              .toList()
          : products.where((p) => p.kasur == kasur).toList();

      // Extract unique divan options
      final divanOptions = filteredProducts
          .map((p) => p.divan)
          .where((divan) => divan.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Add "Tidak ada divan" option if available
      if (filteredProducts
          .any((p) => p.divan.isEmpty || p.divan == AppStrings.noDivan)) {
        if (!divanOptions.contains(AppStrings.noDivan)) {
          divanOptions.add(AppStrings.noDivan);
        }
      }

      return divanOptions;
    } catch (e) {
      print('Error getting divan options: $e');
      return [];
    }
  }

  /// Get available headboard options based on filter
  Future<List<String>> getHeadboardOptions({
    required String area,
    required String channel,
    required String brand,
    required String kasur,
  }) async {
    try {
      final products = await _fetchProductsWithFilter(
        area: area,
        channel: channel,
        brand: brand,
      );

      // Filter products by kasur only (like in product page)
      var filteredProducts = kasur == AppStrings.noKasur
          ? products
              .where((p) => p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
              .toList()
          : products.where((p) => p.kasur == kasur).toList();

      // Extract unique headboard options from all products with this kasur
      final headboardOptions = filteredProducts
          .map((p) => p.headboard)
          .where((headboard) => headboard.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Add "Tidak ada headboard" option if available
      if (filteredProducts.any((p) =>
          p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)) {
        if (!headboardOptions.contains(AppStrings.noHeadboard)) {
          headboardOptions.add(AppStrings.noHeadboard);
        }
      }

      return headboardOptions;
    } catch (e) {
      print('Error getting headboard options: $e');
      return [];
    }
  }

  /// Get available sorong options based on filter
  Future<List<String>> getSorongOptions({
    required String area,
    required String channel,
    required String brand,
    required String kasur,
    required String divan,
    required String headboard,
  }) async {
    try {
      final products = await _fetchProductsWithFilter(
        area: area,
        channel: channel,
        brand: brand,
      );

      // Filter products by kasur and divan only (like in product page)
      var filteredProducts = kasur == AppStrings.noKasur
          ? products
              .where((p) => p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
              .toList()
          : products.where((p) => p.kasur == kasur).toList();

      filteredProducts = divan == AppStrings.noDivan
          ? filteredProducts
              .where((p) => p.divan.isEmpty || p.divan == AppStrings.noDivan)
              .toList()
          : filteredProducts.where((p) => p.divan == divan).toList();

      // Extract unique sorong options from all products with this kasur and divan
      final sorongOptions = filteredProducts
          .map((p) => p.sorong)
          .where((sorong) => sorong.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Add "Tidak ada sorong" option if available
      if (filteredProducts
          .any((p) => p.sorong.isEmpty || p.sorong == AppStrings.noSorong)) {
        if (!sorongOptions.contains(AppStrings.noSorong)) {
          sorongOptions.add(AppStrings.noSorong);
        }
      }

      return sorongOptions;
    } catch (e) {
      print('Error getting sorong options: $e');
      return [];
    }
  }

  /// Fetch products with filter from API
  Future<List<ProductModel>> _fetchProductsWithFilter({
    required String area,
    required String channel,
    required String brand,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        String? token = await AuthService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception(
              "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
        }

        int? userId = await AuthService.getCurrentUserId();
        if (userId == null) {
          throw Exception(
              "User ID tidak tersedia. Silakan login ulang untuk melanjutkan.");
        }

        final url = ApiConfig.getFilteredProductsUrl(
          token: token,
          area: area,
          channel: channel,
          brand: brand,
        );

        final response = await apiClient.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              "Gagal mengambil data produk. Kode error: ${response.statusCode}");
        }

        if (response.data['status'] != 'success') {
          throw Exception(
              "API mengembalikan status error: ${response.data['status']}");
        }

        final data = response.data['result'] ?? response.data['data'];
        if (data == null) {
          throw Exception("Data produk tidak ditemukan dalam response");
        }

        final List<dynamic> productsJson = data is List ? data : [];
        return productsJson.map((json) => ProductModel.fromJson(json)).toList();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception(
              "Gagal mengambil data produk setelah $maxRetries percobaan: $e");
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    throw Exception("Gagal mengambil data produk");
  }
}
