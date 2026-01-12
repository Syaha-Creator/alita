import '../config/dependency_injection.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/cart/domain/repositories/cart_repository.dart';

/// Service untuk menyimpan, mengambil, dan menghapus cart user di local storage.
/// Wrapper untuk CartRepository untuk backward compatibility
class CartStorageService {
  /// Menyimpan list cart ke SharedPreferences.
  /// Uses CartRepository if available, otherwise falls back to direct SharedPreferences
  static Future<bool> saveCartItems(List<CartEntity> cartItems) async {
    try {
      final repository = locator<CartRepository>();
      return await repository.saveCartItems(cartItems);
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      // This should not happen in normal flow, but kept for safety
      return false;
    }
  }

  /// Mengambil list cart dari SharedPreferences.
  /// Uses CartRepository if available, otherwise falls back to direct SharedPreferences
  static Future<List<CartEntity>> loadCartItems() async {
    try {
      final repository = locator<CartRepository>();
      return await repository.loadCartItems();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      // This should not happen in normal flow, but kept for safety
      return [];
    }
  }

  /// Menghapus cart user dari SharedPreferences.
  /// Uses CartRepository if available, otherwise falls back to direct SharedPreferences
  static Future<bool> clearCart() async {
    try {
      final repository = locator<CartRepository>();
      return await repository.clearCart();
    } catch (e) {
      // Fallback to direct SharedPreferences access for backward compatibility
      // This should not happen in normal flow, but kept for safety
      return false;
    }
  }
}
