import '../../../../core/widgets/custom_toast.dart';
import '../datasources/brand_remote_data_source.dart';
import '../models/brand_model.dart';

class BrandRepository {
  final BrandRemoteDataSource remoteDataSource;

  BrandRepository({required this.remoteDataSource});

  /// Fetch brands from API (always fresh data)
  Future<List<BrandModel>> fetchBrands() async {
    try {
      final brands = await remoteDataSource.fetchBrands();
      return brands;
    } catch (e) {
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
      await remoteDataSource.fetchBrands();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all brands from API as strings (includes all brands, not just enum-convertible ones)
  Future<List<String>> fetchAllBrandNames({int? channelId}) async {
    try {
      final brands = await fetchBrands();
      final filtered = channelId == null
          ? brands
          : brands.where((b) => b.plChannelId == channelId).toList();
      final brandNames = filtered.map((brand) => brand.name).toList();
      return brandNames;
    } catch (e) {
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
  Future<List<BrandModel>> fetchAllBrands({int? channelId}) async {
    try {
      final brands = await fetchBrands();
      if (channelId == null) return brands;
      return brands.where((b) => b.plChannelId == channelId).toList();
    } catch (e) {
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
