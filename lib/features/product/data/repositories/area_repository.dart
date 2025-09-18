import '../../../../services/area_service.dart';
import '../models/area_model.dart';

class AreaRepository {
  final AreaService areaService;

  // Cache for areas to avoid repeated API calls
  List<AreaModel>? _cachedAreas;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  AreaRepository({required this.areaService});

  /// Fetch areas from API with caching
  Future<List<AreaModel>> fetchAreas() async {
    // Check if cache is still valid
    if (_cachedAreas != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidDuration) {
        print(
            "AreaRepository: Returning cached areas (${_cachedAreas!.length} areas)");
        return _cachedAreas!;
      }
    }

    try {
      final areas = await areaService.fetchAreas();

      // Update cache
      _cachedAreas = areas;
      _lastFetchTime = DateTime.now();

      print(
          "AreaRepository: Successfully fetched and cached ${areas.length} areas");
      return areas;
    } catch (e) {

      // If API fails, return hardcoded areas as fallback
      return _getHardcodedAreas();
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

  /// Clear cache (useful for testing or when data needs to be refreshed)
  void clearCache() {
    _cachedAreas = null;
    _lastFetchTime = null;
  }

  /// Get hardcoded areas as fallback
  List<AreaModel> _getHardcodedAreas() {
    return [
      AreaModel(id: 3, name: "Nasional"),
      AreaModel(id: 4, name: "Jabodetabek"),
    ];
  }

  /// Get all area names from API (most direct approach)
  Future<List<String>> fetchAllAreaNames() async {
    try {
      final areas = await fetchAreas();
      final areaNames = areas.map((area) => area.name).toList();
      print(
          "AreaRepository: Returning all ${areaNames.length} area names from API");
      return areaNames;
    } catch (e) {
      // Fallback to hardcoded area names
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
