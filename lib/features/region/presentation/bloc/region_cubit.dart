import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/province_model.dart';
import '../../data/models/city_model.dart';
import '../../data/models/district_model.dart';
import '../../data/repositories/region_repository.dart';
import 'region_state.dart';

/// Cubit untuk mengelola state pemilihan wilayah (cascading dropdown)
class RegionCubit extends Cubit<RegionState> {
  final RegionRepository _repository;

  RegionCubit({RegionRepository? repository})
      : _repository = repository ?? RegionRepository(),
        super(RegionState.initial());

  /// Load daftar provinsi
  Future<void> loadProvinces() async {
    if (state.provinces.isNotEmpty) {
      // Already loaded, skip
      return;
    }

    emit(state.copyWith(isLoadingProvinces: true, clearError: true));

    try {
      final provinces = await _repository.getProvinces();
      emit(state.copyWith(
        provinces: provinces,
        isLoadingProvinces: false,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[RegionCubit] Error loading provinces: $e');
      }
      emit(state.copyWith(
        isLoadingProvinces: false,
        errorMessage: 'Gagal memuat daftar provinsi',
      ));
    }
  }

  /// Pilih provinsi dan load kota/kabupaten
  Future<void> selectProvince(ProvinceModel? province) async {
    if (province == null) {
      // Clear selection
      emit(state.copyWith(
        clearSelectedProvince: true,
        clearSelectedCity: true,
        clearSelectedDistrict: true,
        cities: [],
        districts: [],
      ));
      return;
    }

    // Update selected province and clear city/district
    emit(state.copyWith(
      selectedProvince: province,
      clearSelectedCity: true,
      clearSelectedDistrict: true,
      cities: [],
      districts: [],
      isLoadingCities: true,
      clearError: true,
    ));

    // Load cities for selected province
    try {
      final cities = await _repository.getCitiesByProvince(province.id);
      emit(state.copyWith(
        cities: cities,
        isLoadingCities: false,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[RegionCubit] Error loading cities: $e');
      }
      emit(state.copyWith(
        isLoadingCities: false,
        errorMessage: 'Gagal memuat daftar kota/kabupaten',
      ));
    }
  }

  /// Pilih kota/kabupaten dan load kecamatan
  Future<void> selectCity(CityModel? city) async {
    if (city == null) {
      // Clear selection
      emit(state.copyWith(
        clearSelectedCity: true,
        clearSelectedDistrict: true,
        districts: [],
      ));
      return;
    }

    // Update selected city and clear district
    emit(state.copyWith(
      selectedCity: city,
      clearSelectedDistrict: true,
      districts: [],
      isLoadingDistricts: true,
      clearError: true,
    ));

    // Load districts for selected city
    try {
      final districts = await _repository.getDistrictsByCity(city.id);
      emit(state.copyWith(
        districts: districts,
        isLoadingDistricts: false,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('[RegionCubit] Error loading districts: $e');
      }
      emit(state.copyWith(
        isLoadingDistricts: false,
        errorMessage: 'Gagal memuat daftar kecamatan',
      ));
    }
  }

  /// Pilih kecamatan
  void selectDistrict(DistrictModel? district) {
    emit(state.copyWith(
      selectedDistrict: district,
      clearSelectedDistrict: district == null,
      clearError: true,
    ));
  }

  /// Reset semua selection
  void resetSelection() {
    emit(state.copyWith(
      clearSelectedProvince: true,
      clearSelectedCity: true,
      clearSelectedDistrict: true,
      cities: [],
      districts: [],
      clearError: true,
    ));
  }

  /// Set region dari data existing (untuk edit/load draft)
  void setRegionFromNames({
    String? provinceName,
    String? cityName,
    String? districtName,
  }) {
    // Find matching province
    ProvinceModel? province;
    if (provinceName != null && provinceName.isNotEmpty) {
      province = state.provinces.firstWhere(
        (p) => p.name.toLowerCase() == provinceName.toLowerCase(),
        orElse: () => ProvinceModel(id: '', name: provinceName),
      );
    }

    // For city and district, we create placeholder models
    // since we don't have the full list loaded yet
    CityModel? city;
    if (cityName != null && cityName.isNotEmpty) {
      city = CityModel(id: '', provinceId: '', name: cityName);
    }

    DistrictModel? district;
    if (districtName != null && districtName.isNotEmpty) {
      district = DistrictModel(id: '', regencyId: '', name: districtName);
    }

    emit(state.copyWith(
      selectedProvince: province,
      selectedCity: city,
      selectedDistrict: district,
    ));
  }
}
