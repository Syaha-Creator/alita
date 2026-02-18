import 'package:equatable/equatable.dart';

import '../../data/models/province_model.dart';
import '../../data/models/city_model.dart';
import '../../data/models/district_model.dart';

/// State untuk RegionCubit
class RegionState extends Equatable {
  /// Daftar provinsi
  final List<ProvinceModel> provinces;
  
  /// Daftar kota/kabupaten (berdasarkan provinsi terpilih)
  final List<CityModel> cities;
  
  /// Daftar kecamatan (berdasarkan kota terpilih)
  final List<DistrictModel> districts;
  
  /// Provinsi yang dipilih
  final ProvinceModel? selectedProvince;
  
  /// Kota yang dipilih
  final CityModel? selectedCity;
  
  /// Kecamatan yang dipilih
  final DistrictModel? selectedDistrict;
  
  /// Loading state untuk provinsi
  final bool isLoadingProvinces;
  
  /// Loading state untuk kota
  final bool isLoadingCities;
  
  /// Loading state untuk kecamatan
  final bool isLoadingDistricts;
  
  /// Error message jika ada
  final String? errorMessage;

  const RegionState({
    this.provinces = const [],
    this.cities = const [],
    this.districts = const [],
    this.selectedProvince,
    this.selectedCity,
    this.selectedDistrict,
    this.isLoadingProvinces = false,
    this.isLoadingCities = false,
    this.isLoadingDistricts = false,
    this.errorMessage,
  });

  /// Initial state
  factory RegionState.initial() {
    return const RegionState();
  }

  /// Copy with method untuk immutable state updates
  RegionState copyWith({
    List<ProvinceModel>? provinces,
    List<CityModel>? cities,
    List<DistrictModel>? districts,
    ProvinceModel? selectedProvince,
    CityModel? selectedCity,
    DistrictModel? selectedDistrict,
    bool? isLoadingProvinces,
    bool? isLoadingCities,
    bool? isLoadingDistricts,
    String? errorMessage,
    bool clearSelectedProvince = false,
    bool clearSelectedCity = false,
    bool clearSelectedDistrict = false,
    bool clearError = false,
  }) {
    return RegionState(
      provinces: provinces ?? this.provinces,
      cities: cities ?? this.cities,
      districts: districts ?? this.districts,
      selectedProvince: clearSelectedProvince ? null : (selectedProvince ?? this.selectedProvince),
      selectedCity: clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      selectedDistrict: clearSelectedDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
      isLoadingProvinces: isLoadingProvinces ?? this.isLoadingProvinces,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isLoadingDistricts: isLoadingDistricts ?? this.isLoadingDistricts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Check apakah region selection sudah lengkap
  bool get isComplete =>
      selectedProvince != null &&
      selectedCity != null &&
      selectedDistrict != null;

  /// Get formatted region string untuk display
  String get formattedRegion {
    final parts = <String>[];
    if (selectedDistrict != null) parts.add('Kec. ${selectedDistrict!.name}');
    if (selectedCity != null) parts.add(selectedCity!.name);
    if (selectedProvince != null) parts.add(selectedProvince!.name);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        provinces,
        cities,
        districts,
        selectedProvince,
        selectedCity,
        selectedDistrict,
        isLoadingProvinces,
        isLoadingCities,
        isLoadingDistricts,
        errorMessage,
      ];
}
