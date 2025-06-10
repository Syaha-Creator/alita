// lib/services/cart_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constant.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/domain/entities/product_entity.dart';
import 'auth_service.dart';

class CartStorageService {
  static String _getCartKey(int userId) => '${StorageKeys.cartKeyBase}$userId';

  static Future<bool> saveCartItems(List<CartEntity> cartItems) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final cartKey = _getCartKey(userId);
      final List<Map<String, dynamic>> cartJson =
          cartItems.map((item) => _cartEntityToJson(item)).toList();

      await prefs.setString(cartKey, jsonEncode(cartJson));

      print("🛒 Cart for user $userId saved successfully.");
      return true;
    } catch (e) {
      print("❌ Error saving cart: $e");
      return false;
    }
  }

  static Future<List<CartEntity>> loadCartItems() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return [];

      final prefs = await SharedPreferences.getInstance();
      final cartKey = _getCartKey(userId);

      final String? cartData = prefs.getString(cartKey);

      if (cartData == null) return [];

      final List<dynamic> cartJson = jsonDecode(cartData);
      final List<CartEntity> cartItems =
          cartJson.map((item) => _cartEntityFromJson(item)).toList();

      print("🛒 Cart for user $userId loaded successfully (no expiration).");
      return cartItems;
    } catch (e) {
      print("❌ Error loading cart: $e");
      await clearCart();
      return [];
    }
  }

  static Future<bool> clearCart() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCartKey(userId));

      print("🛒 Cart for user $userId cleared successfully");
      return true;
    } catch (e) {
      print("❌ Error clearing cart: $e");
      return false;
    }
  }

  static Map<String, dynamic> _cartEntityToJson(CartEntity item) {
    return {
      'product': _productToJson(item.product),
      'quantity': item.quantity,
      'netPrice': item.netPrice,
      'discountPercentages': item.discountPercentages,
      'editPopupDiscount': item.editPopupDiscount,
      'installmentMonths': item.installmentMonths,
      'installmentPerMonth': item.installmentPerMonth,
    };
  }

  static CartEntity _cartEntityFromJson(Map<String, dynamic> json) {
    return CartEntity(
      product: _productFromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      netPrice: (json['netPrice'] ?? 0.0).toDouble(),
      discountPercentages: List<double>.from(json['discountPercentages'] ?? []),
      editPopupDiscount: (json['editPopupDiscount'] ?? 0.0).toDouble(),
      installmentMonths: json['installmentMonths'],
      installmentPerMonth: json['installmentPerMonth']?.toDouble(),
    );
  }

  static Map<String, dynamic> _productToJson(ProductEntity product) {
    return {
      'id': product.id,
      'area': product.area,
      'channel': product.channel,
      'brand': product.brand,
      'kasur': product.kasur,
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
          .map((b) => {'name': b.name, 'quantity': b.quantity})
          .toList(),
      'discounts': product.discounts,
      'isSet': product.isSet,
    };
  }

  static ProductEntity _productFromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'],
      area: json['area'] ?? '',
      channel: json['channel'] ?? '',
      brand: json['brand'] ?? '',
      kasur: json['kasur'] ?? '',
      divan: json['divan'] ?? '',
      headboard: json['headboard'] ?? '',
      sorong: json['sorong'] ?? '',
      ukuran: json['ukuran'] ?? '',
      pricelist: (json['pricelist'] ?? 0.0).toDouble(),
      program: json['program'] ?? '',
      eupKasur: (json['eupKasur'] ?? 0.0).toDouble(),
      eupDivan: (json['eupDivan'] ?? 0.0).toDouble(),
      eupHeadboard: (json['eupHeadboard'] ?? 0.0).toDouble(),
      endUserPrice: (json['endUserPrice'] ?? 0.0).toDouble(),
      bonus: (json['bonus'] as List? ?? [])
          .map((b) =>
              BonusItem(name: b['name'] ?? '', quantity: b['quantity'] ?? 0))
          .toList(),
      discounts: List<double>.from(json['discounts'] ?? []),
      isSet: json['isSet'] ?? false,
    );
  }
}
