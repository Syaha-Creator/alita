import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/error_logger.dart';
import '../../../../services/api_client.dart';
import '../../../../services/auth_service.dart';
import '../models/item_lookup_model.dart';

/// Remote data source untuk item lookup API calls
abstract class ItemLookupRemoteDataSource {
  Future<List<ItemLookupModel>> fetchItemLookups();

  /// Fetch available item numbers (and fabric choices) for the given variant
  /// Expected query supports fields like: brand, kasur, divan, headboard, ukuran, sorong
  Future<List<ItemLookupModel>> fetchLookupItems({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  });
}

class ItemLookupRemoteDataSourceImpl implements ItemLookupRemoteDataSource {
  final ApiClient apiClient;
  static const int maxRetries = 3;

  ItemLookupRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ItemLookupModel>> fetchItemLookups() async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        String? token = await AuthService.getToken();
        if (token == null || token.isEmpty) {
          throw ServerException(
            "Sesi Anda telah berakhir. Silakan login ulang untuk melanjutkan.",
          );
        }

        final url = ApiConfig.getPlLookupItemNumsUrl(token: token);

        final response = await apiClient.get(url);

        if (response.statusCode != 200) {
          throw ServerException(
            "Gagal mengambil data item lookup. Kode error: ${response.statusCode}",
          );
        }

        // Check API response status
        if (response.data['status'] != 'success') {
          throw ServerException(
            "API mengembalikan status error: ${response.data['status']}",
          );
        }

        // Check for both "result" and "data" keys in response
        final rawData = response.data["data"] ?? response.data["result"];

        if (rawData is! List) {
          if (kDebugMode) {
            print("Raw data type: ${rawData.runtimeType}");
            print("Raw data content: $rawData");
          }
          throw ServerException(
            "Data item lookup tidak ditemukan. Silakan coba lagi.",
          );
        }

