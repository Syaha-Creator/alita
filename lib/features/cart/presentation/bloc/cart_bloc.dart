// File: lib/features/cart/presentation/bloc/cart_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/cart_storage_service.dart';
import '../../domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
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

    on<MarkItemAsCheckedOut>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            return item.copyWith(isCheckedOut: true);
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
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

    on<UpdateCartBonus>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Create updated bonus list
            final updatedBonus = List<BonusItem>.from(item.product.bonus);
            if (event.bonusIndex < updatedBonus.length) {
              if (event.bonusQuantity <= 0) {
                // Remove bonus if quantity is 0 or less
                updatedBonus.removeAt(event.bonusIndex);
              } else {
                // Update bonus with new quantity
                updatedBonus[event.bonusIndex] = BonusItem(
                  name: event.bonusName,
                  quantity: event.bonusQuantity,
                );
              }
            }

            // Create updated product with new bonus
            final updatedProduct = ProductEntity(
              id: item.product.id,
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
              kasur: item.product.kasur,
              divan: item.product.divan,
              headboard: item.product.headboard,
              sorong: item.product.sorong,
              ukuran: item.product.ukuran,
              pricelist: item.product.pricelist,
              program: item.product.program,
              eupKasur: item.product.eupKasur,
              eupDivan: item.product.eupDivan,
              eupHeadboard: item.product.eupHeadboard,
              endUserPrice: item.product.endUserPrice,
              bonus: updatedBonus,
              discounts: item.product.discounts,
              isSet: item.product.isSet,
              plKasur: item.product.plKasur,
              plDivan: item.product.plDivan,
              plHeadboard: item.product.plHeadboard,
              plSorong: item.product.plSorong,
              eupSorong: item.product.eupSorong,
              bottomPriceAnalyst: item.product.bottomPriceAnalyst,
              disc1: item.product.disc1,
              disc2: item.product.disc2,
              disc3: item.product.disc3,
              disc4: item.product.disc4,
              disc5: item.product.disc5,
              itemNumber: item.product.itemNumber,
              itemNumberKasur: item.product.itemNumberKasur,
              itemNumberDivan: item.product.itemNumberDivan,
              itemNumberHeadboard: item.product.itemNumberHeadboard,
              itemNumberSorong: item.product.itemNumberSorong,
              itemNumberAccessories: item.product.itemNumberAccessories,
              itemNumberBonus1: item.product.itemNumberBonus1,
              itemNumberBonus2: item.product.itemNumberBonus2,
              itemNumberBonus3: item.product.itemNumberBonus3,
              itemNumberBonus4: item.product.itemNumberBonus4,
              itemNumberBonus5: item.product.itemNumberBonus5,
            );

            return CartEntity(
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
            );
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<RemoveCartBonus>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Create updated bonus list without the specified bonus
            final updatedBonus = List<BonusItem>.from(item.product.bonus);
            if (event.bonusIndex < updatedBonus.length) {
              updatedBonus.removeAt(event.bonusIndex);
            }

            // Create updated product with removed bonus
            final updatedProduct = ProductEntity(
              id: item.product.id,
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
              kasur: item.product.kasur,
              divan: item.product.divan,
              headboard: item.product.headboard,
              sorong: item.product.sorong,
              ukuran: item.product.ukuran,
              pricelist: item.product.pricelist,
              program: item.product.program,
              eupKasur: item.product.eupKasur,
              eupDivan: item.product.eupDivan,
              eupHeadboard: item.product.eupHeadboard,
              endUserPrice: item.product.endUserPrice,
              bonus: updatedBonus,
              discounts: item.product.discounts,
              isSet: item.product.isSet,
              plKasur: item.product.plKasur,
              plDivan: item.product.plDivan,
              plHeadboard: item.product.plHeadboard,
              plSorong: item.product.plSorong,
              eupSorong: item.product.eupSorong,
              bottomPriceAnalyst: item.product.bottomPriceAnalyst,
              disc1: item.product.disc1,
              disc2: item.product.disc2,
              disc3: item.product.disc3,
              disc4: item.product.disc4,
              disc5: item.product.disc5,
              itemNumber: item.product.itemNumber,
              itemNumberKasur: item.product.itemNumberKasur,
              itemNumberDivan: item.product.itemNumberDivan,
              itemNumberHeadboard: item.product.itemNumberHeadboard,
              itemNumberSorong: item.product.itemNumberSorong,
              itemNumberAccessories: item.product.itemNumberAccessories,
              itemNumberBonus1: item.product.itemNumberBonus1,
              itemNumberBonus2: item.product.itemNumberBonus2,
              itemNumberBonus3: item.product.itemNumberBonus3,
              itemNumberBonus4: item.product.itemNumberBonus4,
              itemNumberBonus5: item.product.itemNumberBonus5,
            );

            return CartEntity(
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
            );
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<AddCartBonus>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Create updated bonus list with new bonus
            final updatedBonus = List<BonusItem>.from(item.product.bonus);
            updatedBonus.add(BonusItem(
              name: event.bonusName,
              quantity: event.bonusQuantity,
            ));

            // Create updated product with new bonus
            final updatedProduct = ProductEntity(
              id: item.product.id,
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
              kasur: item.product.kasur,
              divan: item.product.divan,
              headboard: item.product.headboard,
              sorong: item.product.sorong,
              ukuran: item.product.ukuran,
              pricelist: item.product.pricelist,
              program: item.product.program,
              eupKasur: item.product.eupKasur,
              eupDivan: item.product.eupDivan,
              eupHeadboard: item.product.eupHeadboard,
              endUserPrice: item.product.endUserPrice,
              bonus: updatedBonus,
              discounts: item.product.discounts,
              isSet: item.product.isSet,
              plKasur: item.product.plKasur,
              plDivan: item.product.plDivan,
              plHeadboard: item.product.plHeadboard,
              plSorong: item.product.plSorong,
              eupSorong: item.product.eupSorong,
              bottomPriceAnalyst: item.product.bottomPriceAnalyst,
              disc1: item.product.disc1,
              disc2: item.product.disc2,
              disc3: item.product.disc3,
              disc4: item.product.disc4,
              disc5: item.product.disc5,
              itemNumber: item.product.itemNumber,
              itemNumberKasur: item.product.itemNumberKasur,
              itemNumberDivan: item.product.itemNumberDivan,
              itemNumberHeadboard: item.product.itemNumberHeadboard,
              itemNumberSorong: item.product.itemNumberSorong,
              itemNumberAccessories: item.product.itemNumberAccessories,
              itemNumberBonus1: item.product.itemNumberBonus1,
              itemNumberBonus2: item.product.itemNumberBonus2,
              itemNumberBonus3: item.product.itemNumberBonus3,
              itemNumberBonus4: item.product.itemNumberBonus4,
              itemNumberBonus5: item.product.itemNumberBonus5,
            );

            return CartEntity(
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
            );
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<UpdateCartProductDetail>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Create updated product with new detail value
            final updatedProduct = ProductEntity(
              id: item.product.id,
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
              kasur: item.product.kasur,
              divan: event.detailType == 'divan'
                  ? event.detailValue
                  : item.product.divan,
              headboard: event.detailType == 'headboard'
                  ? event.detailValue
                  : item.product.headboard,
              sorong: event.detailType == 'sorong'
                  ? event.detailValue
                  : item.product.sorong,
              ukuran: item.product.ukuran,
              pricelist: item.product.pricelist,
              program: item.product.program,
              eupKasur: item.product.eupKasur,
              eupDivan: item.product.eupDivan,
              eupHeadboard: item.product.eupHeadboard,
              endUserPrice: item.product.endUserPrice,
              bonus: item.product.bonus,
              discounts: item.product.discounts,
              isSet: item.product.isSet,
              plKasur: item.product.plKasur,
              plDivan: item.product.plDivan,
              plHeadboard: item.product.plHeadboard,
              plSorong: item.product.plSorong,
              eupSorong: item.product.eupSorong,
              bottomPriceAnalyst: item.product.bottomPriceAnalyst,
              disc1: item.product.disc1,
              disc2: item.product.disc2,
              disc3: item.product.disc3,
              disc4: item.product.disc4,
              disc5: item.product.disc5,
              itemNumber: item.product.itemNumber,
              itemNumberKasur: item.product.itemNumberKasur,
              itemNumberDivan: item.product.itemNumberDivan,
              itemNumberHeadboard: item.product.itemNumberHeadboard,
              itemNumberSorong: item.product.itemNumberSorong,
              itemNumberAccessories: item.product.itemNumberAccessories,
              itemNumberBonus1: item.product.itemNumberBonus1,
              itemNumberBonus2: item.product.itemNumberBonus2,
              itemNumberBonus3: item.product.itemNumberBonus3,
              itemNumberBonus4: item.product.itemNumberBonus4,
              itemNumberBonus5: item.product.itemNumberBonus5,
            );

            return CartEntity(
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
            );
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
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
