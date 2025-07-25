import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constant.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/domain/entities/product_entity.dart';
import 'auth_service.dart';

/// Service untuk menyimpan, mengambil, dan menghapus cart user di local storage.
class CartStorageService {
  /// Mendapatkan key cart untuk user tertentu.
  static String _getCartKey(int userId) => '${StorageKeys.cartKeyBase} $userId';

  /// Menyimpan list cart ke SharedPreferences.
  static Future<bool> saveCartItems(List<CartEntity> cartItems) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final cartKey = _getCartKey(userId);
      final List<Map<String, dynamic>> cartJson =
          cartItems.map((item) => _cartEntityToJson(item)).toList();
      await prefs.setString(cartKey, jsonEncode(cartJson));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Mengambil list cart dari SharedPreferences.
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
      return cartItems;
    } catch (e) {
      await clearCart();
      return [];
    }
  }

  /// Menghapus cart user dari SharedPreferences.
  static Future<bool> clearCart() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCartKey(userId));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Konversi CartEntity ke Map untuk disimpan.
  static Map<String, dynamic> _cartEntityToJson(CartEntity item) {
    return {
      'product': _productToJson(item.product),
      'quantity': item.quantity,
      'netPrice': item.netPrice,
      'discountPercentages': item.discountPercentages,
      'editPopupDiscount': item.editPopupDiscount,
      'installmentMonths': item.installmentMonths,
      'installmentPerMonth': item.installmentPerMonth,
      'isSelected': item.isSelected,
    };
  }

  /// Konversi Map ke CartEntity.
  static CartEntity _cartEntityFromJson(Map<String, dynamic> json) {
    return CartEntity(
      product: _productFromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      netPrice: (json['netPrice'] ?? 0.0).toDouble(),
      discountPercentages: List<double>.from(json['discountPercentages'] ?? []),
      editPopupDiscount: (json['editPopupDiscount'] ?? 0.0).toDouble(),
      installmentMonths: json['installmentMonths'],
      installmentPerMonth: json['installmentPerMonth']?.toDouble(),
      isSelected: json['isSelected'] ?? true,
    );
  }

  /// Konversi ProductEntity ke Map untuk disimpan.
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
      'isSet': product.isSet,
      'bonus': product.bonus
          .map((b) => {'name': b.name, 'quantity': b.quantity})
          .toList(),
      'discounts': product.discounts,
      'plKasur': product.plKasur,
      'plDivan': product.plDivan,
      'plHeadboard': product.plHeadboard,
      'plSorong': product.plSorong,
      'eupSorong': product.eupSorong,
      'bottomPriceAnalyst': product.bottomPriceAnalyst,
      'disc1': product.disc1,
      'disc2': product.disc2,
      'disc3': product.disc3,
      'disc4': product.disc4,
      'disc5': product.disc5,
    };
  }

  /// Konversi Map ke ProductEntity.
  static ProductEntity _productFromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json['id'] ?? 0,
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
      plKasur: (json['plKasur'] ?? 0.0).toDouble(),
      plDivan: (json['plDivan'] ?? 0.0).toDouble(),
      plHeadboard: (json['plHeadboard'] ?? 0.0).toDouble(),
      plSorong: (json['plSorong'] ?? 0.0).toDouble(),
      eupSorong: (json['eupSorong'] ?? 0.0).toDouble(),
      bottomPriceAnalyst: (json['bottomPriceAnalyst'] ?? 0.0).toDouble(),
      disc1: (json['disc1'] ?? 0.0).toDouble(),
      disc2: (json['disc2'] ?? 0.0).toDouble(),
      disc3: (json['disc3'] ?? 0.0).toDouble(),
      disc4: (json['disc4'] ?? 0.0).toDouble(),
      disc5: (json['disc5'] ?? 0.0).toDouble(),
    );
  }
}
