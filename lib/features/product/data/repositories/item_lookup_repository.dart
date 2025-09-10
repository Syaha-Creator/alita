import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/item_lookup_model.dart';
import '../../domain/entities/item_lookup_entity.dart';
import '../../domain/repositories/item_lookup_repository.dart';

class ItemLookupRepositoryImpl implements ItemLookupRepository {
  final ApiClient apiClient;

  ItemLookupRepositoryImpl({required this.apiClient});

  @override
  Future<List<ItemLookupEntity>> fetchItemLookups() async {
    const int maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        String? token = await AuthService.getToken();
        if (token == null || token.isEmpty) {
          throw Exception(
              "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.");
        }

        final url = ApiConfig.getPlLookupItemNumsUrl(token: token);

        print("Making API request to: $url");

        final response = await apiClient.get(url);

        if (response.statusCode != 200) {
          throw Exception(
              "Gagal mengambil data item lookup. Kode error: ${response.statusCode}");
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
          throw Exception(
              "Data item lookup tidak ditemukan. Silakan coba lagi.");
        }

        final itemLookups = rawData.map((item) {
          try {
            return ItemLookupModel.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print("Error parsing item lookup: $e");
            print("Item data: $item");
            rethrow;
          }
        }).toList();

        // Convert models to entities
        return itemLookups
            .map((model) => ItemLookupEntity(
                  id: model.id,
                  brand: model.brand,
                  tipe: model.tipe,
                  tebal: model.tebal,
                  ukuran: model.ukuran,
                  itemNum: model.itemNum,
                  itemDesc: model.itemDesc,
                  jenisKain: model.jenisKain,
                  warnaKain: model.warnaKain,
                  berat: model.berat,
                  kubikasi: model.kubikasi,
                  createdAt: model.createdAt,
                  updatedAt: model.updatedAt,
                ))
            .toList();
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
            throw NetworkException(
                "Gagal terhubung ke server. Periksa koneksi Anda.");
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

          throw ServerException(
              "Gagal mengambil data item lookup dari server: ${e.message}");
        } else if (e.response?.statusCode == 400 ||
            e.response?.statusCode == 404) {
          throw ServerException(
              "Gagal mengambil data item lookup dari server: ${e.message}");
        } else {
          throw ServerException(
              "Gagal mengambil data item lookup dari server: ${e.message}");
        }
      } catch (e) {
        throw ServerException(
            "Terjadi kesalahan yang tidak diketahui saat memproses data: $e");
      }
    }

    throw ServerException(
        "Gagal mengambil data setelah $maxRetries percobaan.");
  }
}
