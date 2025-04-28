import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cart_entity.dart';
import 'event/cart_event.dart';
import 'state/cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartInitial()) {
    on<AddToCart>((event, emit) {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final existingItem = currentState.cartItems.firstWhere(
          (item) =>
              item.product.id == event.product.id &&
              item.netPrice == event.netPrice &&
              item.discountPercentages == event.discountPercentages &&
              item.editPopupDiscount == event.editPopupDiscount &&
              item.installmentMonths == event.installmentMonths,
          orElse: () => CartEntity(
            product: event.product,
            quantity: 0,
            netPrice: event.netPrice,
            discountPercentages: event.discountPercentages,
            editPopupDiscount: event.editPopupDiscount,
            installmentMonths: event.installmentMonths,
            installmentPerMonth: event.installmentPerMonth,
          ),
        );

        final updatedItems = currentState.cartItems
            .where((item) =>
                item.product.id != event.product.id ||
                item.netPrice != event.netPrice ||
                item.discountPercentages != event.discountPercentages ||
                item.editPopupDiscount != event.editPopupDiscount ||
                item.installmentMonths != event.installmentMonths)
            .toList();

        updatedItems.add(
          CartEntity(
            product: event.product,
            quantity: existingItem.quantity + event.quantity,
            netPrice: event.netPrice,
            discountPercentages: event.discountPercentages,
            editPopupDiscount: event.editPopupDiscount,
            installmentMonths: event.installmentMonths,
            installmentPerMonth: event.installmentPerMonth,
          ),
        );
        emit(CartLoaded(updatedItems));
      } else {
        emit(CartLoaded([
          CartEntity(
            product: event.product,
            quantity: event.quantity,
            netPrice: event.netPrice,
            discountPercentages: event.discountPercentages,
            editPopupDiscount: event.editPopupDiscount,
            installmentMonths: event.installmentMonths,
            installmentPerMonth: event.installmentPerMonth,
          )
        ]));
      }
    });

    on<RemoveFromCart>((event, emit) {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems
            .where((item) =>
                item.product.id != event.productId ||
                item.netPrice != event.netPrice)
            .toList();
        emit(CartLoaded(updatedItems));
      }
    });

    on<UpdateCartQuantity>((event, emit) {
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
              editPopupDiscount: item.editPopupDiscount,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
            );
          }
          return item;
        }).toList();
        emit(CartLoaded(updatedItems));
      }
    });

    on<ClearCart>((event, emit) {
      emit(CartLoaded([]));
    });
  }
}
