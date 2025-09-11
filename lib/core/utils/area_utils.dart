import '../../features/product/data/models/area_model.dart';
import '../../features/product/data/repositories/area_repository.dart';

/// Utility class for working with areas
class AreaUtils {
  final AreaRepository areaRepository;

  AreaUtils({required this.areaRepository});

  /// Get all available areas from API or fallback to hardcoded values
  Future<List<AreaModel>> getAllAreas() async {
    try {
      return await areaRepository.fetchAreas();
    } catch (e) {
      print('AreaUtils: Error fetching areas: $e');
      // Return hardcoded areas as fallback
      return _getHardcodedAreas();
    }
  }

  /// Get area names as strings
  Future<List<String>> getAreaNames() async {
    try {
      return await areaRepository.fetchAllAreaNames();
    } catch (e) {
      print('AreaUtils: Error fetching area names: $e');
      return [
        "Nasional",
        "Jabodetabek",
        "Bandung",
        "Surabaya",
        "Semarang",
        "Yogyakarta",
        "Solo",
        "Malang",
        "Denpasar",
        "Medan",
        "Palembang"
      ];
    }
  }

  /// Get area by name
  Future<AreaModel?> getAreaByName(String name) async {
    try {
      return await areaRepository.getAreaByName(name);
    } catch (e) {
      print('AreaUtils: Error getting area by name: $e');
      return null;
    }
  }

  /// Get area by ID
  Future<AreaModel?> getAreaById(int id) async {
    try {
      return await areaRepository.getAreaById(id);
    } catch (e) {
      print('AreaUtils: Error getting area by ID: $e');
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

  /// Clear area cache
  void clearCache() {
    areaRepository.clearCache();
  }

  /// Get hardcoded areas as fallback
  List<AreaModel> _getHardcodedAreas() {
    return [
      AreaModel(id: 0, name: "Nasional"),
      AreaModel(id: 1, name: "Jabodetabek"),
      AreaModel(id: 2, name: "Bandung"),
      AreaModel(id: 3, name: "Surabaya"),
      AreaModel(id: 4, name: "Semarang"),
      AreaModel(id: 5, name: "Yogyakarta"),
      AreaModel(id: 6, name: "Solo"),
      AreaModel(id: 7, name: "Malang"),
      AreaModel(id: 8, name: "Denpasar"),
      AreaModel(id: 9, name: "Medan"),
      AreaModel(id: 10, name: "Palembang"),
    ];
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