        final itemLookups = rawData.map((item) {
          try {
            return ItemLookupModel.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing item lookup: $e");
              print("Item data: $item");
            }
            rethrow;
          }
        }).toList();

        return itemLookups;
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
              "Gagal terhubung ke server. Periksa koneksi Anda.",
            );
          }
        } else if (e.type == DioExceptionType.connectionError) {
          throw NetworkException(
            "Gagal terhubung ke server. Periksa koneksi Anda.",
          );
        } else if (e.response?.statusCode == 500) {
          // Check if it's a Phusion Passenger error (server down)
          if (e.response?.data is String &&
              (e.response?.data as String).contains("Phusion Passenger") &&
              (e.response?.data as String)
                  .contains("Web application could not be started")) {
            throw ServerException(
              "Server sedang dalam maintenance. Silakan coba lagi dalam beberapa saat.",
            );
          }

          throw ServerException(
            "Gagal mengambil data item lookup dari server: ${e.message}",
          );
        } else if (e.response?.statusCode == 400 ||
            e.response?.statusCode == 404) {
          throw ServerException(
            "Gagal mengambil data item lookup dari server: ${e.message}",
          );
        } else {
          throw ServerException(
            "Gagal mengambil data item lookup dari server: ${e.message}",
          );
        }
      } catch (e) {
        if (e is ServerException || e is NetworkException) {
          rethrow;
        }
        throw ServerException(
          "Terjadi kesalahan yang tidak diketahui saat memproses data: $e",
        );
      }
    }

    throw ServerException(
      "Gagal mengambil data setelah $maxRetries percobaan.",
    );
  }

  @override
  Future<List<ItemLookupModel>> fetchLookupItems({
    required String brand,
    required String kasur,
    String? divan,
    String? headboard,
    String? sorong,
    required String ukuran,
    String? contextItemType,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] fetchLookupItems IN => brand=$brand, kasur=$kasur, divan=$divan, headboard=$headboard, sorong=$sorong, ukuran=$ukuran, contextItemType=$contextItemType');
      }
      // Build authenticated URL
      String? token = await AuthService.getToken();
      if (token == null) {
        throw ServerException('Auth token not found');
      }
      final url = ApiConfig.getPlLookupItemNumsUrl(token: token);

      // Normalize and avoid sending 'Tanpa/Tidak ada' values
      bool isNone(String? v) {
        if (v == null) return true;
        final s = v.trim().toLowerCase();
        if (s.isEmpty) return true;
        return s == '-' ||
            s == 'n/a' ||
            s.contains('tanpa') ||
            s.contains('tidak ada');
      }

      // Determine source tipe based on context component, falling back to kasur
      String resolveSourceTipe() {
        String? ctx = (contextItemType ?? '').toLowerCase().trim();
        bool isInvalidCtxVal(String? v) => isNone(v);
        if (ctx == 'divan' && !isInvalidCtxVal(divan)) return divan!.trim();
        if (ctx == 'headboard' && !isInvalidCtxVal(headboard)) {
          return headboard!.trim();
        }
        if (ctx == 'sorong' && !isInvalidCtxVal(sorong)) return sorong!.trim();
        return kasur.trim();
      }

      final sourceTipe = resolveSourceTipe();
      // Many backends expect 'tipe'; normalize quotes
      String normTipe = sourceTipe.replaceAll("'", "'").trim();
      // Normalize size: unify separator, remove spaces, strip leading zeros per segment
      String normalizeSize(String value) {
        String v = value
            .replaceAll('\u00D7', 'x') // multiplication sign × -> x
            .replaceAll('X', 'x')
            .replaceAll(RegExp(r'\s*[x]\s*'), 'x')
            .replaceAll(' ', '')
            .trim()
            .toLowerCase();
        final parts = v.split('x').map((p) {
          final s = p.replaceFirst(RegExp(r'^0+'), '');
          return s.isEmpty ? '0' : s;
        }).toList();
        return parts.join('x');
      }

      final normUkuran = normalizeSize(ukuran);
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] normalized => tipe="$normTipe", ukuran="$normUkuran"');
      }
      // Parser helper
      List<ItemLookupModel> parseItems(dynamic data) {
        List<dynamic> list = const [];
        if (data is Map) {
          if (data['data'] is List) {
            list = data['data'] as List;
          } else if (data['result'] is List) {
            list = data['result'] as List;
          }
        } else if (data is List) {
          list = data;
        }
        return list
            .map((e) => ItemLookupModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      Response response;

      // Primary: GET all then local filter by tipe + ukuran (tanpa params)
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] GET pl_lookup_item_nums params: {}');
      }
      response = await apiClient.get(url);
      var items = response.statusCode == 200
          ? parseItems(response.data)
          : <ItemLookupModel>[];
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] parsed count (all) = ${items.length}');
      }
      String k(String? s) => (s ?? '').trim().toLowerCase();
      String kSize(String? s) => normalizeSize(s ?? '');
      bool isInvalidNum(String? v) {
        if (v == null) return true;
        final s = v.trim().toLowerCase();
        return s.isEmpty || s == '0' || s == '0.0' || s == 'null';
      }

      // Primary client-side filter by tipe + ukuran only
      items = items
          .where(
              (i) => k(i.tipe) == k(normTipe) && kSize(i.ukuran) == normUkuran)
          .toList();
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] after primary filter => count=${items.length}');
      }

      // Fallback 1: tambah brand/komponen via server filter bila kosong
      if (items.isEmpty) {
        String normBrand = (brand.split(' - ').first).trim();
        final qpBrand = <String, dynamic>{
          'brand': normBrand,
          'tipe': normTipe,
          'ukuran': ukuran,
        };
        if (!isNone(divan)) qpBrand['divan'] = divan;
        if (!isNone(headboard)) qpBrand['headboard'] = headboard;
        if (!isNone(sorong)) qpBrand['sorong'] = sorong;
        if (kDebugMode) {
          print('[ItemLookupRemoteDataSource] Fallback brand params: $qpBrand');
        }
        try {
          response = await apiClient.get(url, queryParameters: qpBrand);
          if (response.statusCode == 200) {
            items = parseItems(response.data);
            if (kDebugMode) {
              print(
                  '[ItemLookupRemoteDataSource] fallback brand raw count=${items.length}');
            }
          }
        } catch (e, stackTrace) {
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to fetch items with fallback brand',
            extra: {'brand': normBrand, 'fallbackAttempt': true},
            fatal: false,
          );
        }
      }

      // Fallback 2: key alternatif 'type'
      if (items.isEmpty) {
        final qpAlt = <String, dynamic>{
          'type': normTipe,
          'ukuran': ukuran,
        };
        if (kDebugMode) {
          print('[ItemLookupRemoteDataSource] Fallback alt key params: $qpAlt');
        }
        try {
          response = await apiClient.get(url, queryParameters: qpAlt);
          if (response.statusCode == 200) {
            items = parseItems(response.data);
            if (kDebugMode) {
              print(
                  '[ItemLookupRemoteDataSource] fallback alt raw count=${items.length}');
            }
          }
        } catch (e, stackTrace) {
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to fetch items with fallback alt key',
            extra: {'fallbackAttempt': 2},
            fatal: false,
          );
        }
      }

      // Fallback 3: client-side relax size filter (match by tipe only)
      if (items.isEmpty) {
        if (kDebugMode) {
          print(
              '[ItemLookupRemoteDataSource] Fallback tipe-only filter (client-side)');
        }
        try {
          // Ensure we have a source list to filter from
          if (response.statusCode != 200) {
            response = await apiClient.get(url);
          }
          final all = parseItems(response.data);
          items = all.where((i) => k(i.tipe) == k(normTipe)).toList();
          // If context present, prefer items whose description matches component keyword
          final ctx = (contextItemType ?? '').toLowerCase();
          if (ctx.isNotEmpty) {
            items = items.where((i) {
              final d = i.itemDesc.toLowerCase();
              if (ctx == 'divan') return d.contains('divan');
              if (ctx == 'headboard') return d.contains('headboard');
              if (ctx == 'sorong') return d.contains('sorong');
              return true;
            }).toList();
          }
          items = items.where((i) => !isInvalidNum(i.itemNum)).toList();
          if (kDebugMode) {
            print(
                '[ItemLookupRemoteDataSource] fallback tipe-only after ctx filter => count=${items.length}');
          }
        } catch (e, stackTrace) {
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to fetch items with fallback tipe-only filter',
            extra: {'fallbackAttempt': 3},
            fatal: false,
          );
        }
      }
      final preview = items.take(3).map((e) => e.itemNum).toList();
      if (kDebugMode) {
        print(
            '[ItemLookupRemoteDataSource] Response count: ${items.length}, preview=$preview');
      }
      return items;
    } catch (e) {
      if (kDebugMode) {
        print('[ItemLookupRemoteDataSource] Error: $e');
      }
      return [];
    }
  }
}
