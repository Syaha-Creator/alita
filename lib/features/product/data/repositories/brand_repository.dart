import '../../../../services/brand_service.dart';
import '../models/brand_model.dart';

class BrandRepository {
  final BrandService brandService;

  // Cache for brands to avoid repeated API calls
  List<BrandModel>? _cachedBrands;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  BrandRepository({required this.brandService});

  /// Fetch brands from API with caching
  Future<List<BrandModel>> fetchBrands() async {
    // Check if cache is still valid
    if (_cachedBrands != null && _lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheValidDuration) {
        print(
            "BrandRepository: Returning cached brands (${_cachedBrands!.length} brands)");
        return _cachedBrands!;
      }
    }

    try {
      print("BrandRepository: Fetching brands from API...");
      final brands = await brandService.fetchBrands();

      // Update cache
      _cachedBrands = brands;
      _lastFetchTime = DateTime.now();

      print(
          "BrandRepository: Successfully fetched and cached ${brands.length} brands");
      return brands;
    } catch (e) {
      print("BrandRepository: Error fetching brands from API: $e");

      // If API fails, return hardcoded brands as fallback
      print("BrandRepository: Falling back to hardcoded brands");
      return _getHardcodedBrands();
    }
  }

  /// Get brand by ID
  Future<BrandModel?> getBrandById(int id) async {
    try {
      final brands = await fetchBrands();
      return brands.firstWhere((brand) => brand.id == id);
    } catch (e) {
      print("BrandRepository: Error getting brand by ID $id: $e");
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
      print("BrandRepository: Error getting brand by name '$name': $e");
      return null;
    }
  }

  /// Clear cache (useful for testing or when data needs to be refreshed)
  void clearCache() {
    _cachedBrands = null;
    _lastFetchTime = null;
    print("BrandRepository: Cache cleared");
  }

  /// Get hardcoded brands as fallback
  List<BrandModel> _getHardcodedBrands() {
    return [
      BrandModel(id: 1, name: "Superfit"),
      BrandModel(id: 2, name: "Therapedic"),
      BrandModel(id: 3, name: "Sleep Spa"),
      BrandModel(id: 4, name: "Spring Air"),
      BrandModel(id: 5, name: "Comforta"),
      BrandModel(id: 6, name: "iSleep"),
    ];
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
      print("BrandRepository: Error fetching all brand names: $e");
      // Fallback to hardcoded brand names
      return [
        "Superfit",
        "Therapedic",
        "Sleep Spa",
        "Spring Air",
        "Comforta",
        "iSleep"
      ];
    }
  }

  /// Get all brands from API as BrandModel list (includes all brands, not just enum-convertible ones)
  Future<List<BrandModel>> fetchAllBrands() async {
    try {
      final brands = await fetchBrands();
      print("BrandRepository: Returning all ${brands.length} brands from API");
      return brands;
    } catch (e) {
      print("BrandRepository: Error fetching all brands: $e");
      // Fallback to hardcoded brands
      return _getHardcodedBrands();
    }
  }
}
