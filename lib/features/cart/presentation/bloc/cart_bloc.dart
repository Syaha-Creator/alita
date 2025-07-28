// File: lib/features/cart/presentation/bloc/cart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/cart_storage_service.dart';
import '../../domain/entities/cart_entity.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartLoaded([])) {
    on<LoadCart>((event, emit) async {
      try {
        final cartItems = await CartStorageService.loadCartItems();
        emit(CartLoaded(cartItems));
      } catch (e) {
        emit(CartError("Failed to load cart: $e"));
      }
    });

    on<AddToCart>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;

        // Check if item with same configuration already exists
        final existingItemIndex = currentState.cartItems.indexWhere(
          (item) =>
              item.product.id == event.product.id &&
              item.netPrice == event.netPrice &&
              _listEquals(
                  item.discountPercentages, event.discountPercentages) &&
              item.installmentMonths == event.installmentMonths,
        );

        List<CartEntity> updatedItems = List.from(currentState.cartItems);

        if (existingItemIndex != -1) {
          // Update existing item quantity
          final existingItem = updatedItems[existingItemIndex];
          updatedItems[existingItemIndex] = CartEntity(
            product: existingItem.product,
            quantity: existingItem.quantity + event.quantity,
            netPrice: existingItem.netPrice,
            discountPercentages: existingItem.discountPercentages,
            installmentMonths: existingItem.installmentMonths,
            installmentPerMonth: existingItem.installmentPerMonth,
          );
        } else {
          // Add new item
          updatedItems.add(
            CartEntity(
              product: event.product,
              quantity: event.quantity,
              netPrice: event.netPrice,
              discountPercentages: event.discountPercentages,
              installmentMonths: event.installmentMonths,
              installmentPerMonth: event.installmentPerMonth,
            ),
          );
        }

        // Save to storage and emit new state
        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      } else {
        // Create new cart
        final newCart = [
          CartEntity(
            product: event.product,
            quantity: event.quantity,
            netPrice: event.netPrice,
            discountPercentages: event.discountPercentages,
            installmentMonths: event.installmentMonths,
            installmentPerMonth: event.installmentPerMonth,
          )
        ];

        await CartStorageService.saveCartItems(newCart);
        emit(CartLoaded(newCart));
      }
    });

    on<RemoveFromCart>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems
            .where((item) => !(item.product.id == event.productId &&
                item.netPrice == event.netPrice))
            .toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<UpdateCartQuantity>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            return CartEntity(
              product: item.product,
              quantity: event.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
            );
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<ToggleCartItemSelection>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Gunakan copyWith untuk mengubah status isSelected
            return item.copyWith(isSelected: !item.isSelected);
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<ClearCart>((event, emit) async {
      await CartStorageService.clearCart();
      emit(CartLoaded([]));
    });

    on<Checkout>((event, emit) async {
      if (state is CartLoaded) {
        // After successful checkout, clear the cart
        await CartStorageService.clearCart();
        emit(CartLoaded([]));
      }
    });

    on<ReloadCartForUser>((event, emit) async {
      add(LoadCart());
    });

    // Auto-load cart when bloc is created
    add(LoadCart());
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
