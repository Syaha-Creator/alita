import '../../../../services/area_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../models/area_model.dart';

class AreaRepository {
  final AreaService areaService;

  AreaRepository({required this.areaService});

  /// Fetch areas from API (always fresh data)
  Future<List<AreaModel>> fetchAreas() async {
    try {
      final areas = await areaService.fetchAreas();
      return areas;
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

  /// Get all area names from API (most direct approach)
  Future<List<String>> fetchAllAreaNames() async {
    try {
      final areas = await fetchAreas();
      final areaNames = areas.map((area) => area.name).toList();
      return areaNames;
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

  /// Check if areas are available from API
  Future<bool> isApiAvailable() async {
    try {
      await areaService.fetchAreas();
      return true;
    } catch (e) {
      return false;
    }
  }
}
