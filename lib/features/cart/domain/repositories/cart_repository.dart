import '../entities/cart_entity.dart';

/// Repository interface untuk cart operations
abstract class CartRepository {
  Future<List<CartEntity>> loadCartItems();
  Future<bool> saveCartItems(List<CartEntity> cartItems);
  Future<bool> clearCart();
}

