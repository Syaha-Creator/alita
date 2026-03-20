import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';
import '../../../core/utils/log.dart';
import '../data/cart_item.dart';

/// Stable key for a cart line (same product + same component SKUs = same key).
/// Used for selection and for removeItemsByIds.
String cartItemKey(CartItem item) {
  return '${item.product.id}|${item.kasurSku}|${item.divanSku}|${item.sandaranSku}|${item.sorongSku}';
}

/// Cart state notifier with persistent storage
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _loadCart();
  }

  /// Load cart from storage on init
  Future<void> _loadCart() async {
    final cartData = await StorageService.loadCart();
    if (cartData.isNotEmpty) {
      try {
        final items = cartData
            .map((json) => CartItem.fromJson(json))
            .toList();
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
  /// same Product ID AND the same full set of component SKUs.
  static bool _isSameLine(CartItem a, CartItem b) =>
      a.product.id == b.product.id &&
      a.kasurSku == b.kasurSku &&
      a.divanSku == b.divanSku &&
      a.sandaranSku == b.sandaranSku &&
      a.sorongSku == b.sorongSku;

  /// Add a fully-snapshotted CartItem to the cart.
  /// Items are merged only when Product ID AND all component SKUs match.
  /// Different configurations of the same product become separate cart lines.
  Future<void> addItem(CartItem cartItem) async {
    final existingIndex = state.indexWhere(
      (item) => _isSameLine(item, cartItem),
    );

    if (existingIndex >= 0) {
      final updatedItem = state[existingIndex].copyWith(
        quantity: state[existingIndex].quantity + cartItem.quantity,
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
    if (index < 0 || index >= state.length) return;
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Remove all lines that share the given product ID (legacy helper).
  Future<void> removeItem(String productId) async {
    state = state.where((item) => item.product.id != productId).toList();
    await _saveCart();
  }

  /// Decrement quantity of the cart line at [index], removing it if qty hits 0.
  Future<void> decrementItem(int index) async {
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
  /// The original quantity is preserved unless the caller explicitly sets one.
  Future<void> updateCartItem(int index, CartItem cartItem) async {
    if (index < 0 || index >= state.length) return;
    final preserved = state[index].quantity;
    state = [
      ...state.sublist(0, index),
      cartItem.copyWith(quantity: preserved),
      ...state.sublist(index + 1),
    ];
    await _saveCart();
  }

  /// Increment quantity of the cart line at [index].
  Future<void> incrementItem(int index) async {
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
    state = [];
    await _saveCart();
  }

  /// Remove only cart lines whose [cartItemKey] is in [ids].
  /// Used after selective checkout so unchecked items stay in cart.
  Future<void> removeItemsByIds(Set<String> ids) async {
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
}

/// Cart provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

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
class SelectedCartIdsNotifier extends StateNotifier<Set<String>> {
  SelectedCartIdsNotifier(this._ref) : super({});

  final Ref _ref;

  void toggleSelectItem(String id, bool isSelected) {
    if (isSelected) {
      state = {...state, id};
    } else {
      state = Set.from(state)..remove(id);
    }
  }

  void toggleSelectAll(bool isSelected) {
    final cart = _ref.read(cartProvider);
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
}

final selectedCartItemIdsProvider =
    StateNotifierProvider<SelectedCartIdsNotifier, Set<String>>((ref) {
  return SelectedCartIdsNotifier(ref);
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
  return cart
      .where((item) => selectedIds.contains(cartItemKey(item)))
      .toList();
});
