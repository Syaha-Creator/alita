import '../../../../services/area_service.dart';
import '../../../../services/area_cache.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../models/area_model.dart';

class AreaRepository {
  final AreaService areaService;

  AreaRepository({required this.areaService});

  /// Fetch areas from API with smart caching
  /// - Sukses: simpan ke cache, return data
  /// - Gagal: gunakan cache jika ada, kalau tidak return empty
  Future<List<AreaModel>> fetchAreas() async {
    try {
      final areas = await areaService.fetchAreas();

      // Sukses fetch dari API → simpan ke cache
      if (areas.isNotEmpty) {
        await AreaCache.cacheAreas(areas);
      }

      return areas;
    } catch (e) {
      // API gagal → coba gunakan cache
      final cachedAreas = await AreaCache.getCachedAreas();

      if (cachedAreas != null && cachedAreas.isNotEmpty) {
        // Ada cache, gunakan cache (silent - tidak tampilkan error)
        return cachedAreas;
      }

      // Tidak ada cache, tampilkan error
      CustomToast.showToast(
        "Gagal memuat data area. Periksa koneksi internet Anda.",
        ToastType.error,
        duration: 3,
      );
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

  /// Get all area names from API with smart caching
  Future<List<String>> fetchAllAreaNames() async {
    try {
      final areas = await fetchAreas(); // Already uses cache internally
      return areas.map((area) => area.name).toList();
    } catch (e) {
      // fetchAreas already handles cache and error toast
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
