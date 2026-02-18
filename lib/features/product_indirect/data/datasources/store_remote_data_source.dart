import 'package:dio/dio.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/error/exceptions.dart';
import '../models/store_model.dart';

/// Remote data source untuk fetch stores (toko) dari API Indirect
abstract class StoreRemoteDataSource {
  /// Fetch list of stores berdasarkan sales_code (address_number user)
  Future<List<StoreModel>> fetchStoresBySalesCode({
    required String salesCode,
  });
}

class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final Dio dio;

  StoreRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<List<StoreModel>> fetchStoresBySalesCode({
    required String salesCode,
  }) async {
    try {
      final url = IndirectApiConfig.getStoreUrl(salesCode: salesCode);

      final response = await dio.get(
        url,
        options: Options(
          headers: IndirectApiConfig.headers,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException(
          'Gagal mengambil data toko. Kode error: ${response.statusCode}',
        );
      }

      final data = response.data;

      // Check API response status
      if (data['status'] != true) {
        throw ServerException(
          'API mengembalikan status error',
        );
      }

      final result = data['result'];
      if (result is! List) {
        return []; // Return empty list if no stores found
      }

      final stores = result.map((item) {
        return StoreModel.fromJson(item as Map<String, dynamic>);
      }).toList();

      // Sort by alpha_name
      stores.sort(
        (a, b) =>
            a.alphaName.toLowerCase().compareTo(b.alphaName.toLowerCase()),
      );

      return stores;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          'Timeout saat mengambil data toko. Silakan coba lagi.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
        );
      } else {
        throw ServerException('Error jaringan: ${e.message}');
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException('Error tidak terduga: $e');
    }
  }
}
