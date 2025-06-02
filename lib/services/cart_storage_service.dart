import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/domain/entities/product_entity.dart';

class CartStorageService {
  // Dynamic keys based on user ID
  static String _getCartKey(String userId) => 'cart_items_$userId';
  static String _getCartTimestampKey(String userId) => 'cart_timestamp_$userId';
  static const int _cartExpirationHours = 24; // Cart expires after 24 hours

  // Get current user ID from auth service
  static Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Get user ID from SharedPreferences
      final userId = prefs.getString('user_id');
      return userId;
    } catch (e) {
      print("❌ Failed to get user ID: $e");
      return null;
    }
  }

  // Save cart to SharedPreferences for current user
  static Future<bool> saveCart(List<CartEntity> cartItems) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print("⚠️ No user ID found, cannot save cart");
        return false;
      }

      final prefs = await SharedPreferences.getInstance();

      // Convert cart items to JSON
      final cartJsonList =
          cartItems.map((item) => _cartEntityToJson(item)).toList();
      final cartString = jsonEncode(cartJsonList);

      // Save cart and timestamp with user-specific keys
      await prefs.setString(_getCartKey(userId), cartString);
      await prefs.setInt(
          _getCartTimestampKey(userId), DateTime.now().millisecondsSinceEpoch);

      print(
          "✅ Cart saved successfully for user $userId with ${cartItems.length} items");
      return true;
    } catch (e) {
      print("❌ Failed to save cart: $e");
      return false;
    }
  }

  // Load cart from SharedPreferences for current user
  static Future<List<CartEntity>> loadCart() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print("⚠️ No user ID found, returning empty cart");
        return [];
      }

      final prefs = await SharedPreferences.getInstance();

      // Check if cart exists for this user
      final cartString = prefs.getString(_getCartKey(userId));
      if (cartString == null) {
        print("📭 No saved cart found for user $userId");
        return [];
      }

      // Check cart expiration
      final timestamp = prefs.getInt(_getCartTimestampKey(userId)) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final hoursDifference = (currentTime - timestamp) / (1000 * 60 * 60);

      if (hoursDifference > _cartExpirationHours) {
        print("⏰ Cart expired for user $userId, clearing...");
        await clearCart();
        return [];
      }

      // Parse cart items
      final cartJsonList = jsonDecode(cartString) as List;
      final cartItems =
          cartJsonList.map((json) => _jsonToCartEntity(json)).toList();

      print(
          "✅ Cart loaded successfully for user $userId with ${cartItems.length} items");
      return cartItems;
    } catch (e) {
      print("❌ Failed to load cart: $e");
      return [];
    }
  }

  // Clear cart with specific user ID (for logout)
  static Future<bool> clearCartForUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCartKey(userId));
      await prefs.remove(_getCartTimestampKey(userId));
      print("🗑️ Cart cleared successfully for user $userId");
      return true;
    } catch (e) {
      print("❌ Failed to clear cart for user: $e");
      return false;
    }
  }

  // Clear cart from SharedPreferences for current user
  static Future<bool> clearCart() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print("⚠️ No user ID found, cannot clear cart");
        return false;
      }

      return await clearCartForUser(userId);
    } catch (e) {
      print("❌ Failed to clear cart: $e");
      return false;
    }
  }

  // Clear all carts (for cleanup)
  static Future<bool> clearAllCarts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Remove all cart-related keys
      for (String key in keys) {
        if (key.startsWith('cart_items_') ||
            key.startsWith('cart_timestamp_')) {
          await prefs.remove(key);
        }
      }

      print("🗑️ All carts cleared successfully");
      return true;
    } catch (e) {
      print("❌ Failed to clear all carts: $e");
      return false;
    }
  }

  // Convert CartEntity to JSON
  static Map<String, dynamic> _cartEntityToJson(CartEntity cart) {
    return {
      'product': _productEntityToJson(cart.product),
      'quantity': cart.quantity,
      'netPrice': cart.netPrice,
      'discountPercentages': cart.discountPercentages,
      'editPopupDiscount': cart.editPopupDiscount,
      'installmentMonths': cart.installmentMonths,
      'installmentPerMonth': cart.installmentPerMonth,
    };
  }

  // Convert ProductEntity to JSON
  static Map<String, dynamic> _productEntityToJson(ProductEntity product) {
    return {
      'id': product.id,
      'area': product.area,
      'channel': product.channel,
      'brand': product.brand,
      'kasur': product.kasur,
      'isSet': product.isSet,
      'divan': product.divan,
      'headboard': product.headboard,
      'sorong': product.sorong,
      'ukuran': product.ukuran,
      'pricelist': product.pricelist,
      'program': product.program,
      'eupKasur': product.eupKasur,
      'eupDivan': product.eupDivan,
      'eupHeadboard': product.eupHeadboard,
      'endUserPrice': product.endUserPrice,
      'bonus': product.bonus
          .map((b) => {
                'name': b.name,
                'quantity': b.quantity,
              })
          .toList(),
      'discounts': product.discounts,
    };
  }

  // Convert JSON to CartEntity
  static CartEntity _jsonToCartEntity(Map<String, dynamic> json) {
    return CartEntity(
      product: _jsonToProductEntity(json['product']),
      quantity: json['quantity'] ?? 1,
      netPrice: (json['netPrice'] ?? 0).toDouble(),
      discountPercentages: List<double>.from(
        (json['discountPercentages'] ?? []).map((e) => e.toDouble()),
      ),
      editPopupDiscount: (json['editPopupDiscount'] ?? 0).toDouble(),
      installmentMonths: json['installmentMonths'],
      installmentPerMonth: json['installmentPerMonth']?.toDouble(),
    );
  }

  // Convert JSON to ProductEntity
  static ProductEntity _jsonToProductEntity(Map<String, dynamic> json) {
    // Create bonus list from JSON
    List<BonusItem> bonusList = [];
    if (json['bonus'] != null && json['bonus'] is List) {
      bonusList = (json['bonus'] as List)
          .map((b) => BonusItem(
                name: b['name'] ?? '',
                quantity: b['quantity'] ?? 0,
              ))
          .toList();
    }

    return ProductEntity(
      id: json['id'] ?? 0,
      area: json['area'] ?? '',
      channel: json['channel'] ?? '',
      brand: json['brand'] ?? '',
      kasur: json['kasur'] ?? '',
      isSet: json['isSet'] ?? false,
      divan: json['divan'] ?? '',
      headboard: json['headboard'] ?? '',
      sorong: json['sorong'] ?? '',
      ukuran: json['ukuran'] ?? '',
      pricelist: (json['pricelist'] ?? 0).toDouble(),
      program: json['program'] ?? '',
      eupKasur: (json['eupKasur'] ?? 0).toDouble(),
      eupDivan: (json['eupDivan'] ?? 0).toDouble(),
      eupHeadboard: (json['eupHeadboard'] ?? 0).toDouble(),
      endUserPrice: (json['endUserPrice'] ?? 0).toDouble(),
      bonus: bonusList,
      discounts: List<double>.from(
        (json['discounts'] ?? []).map((e) => e.toDouble()),
      ),
    );
  }
}
