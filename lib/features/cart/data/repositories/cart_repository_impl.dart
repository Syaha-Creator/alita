import '../../../../core/error/exceptions.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';

/// Repository implementation untuk cart
/// Menggunakan local datasource sesuai Clean Architecture
class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource localDataSource;

  CartRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CartEntity>> loadCartItems() async {
    try {
      return await localDataSource.loadCartItems();
    } catch (e) {
      throw CacheException('Gagal memuat cart: ${e.toString()}');
    }
  }

  @override
  Future<bool> saveCartItems(List<CartEntity> cartItems) async {
    try {
      return await localDataSource.saveCartItems(cartItems);
    } catch (e) {
      throw CacheException('Gagal menyimpan cart: ${e.toString()}');
    }
  }

  @override
  Future<bool> clearCart() async {
    try {
      return await localDataSource.clearCart();
    } catch (e) {
      throw CacheException('Gagal menghapus cart: ${e.toString()}');
    }
  }
}

