import '../../../../core/error/exceptions.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

/// Repository implementation untuk product
/// Menggunakan remote datasource sesuai Clean Architecture
class ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepository({required this.remoteDataSource});

  Future<List<ProductModel>> fetchProductsWithFilter({
    required String area,
    required String channel,
    required String brand,
  }) async {
    try {
      return await remoteDataSource.fetchProductsWithFilter(
        area: area,
        channel: channel,
        brand: brand,
      );
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        "Terjadi kesalahan yang tidak diketahui saat memproses data: $e",
      );
    }
  }
}
