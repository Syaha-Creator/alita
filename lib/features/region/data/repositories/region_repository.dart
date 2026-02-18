import '../datasources/region_remote_data_source.dart';
import '../models/province_model.dart';
import '../models/city_model.dart';
import '../models/district_model.dart';

/// Repository untuk mengelola data wilayah Indonesia
/// Bertindak sebagai abstraksi antara data source dan presentation layer
class RegionRepository {
  final RegionRemoteDataSource _remoteDataSource;
  
  /// Cache untuk data provinsi (karena jarang berubah)
  List<ProvinceModel>? _provincesCache;

  RegionRepository({RegionRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? RegionRemoteDataSource();

  /// Mendapatkan daftar provinsi dengan caching
  Future<List<ProvinceModel>> getProvinces({bool forceRefresh = false}) async {
    // Return cache jika tersedia dan tidak force refresh
    if (_provincesCache != null && !forceRefresh) {
      return _provincesCache!;
    }

    // Fetch dari remote dan cache
    _provincesCache = await _remoteDataSource.getProvinces();
    return _provincesCache!;
  }

  /// Mendapatkan daftar kota/kabupaten berdasarkan provinsi
  Future<List<CityModel>> getCitiesByProvince(String provinceId) async {
    return _remoteDataSource.getCitiesByProvince(provinceId);
  }

  /// Mendapatkan daftar kecamatan berdasarkan kota/kabupaten
  Future<List<DistrictModel>> getDistrictsByCity(String cityId) async {
    return _remoteDataSource.getDistrictsByCity(cityId);
  }

  /// Clear cache provinsi
  void clearCache() {
    _provincesCache = null;
  }
}
