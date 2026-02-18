import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/province_model.dart';
import '../models/city_model.dart';
import '../models/district_model.dart';

/// Remote data source untuk mengambil data wilayah Indonesia
/// Menggunakan API dari emsifa (gratis, tanpa auth)
class RegionRemoteDataSource {
  final Dio _dio;
  
  /// Base URL API Wilayah Indonesia
  static const String baseUrl = 'https://www.emsifa.com/api-wilayah-indonesia/api/';

  RegionRemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// Mendapatkan daftar semua provinsi
  Future<List<ProvinceModel>> getProvinces() async {
    try {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Fetching provinces...');
      }

      final response = await _dio.get('provinces.json');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final provinces = data.map((json) => ProvinceModel.fromJson(json)).toList();
        
        // Sort by name
        provinces.sort((a, b) => a.name.compareTo(b.name));
        
        if (kDebugMode) {
          print('[RegionRemoteDataSource] Loaded ${provinces.length} provinces');
        }
        
        return provinces;
      }

      throw Exception('Failed to load provinces: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error fetching provinces: ${e.message}');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error: $e');
      }
      rethrow;
    }
  }

  /// Mendapatkan daftar kota/kabupaten berdasarkan ID provinsi
  Future<List<CityModel>> getCitiesByProvince(String provinceId) async {
    try {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Fetching cities for province: $provinceId');
      }

      final response = await _dio.get('regencies/$provinceId.json');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final cities = data.map((json) => CityModel.fromJson(json)).toList();
        
        // Sort by name
        cities.sort((a, b) => a.name.compareTo(b.name));
        
        if (kDebugMode) {
          print('[RegionRemoteDataSource] Loaded ${cities.length} cities');
        }
        
        return cities;
      }

      throw Exception('Failed to load cities: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error fetching cities: ${e.message}');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error: $e');
      }
      rethrow;
    }
  }

  /// Mendapatkan daftar kecamatan berdasarkan ID kota/kabupaten
  Future<List<DistrictModel>> getDistrictsByCity(String cityId) async {
    try {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Fetching districts for city: $cityId');
      }

      final response = await _dio.get('districts/$cityId.json');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final districts = data.map((json) => DistrictModel.fromJson(json)).toList();
        
        // Sort by name
        districts.sort((a, b) => a.name.compareTo(b.name));
        
        if (kDebugMode) {
          print('[RegionRemoteDataSource] Loaded ${districts.length} districts');
        }
        
        return districts;
      }

      throw Exception('Failed to load districts: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error fetching districts: ${e.message}');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        print('[RegionRemoteDataSource] Error: $e');
      }
      rethrow;
    }
  }
}
