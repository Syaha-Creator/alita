import '../../features/product/data/models/area_model.dart';
import '../../features/product/data/repositories/area_repository.dart';
import '../widgets/custom_toast.dart';

/// Utility class for working with areas
class AreaUtils {
  final AreaRepository areaRepository;

  AreaUtils({required this.areaRepository});

  /// Get all available areas from API
  Future<List<AreaModel>> getAllAreas() async {
    try {
      return await areaRepository.fetchAreas();
    } catch (e) {
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat data area. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get area names as strings
  Future<List<String>> getAreaNames() async {
    try {
      return await areaRepository.fetchAllAreaNames();
    } catch (e) {
      // Show error toast to user
      CustomToast.showToast(
        "Gagal memuat daftar area. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
      // Return empty list if API fails - no hardcoded fallback
      return [];
    }
  }

  /// Get area by name
  Future<AreaModel?> getAreaByName(String name) async {
    try {
      return await areaRepository.getAreaByName(name);
    } catch (e) {
      return null;
    }
  }

  /// Get area by ID
  Future<AreaModel?> getAreaById(int id) async {
    try {
      return await areaRepository.getAreaById(id);
    } catch (e) {
      return null;
    }
  }

  /// Check if API is available for areas
  Future<bool> isApiAvailable() async {
    try {
      return await areaRepository.isApiAvailable();
    } catch (e) {
      return false;
    }
  }

  /// Get display name for area (with fallback)
  String getDisplayName(dynamic area) {
    if (area is AreaModel) {
      return area.name;
    } else if (area is String) {
      return area;
    }
    return 'Unknown Area';
  }
}
