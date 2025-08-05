import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/error/exceptions.dart';

import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient apiClient;

  ProductRepository({required this.apiClient});

  Future<List<ProductModel>> fetchProductsWithFilter({
    required String area,
    required String channel,
    required String brand,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        String? token = await AuthService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception(
              "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
        }

        int? userId = await AuthService.getCurrentUserId();
        if (userId == null) {
          throw Exception(
              "User ID tidak tersedia. Silakan login ulang untuk melanjutkan.");
        }

        // Use the main API endpoint instead of ngrok
        final url = ApiConfig.getFilteredProductsUrl(
          token: token,
          area: area,
          channel: channel,
          brand: brand,
        );

        print("Making API request to: $url");

        final response = await apiClient.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              "Gagal mengambil data produk. Kode error: ${response.statusCode}");
        }

        // Debug: Log response structure
        print("API Response keys: ${response.data.keys.toList()}");
        print("API Response status: ${response.data['status']}");

        // Check API response status
        if (response.data['status'] != 'success') {
          throw Exception(
              "API mengembalikan status error: ${response.data['status']}");
        }

        // Check for both "result" and "data" keys in response
        final rawData = response.data["data"] ?? response.data["result"];

        if (rawData is! List) {
          print("Raw data type: ${rawData.runtimeType}");
          print("Raw data content: $rawData");
          throw Exception("Data produk tidak ditemukan. Silakan coba lagi.");
        }

        final products = rawData.map((item) {
          try {
            return ProductModel.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print("Error parsing product item: $e");
            print("Item data: $item");
            rethrow;
          }
        }).toList();

        return products;
      } on DioException catch (e) {
        retryCount++;

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          if (retryCount < maxRetries) {
            // Wait before retrying (exponential backoff)
            await Future.delayed(Duration(seconds: retryCount * 2));
            continue;
          } else {
            // Try fallback to old API with client-side filtering
            return await _fetchWithFallback(area, channel, brand);
          }
        } else if (e.type == DioExceptionType.connectionError) {
          throw NetworkException(
              "Gagal terhubung ke server. Periksa koneksi Anda.");
        } else if (e.response?.statusCode == 500) {
          // Check if it's a Phusion Passenger error (server down)
          if (e.response?.data is String &&
              (e.response?.data as String).contains("Phusion Passenger") &&
              (e.response?.data as String)
                  .contains("Web application could not be started")) {
            throw ServerException(
                "Server sedang dalam maintenance. Silakan coba lagi dalam beberapa saat.");
          }

          // Try fallback API for other server errors
          return await _fetchWithFallback(area, channel, brand);
        } else if (e.response?.statusCode == 400 ||
            e.response?.statusCode == 404) {
          // If area "Nasional" is not recognized, try with user's area
          if (area == AreaEnum.nasional.value) {
            final userAreaId = await AuthService.getCurrentUserAreaId();
            if (userAreaId != null) {
              final userAreaEnum = _getAreaEnumFromId(userAreaId);
              if (userAreaEnum != null && userAreaEnum != AreaEnum.nasional) {
                return await fetchProductsWithFilter(
                  area: userAreaEnum.value,
                  channel: channel,
                  brand: brand,
                );
              }
            }
          }
          throw ServerException(
              "Gagal mengambil data produk dari server: ${e.message}");
        } else {
          throw ServerException(
              "Gagal mengambil data produk dari server: ${e.message}");
        }
      } catch (e) {
        throw ServerException(
            "Terjadi kesalahan yang tidak diketahui saat memproses data: $e");
      }
    }

    throw ServerException(
        "Gagal mengambil data setelah $maxRetries percobaan.");
  }

  // Fallback method using old API with client-side filtering
  Future<List<ProductModel>> _fetchWithFallback(
    String area,
    String channel,
    String brand,
  ) async {
    try {
      String? token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Token tidak tersedia. Harap login ulang.");
      }

      int? userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception("User ID tidak tersedia. Harap login ulang.");
      }

      final url = ApiConfig.getFilteredProductsUrl(
        token: token,
        area: area,
        channel: channel,
        brand: brand,
      );

      final response = await apiClient.get(url);

      if (response.statusCode == 401) {
        final newToken = await AuthService.refreshToken();
        if (newToken != null) {
          final newUrl = ApiConfig.getFilteredProductsUrl(
            token: newToken,
            area: area,
            channel: channel,
            brand: brand,
          );
          final newResponse = await apiClient.get(newUrl);

          if (newResponse.statusCode != 200) {
            throw Exception(
                "Gagal mengambil data cadangan setelah memperbarui sesi. Silakan coba lagi.");
          }

          // Check API response status
          if (newResponse.data['status'] != 'success') {
            throw Exception(
                "API mengembalikan status error: ${newResponse.data['status']}");
          }

          if (newResponse.data is! Map<String, dynamic>) {
            throw Exception(
                "Data cadangan tidak sesuai format. Silakan coba lagi.");
          }

          final rawData =
              newResponse.data["data"] ?? newResponse.data["result"];
          if (rawData is! List) {
            throw Exception(
                "Format JSON tidak sesuai: data/result bukan List.");
          }

          final allProducts = rawData.map((item) {
            try {
              return ProductModel.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              print("Error parsing product item in token refresh fallback: $e");
              print("Item data: $item");
              rethrow;
            }
          }).toList();

          // Client-side filtering
          final filteredProducts = allProducts.where((product) {
            return product.area == area &&
                product.channel == channel &&
                product.brand == brand;
          }).toList();

          return filteredProducts;
        } else {
          throw Exception("Token refresh failed. Harap login ulang.");
        }
      }

      if (response.statusCode == 500) {
        // Check if it's a Phusion Passenger error (server down)
        if (response.data is String &&
            (response.data as String).contains("Phusion Passenger") &&
            (response.data as String)
                .contains("Web application could not be started")) {
          throw ServerException(
              "Server sedang dalam maintenance. Silakan coba lagi dalam beberapa saat.");
        }

        throw Exception(
            "Gagal mengambil data cadangan. Server error: ${response.statusCode}");
      }

      if (response.statusCode != 200) {
        throw Exception(
            "Gagal mengambil data cadangan. Kode error: ${response.statusCode}");
      }

      // Check API response status
      if (response.data['status'] != 'success') {
        throw Exception(
            "API mengembalikan status error: ${response.data['status']}");
      }

      if (response.data is! Map<String, dynamic>) {
        throw Exception("Format JSON tidak sesuai: Data utama bukan Map.");
      }

      final rawData = response.data["data"] ?? response.data["result"];
      if (rawData is! List) {
        throw Exception("Format JSON tidak sesuai: data/result bukan List.");
      }

      final allProducts = rawData.map((item) {
        try {
          return ProductModel.fromJson(item as Map<String, dynamic>);
        } catch (e) {
          print("Error parsing product item in fallback: $e");
          print("Item data: $item");
          rethrow;
        }
      }).toList();

      // Client-side filtering
      final filteredProducts = allProducts.where((product) {
        return product.area == area &&
            product.channel == channel &&
            product.brand == brand;
      }).toList();

      return filteredProducts;
    } catch (e) {
      throw ServerException("Semua API gagal. Silakan coba lagi nanti.");
    }
  }

  // Helper method to map area_id to area enum
  AreaEnum? _getAreaEnumFromId(int areaId) {
    try {
      return AreaEnum.values.firstWhere(
        (area) => AreaEnum.getId(area) == areaId,
      );
    } catch (e) {
      return null;
    }
  }
}
