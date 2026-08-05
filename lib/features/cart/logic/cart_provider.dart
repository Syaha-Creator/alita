import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/log.dart';
import '../../pricelist/data/models/product.dart';
import '../data/cart_item.dart';

/// Stable key for a cart line — must match _isSameLine exactly.
/// Used for selection and for removeItemsByIds.
String cartItemKey(CartItem item) {
  final indirect =
      item.isIndirectSale ? '|i${item.indirectStoreAddressNumber}' : '|d';
  final foc = item.isFocVoucherActive ? '|foc' : '';
  final bonus = item.bonusSnapshots.map((b) => '${b.name}:${b.qty}').join(',');
  final bonusSuffix = bonus.isEmpty ? '' : '|$bonus';
  // Include ukuran so the same catalog product id with different sizes
  // (or custom size) never collapses into one cart line.
  return '${item.product.id}|${item.product.ukuran}|${item.kasurSku}|${item.divanSku}|${item.sandaranSku}|${item.sorongSku}$indirect$foc$bonusSuffix';
}

/// Cart state notifier with persistent storage
class CartNotifier extends Notifier<List<CartItem>> {
  late final Future<void> _loadCartFuture;

  @override
  List<CartItem> build() {
    _loadCartFuture = _loadCart();
    return [];
  }

  /// Load cart from storage on init
  Future<void> _loadCart() async {
    final cartData = await StorageService.loadCart();
    if (cartData.isNotEmpty) {
      try {
        final items = cartData.map((json) => CartItem.fromJson(json)).toList();
        state = items;
      } catch (e, st) {
        Log.error(e, st, reason: 'CartNotifier._loadCart parse');
        state = [];
      }
    }
  }

  /// Save cart to storage
  Future<void> _saveCart() async {
    final cartData = state.map((item) => item.toJson()).toList();
    await StorageService.saveCart(cartData);
  }

  /// Returns true if [a] and [b] represent the same cart line:
  /// same Product ID, ukuran, component SKUs, store, FOC flag, AND bonus list.
  /// Same product with different ukuran (or different bonuses) stay separate.
  static bool _isSameLine(CartItem a, CartItem b) =>
      a.product.id == b.product.id &&
      a.product.ukuran == b.product.ukuran &&
      a.kasurSku == b.kasurSku &&
      a.divanSku == b.divanSku &&
      a.sandaranSku == b.sandaranSku &&
      a.sorongSku == b.sorongSku &&
      a.indirectStoreAddressNumber == b.indirectStoreAddressNumber &&
      a.isFocVoucherActive == b.isFocVoucherActive &&
      _bonusListEquals(a.bonusSnapshots, b.bonusSnapshots);

  /// Add a fully-snapshotted CartItem to the cart.
  /// Items are merged only when Product ID AND all component SKUs match.
  /// Different configurations of the same product become separate cart lines.
  ///
  /// On merge the incoming item's [product] and [bonusSnapshots] replace the
  /// existing ones so that stale data (e.g. bonus qty changed on the server)
  /// is refreshed automatically.
  Future<void> addItem(CartItem cartItem) async {
    await _loadCartFuture;
    final existingIndex = state.indexWhere(
      (item) => _isSameLine(item, cartItem),
    );

    if (existingIndex >= 0) {
      final existing = state[existingIndex];
      final updatedItem = cartItem.copyWith(
        quantity: existing.quantity + cartItem.quantity,
      );
      state = [
        ...state.sublist(0, existingIndex),
        updatedItem,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, cartItem];
    }

    await _saveCart();
  }

