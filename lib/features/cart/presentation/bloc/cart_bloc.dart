import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/cart_storage_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../product/domain/usecases/get_product_usecase.dart';
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
      print('=== ADD TO CART EVENT ===');
      print('Product: ${event.product.kasur} ${event.product.ukuran}');
      print('Quantity: ${event.quantity}');
      print('Net Price: ${event.netPrice}');

      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        print(
            'Current cart items before add: ${currentState.cartItems.length}');

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
          print('Updating existing item at index $existingItemIndex');
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
          print('Adding new item to cart');
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

        print('Cart items after add: ${updatedItems.length}');

        // Save to storage and emit new state
        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
        print('Cart state updated successfully');
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

    on<UpdateBonusTakeAway>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            return item.copyWith(bonusTakeAway: event.bonusTakeAway);
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<RemoveSelectedItems>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        // Remove specific items from cart
        final updatedItems = currentState.cartItems.where((item) {
          return !event.itemsToRemove.any((removeItem) =>
              removeItem.product.id == item.product.id &&
              removeItem.netPrice == item.netPrice);
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
                // Get original bonus to preserve originalQuantity and apply max limit
                final originalBonus = updatedBonus[event.bonusIndex];
                final maxQuantity = originalBonus.maxQuantity;
                final finalQuantity = event.bonusQuantity > maxQuantity
                    ? maxQuantity
                    : event.bonusQuantity;

                // Update bonus with new quantity (limited to max)
                updatedBonus[event.bonusIndex] = BonusItem(
                  name: event.bonusName,
                  quantity: finalQuantity,
                  originalQuantity: originalBonus.originalQuantity,
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
              originalQuantity:
                  event.bonusQuantity, // Set original quantity for new bonus
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
        final getProductUseCase = locator<GetProductUseCase>();

        final List<CartEntity> updatedItems = [];

        for (final item in currentState.cartItems) {
          if (item.product.id == event.productId &&
              item.netPrice == event.netPrice) {
            // Update selected detail on current product
            final String newDivan = event.detailType == 'divan'
                ? event.detailValue
                : item.product.divan;
            final String newHeadboard = event.detailType == 'headboard'
                ? event.detailValue
                : item.product.headboard;
            final String newSorong = event.detailType == 'sorong'
                ? event.detailValue
                : item.product.sorong;
            final String newUkuran = event.detailType == 'ukuran'
                ? event.detailValue
                : item.product.ukuran;

            // Fetch products with same filters to find the exact variant
            try {
              final products = await getProductUseCase.callWithFilter(
                area: item.product.area,
                channel: item.product.channel,
                brand: item.product.brand,
              );

              // Try to find a matching variant
              final matched = products.firstWhere(
                (p) =>
                    (p.kasur == item.product.kasur) &&
                    (p.divan == newDivan) &&
                    (p.headboard == newHeadboard) &&
                    (p.sorong == newSorong) &&
                    (p.ukuran == newUkuran),
                orElse: () => item.product,
              );

              // Base price is endUserPrice of matched product
              final double basePrice = matched.endUserPrice;
              final double recalculatedNet = _applyDiscountsSequentially(
                  basePrice, item.discountPercentages);

              // Build updated product entity using matched details
              final updatedProduct = ProductEntity(
                id: item.product.id,
                area: matched.area,
                channel: matched.channel,
                brand: matched.brand,
                kasur: matched.kasur,
                divan: newDivan,
                headboard: newHeadboard,
                sorong: newSorong,
                ukuran: newUkuran,
                pricelist: matched.pricelist,
                program: matched.program,
                eupKasur: matched.eupKasur,
                eupDivan: matched.eupDivan,
                eupHeadboard: matched.eupHeadboard,
                endUserPrice: matched.endUserPrice,
                bonus: item.product.bonus,
                discounts: matched.discounts,
                isSet: matched.isSet,
                plKasur: matched.plKasur,
                plDivan: matched.plDivan,
                plHeadboard: matched.plHeadboard,
                plSorong: matched.plSorong,
                eupSorong: matched.eupSorong,
                bottomPriceAnalyst: matched.bottomPriceAnalyst,
                disc1: matched.disc1,
                disc2: matched.disc2,
                disc3: matched.disc3,
                disc4: matched.disc4,
                disc5: matched.disc5,
                itemNumber: matched.itemNumber,
                itemNumberKasur: matched.itemNumberKasur,
                itemNumberDivan: matched.itemNumberDivan,
                itemNumberHeadboard: matched.itemNumberHeadboard,
                itemNumberSorong: matched.itemNumberSorong,
                itemNumberAccessories: matched.itemNumberAccessories,
                itemNumberBonus1: matched.itemNumberBonus1,
                itemNumberBonus2: matched.itemNumberBonus2,
                itemNumberBonus3: matched.itemNumberBonus3,
                itemNumberBonus4: matched.itemNumberBonus4,
                itemNumberBonus5: matched.itemNumberBonus5,
              );

              updatedItems.add(CartEntity(
                product: updatedProduct,
                quantity: item.quantity,
                netPrice: recalculatedNet,
                discountPercentages: item.discountPercentages,
                installmentMonths: item.installmentMonths,
                installmentPerMonth: item.installmentPerMonth,
                isSelected: item.isSelected,
              ));
            } catch (e) {
              // If matching fails, keep original but update the selected field
              final updatedProduct = ProductEntity(
                id: item.product.id,
                area: item.product.area,
                channel: item.product.channel,
                brand: item.product.brand,
                kasur: item.product.kasur,
                divan: newDivan,
                headboard: newHeadboard,
                sorong: newSorong,
                ukuran: newUkuran,
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

              // Recalculate net from current endUserPrice
              final double basePrice = updatedProduct.endUserPrice;
              final double recalculatedNet = _applyDiscountsSequentially(
                  basePrice, item.discountPercentages);

              updatedItems.add(CartEntity(
                product: updatedProduct,
                quantity: item.quantity,
                netPrice: recalculatedNet,
                discountPercentages: item.discountPercentages,
                installmentMonths: item.installmentMonths,
                installmentPerMonth: item.installmentPerMonth,
                isSelected: item.isSelected,
              ));
            }
          } else {
            updatedItems.add(item);
          }
        }

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<UpdateCartPrice>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.oldNetPrice) {
            return CartEntity(
              product: item.product,
              quantity: item.quantity,
              netPrice: event.newNetPrice,
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

    on<UpdateCartDiscounts>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (item.product.id == event.productId &&
              item.netPrice == event.oldNetPrice) {
            return CartEntity(
              product: item.product,
              quantity: item.quantity,
              netPrice: event.newNetPrice,
              discountPercentages: event.discountPercentages,
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

  // Apply percentage discounts sequentially to a base price
  double _applyDiscountsSequentially(
      double basePrice, List<double> discountPercentages) {
    double price = basePrice;
    for (final percent in discountPercentages) {
      if (percent <= 0) continue;
      price = price * (1 - (percent / 100.0));
    }
    // Ensure not negative and round to 2 decimals if needed
    if (price < 0) price = 0;
    return price;
  }
}
