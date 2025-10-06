import '../../../../services/brand_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../models/brand_model.dart';

class BrandRepository {
  final BrandService brandService;

  BrandRepository({required this.brandService});

  /// Fetch brands from API (always fresh data)
  Future<List<BrandModel>> fetchBrands() async {
    try {
      final brands = await brandService.fetchBrands();
      print("BrandRepository: Successfully fetched ${brands.length} brands");
      return brands;
    } catch (e) {
      print("BrandRepository: API failed: $e");
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat data brand. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get brand by ID
  Future<BrandModel?> getBrandById(int id) async {
    try {
      final brands = await fetchBrands();
      return brands.firstWhere((brand) => brand.id == id);
    } catch (e) {
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
      return null;
    }
  }

  /// Check if brands are available from API
  Future<bool> isApiAvailable() async {
    try {
      await brandService.fetchBrands();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all brands from API as strings (includes all brands, not just enum-convertible ones)
  Future<List<String>> fetchAllBrandNames() async {
    try {
      final brands = await fetchBrands();
      final brandNames = brands.map((brand) => brand.name).toList();
      print(
          "BrandRepository: Returning all ${brandNames.length} brand names from API");
      return brandNames;
    } catch (e) {
      print("BrandRepository: API failed for brand names: $e");
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat daftar brand. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get all brands from API as BrandModel list (includes all brands, not just enum-convertible ones)
  Future<List<BrandModel>> fetchAllBrands() async {
    try {
      final brands = await fetchBrands();
      return brands;
    } catch (e) {
      print("BrandRepository: API failed for all brands: $e");
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat data brand. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }
}