  /// Remove a specific cart line by its index.
  Future<void> removeItemAt(int index) async {
    await _loadCartFuture;
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Remove all lines that share the given product ID (legacy helper).
  Future<void> removeItem(String productId) async {
    await _loadCartFuture;
    state = state.where((item) => item.product.id != productId).toList();
    await _saveCart();
  }

  /// Decrement quantity of the cart line at [index], removing it if qty hits 0.
  Future<void> decrementItem(int index) async {
    await _loadCartFuture;
    if (index < 0 || index >= state.length) return;
    final current = state[index];

    if (current.quantity > 1) {
      state = [
        ...state.sublist(0, index),
        current.copyWith(quantity: current.quantity - 1),
        ...state.sublist(index + 1),
      ];
      await _saveCart();
    } else {
      await removeItemAt(index);
    }
  }

  /// Replace item at [index] with an updated snapshot CartItem (edit mode).
  ///
  /// Secara default kuantitas baris lama dipertahankan (aliran edit dari
  /// halaman detail). Set [preserveQuantity] false bila snapshot sudah
  /// membawa kuantitas baru (mis. editor baris custom pricelist).
  Future<void> updateCartItem(
    int index,
    CartItem cartItem, {
    bool preserveQuantity = true,
  }) async {
    await _loadCartFuture;
    if (index < 0 || index >= state.length) return;
    final preserved = state[index].quantity;
    final qty = preserveQuantity ? preserved : cartItem.quantity;
    state = [
      ...state.sublist(0, index),
      cartItem.copyWith(quantity: qty),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Voucher FOC 100% pada satu baris keranjang (tidak mengubah snapshot produk).
  Future<void> setItemFocVoucher(int index, bool value) async {
    await _loadCartFuture;
    if (index < 0 || index >= state.length) return;
    final current = state[index];
    if (!current.isIndirectSale && value) return;
    if (current.isFocVoucher == value) return;
    state = [
      ...state.sublist(0, index),
      current.copyWith(isFocVoucher: value),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Increment quantity of the cart line at [index].
  Future<void> incrementItem(int index) async {
    await _loadCartFuture;
    if (index < 0 || index >= state.length) return;
    final current = state[index];
    state = [
      ...state.sublist(0, index),
      current.copyWith(quantity: current.quantity + 1),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Clear all items from cart
  Future<void> clearCart() async {
    await _loadCartFuture;
    state = [];
    await _saveCart();
  }

  /// Replace entire cart (e.g. after server price refresh).
  Future<void> replaceCartItems(List<CartItem> next) async {
    await _loadCartFuture;
    state = List<CartItem>.from(next);
    await _saveCart();
  }

  /// Remove only cart lines whose [cartItemKey] is in [ids].
  /// Used after selective checkout so unchecked items stay in cart.
  Future<void> removeItemsByIds(Set<String> ids) async {
    await _loadCartFuture;
    if (ids.isEmpty) return;
    state = state.where((item) => !ids.contains(cartItemKey(item))).toList();
    await _saveCart();
  }

  /// Get total number of items in cart
  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get total amount (price)
  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Refresh bonus snapshots for all cart items using the latest product data.
  ///
  /// Call when entering checkout to ensure bonus quantities reflect the
  /// server-side values (which may have changed since the item was added).
  Future<void> refreshBonusSnapshots(List<Product> allProducts) async {
    await _loadCartFuture;
    if (state.isEmpty || allProducts.isEmpty) return;

    final productById = <dynamic, Product>{};
    for (final p in allProducts) {
      productById.putIfAbsent(p.id, () => p);
    }

    var changed = false;
    final updated = state.map((item) {
      final fresh = productById[item.product.id];
      if (fresh == null) return item;

      final freshBonuses = _buildBonusSnapshotsFromProduct(fresh);
      if (_bonusListEquals(item.bonusSnapshots, freshBonuses)) return item;

      changed = true;
      return item.copyWith(bonusSnapshots: freshBonuses);
    }).toList();

    if (changed) {
      state = updated;
      await _saveCart();
    }
  }

  static List<CartBonusSnapshot> _buildBonusSnapshotsFromProduct(Product p) {
    final slots = <(String?, int?, double?)>[
      (p.bonus1, p.qtyBonus1, p.plBonus1),
      (p.bonus2, p.qtyBonus2, p.plBonus2),
      (p.bonus3, p.qtyBonus3, p.plBonus3),
      (p.bonus4, p.qtyBonus4, p.plBonus4),
      (p.bonus5, p.qtyBonus5, p.plBonus5),
      (p.bonus6, p.qtyBonus6, p.plBonus6),
      (p.bonus7, p.qtyBonus7, p.plBonus7),
      (p.bonus8, p.qtyBonus8, p.plBonus8),
    ];

    return [
      for (final (name, qty, pl) in slots)
        if (name != null && name.isNotEmpty)
          CartBonusSnapshot(name: name, qty: qty ?? 1, plPrice: pl ?? 0.0),
    ];
  }

  static bool _bonusListEquals(
    List<CartBonusSnapshot> a,
    List<CartBonusSnapshot> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].qty != b[i].qty) return false;
    }
    return true;
  }
}

/// Cart provider
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Total items count provider
final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

/// Total amount provider (all items)
final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

// ─── Selective checkout: which cart lines are selected ─────────────────────

/// Tracks selected cart item keys. Empty = nothing selected (checkout disabled).
class SelectedCartIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggleSelectItem(String id, bool isSelected) {
    if (isSelected) {
      state = {...state, id};
    } else {
      state = Set.from(state)..remove(id);
    }
  }

  void toggleSelectAll(bool isSelected) {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = {};
      return;
    }
    if (isSelected) {
      state = cart.map((item) => cartItemKey(item)).toSet();
    } else {
      state = {};
    }
  }

  /// Hapus ID pilihan yang tidak lagi cocok dengan baris di [cart] (mis. setelah
  /// edit konfigurasi/FOC atau item dihapus — [cartItemKey] berubah).
  void syncWithCart(List<CartItem> cart) {
    final validKeys = cart.map(cartItemKey).toSet();
    final next = state.intersection(validKeys);
    if (next.length != state.length) {
      state = next;
    }
  }
}

final selectedCartItemIdsProvider =
    NotifierProvider<SelectedCartIdsNotifier, Set<String>>(
  SelectedCartIdsNotifier.new,
);

/// True bila minimal satu **baris keranjang saat ini** terpilih.
/// Tidak memakai [Set.isNotEmpty] mentah — ID bisa stale setelah edit/hapus baris.
final cartHasSelectedLinesProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  final selectedIds = ref.watch(selectedCartItemIdsProvider);
  for (final item in cart) {
    if (selectedIds.contains(cartItemKey(item))) return true;
  }
  return false;
});

/// True when every cart line is selected and cart is not empty.
final isAllSelectedProvider = Provider<bool>((ref) {
  final cart = ref.watch(cartProvider);
  final selectedIds = ref.watch(selectedCartItemIdsProvider);
  if (cart.isEmpty) return false;
  return cart.every((item) => selectedIds.contains(cartItemKey(item)));
});

/// Total amount for selected items only. Zero when nothing selected.
final cartSelectedTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final selectedIds = ref.watch(selectedCartItemIdsProvider);
  return cart.fold<double>(
    0.0,
    (sum, item) =>
        selectedIds.contains(cartItemKey(item)) ? sum + item.totalPrice : sum,
  );
});

/// List of cart items that are currently selected (for passing to checkout).
final selectedCartItemsProvider = Provider<List<CartItem>>((ref) {
  final cart = ref.watch(cartProvider);
  final selectedIds = ref.watch(selectedCartItemIdsProvider);
  return cart.where((item) => selectedIds.contains(cartItemKey(item))).toList();
});
