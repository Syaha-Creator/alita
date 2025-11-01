import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/cart_storage_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../config/dependency_injection.dart';
import '../../../product/domain/usecases/get_product_usecase.dart';
import '../../domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../domain/usecases/apply_discounts_usecase.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final ApplyDiscountsUsecase _applyDiscountsUsecase;

  CartBloc({ApplyDiscountsUsecase? applyDiscountsUsecase})
      : _applyDiscountsUsecase =
            applyDiscountsUsecase ?? const ApplyDiscountsUsecase(),
        super(CartLoaded([])) {
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
            cartLineId: existingItem.cartLineId,
            product: existingItem.product,
            quantity: existingItem.quantity + event.quantity,
            netPrice: existingItem.netPrice,
            discountPercentages: existingItem.discountPercentages,
            installmentMonths: existingItem.installmentMonths,
            installmentPerMonth: existingItem.installmentPerMonth,
            isSelected: existingItem.isSelected,
            bonusTakeAway: existingItem.bonusTakeAway,
            selectedItemNumbers: existingItem.selectedItemNumbers,
            selectedItemNumbersPerUnit: existingItem.selectedItemNumbersPerUnit,
          );
        } else {
          final normalizedProduct = _withNormalizedBonusOriginal(event.product);
          updatedItems.add(
            CartEntity(
              cartLineId: _generateCartLineId(),
              product: normalizedProduct,
              quantity: event.quantity,
              netPrice: event.netPrice,
              discountPercentages: event.discountPercentages,
              installmentMonths: event.installmentMonths,
              installmentPerMonth: event.installmentPerMonth,
              isSelected: true,
              bonusTakeAway: null,
              selectedItemNumbers: null,
              selectedItemNumbersPerUnit: null,
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
            cartLineId: _generateCartLineId(),
            product: event.product,
            quantity: event.quantity,
            netPrice: event.netPrice,
            discountPercentages: event.discountPercentages,
            installmentMonths: event.installmentMonths,
            installmentPerMonth: event.installmentPerMonth,
            isSelected: true,
            bonusTakeAway: null,
            selectedItemNumbers: null,
            selectedItemNumbersPerUnit: null,
          )
        ];

        await CartStorageService.saveCartItems(newCart);
        emit(CartLoaded(newCart));
      }
    });

    on<RemoveFromCart>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        // Find the index of the item to remove
        final itemIndex = currentState.cartItems.indexWhere((item) =>
            _matchesLine(item,
                cartLineId: event.cartLineId,
                productId: event.productId,
                netPrice: event.netPrice));

        if (itemIndex != -1) {
          // Remove the specific item by index
          final updatedItems = List<CartEntity>.from(currentState.cartItems);
          updatedItems.removeAt(itemIndex);

          await CartStorageService.saveCartItems(updatedItems);
          emit(CartLoaded(updatedItems));
        }
      }
    });

    // Save user-selected item number (fabric selection) per component
    on<UpdateCartSelectedItemNumber>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
            if (event.unitIndex != null) {
              // Per-unit selection
              final perUnit = Map<String, List<Map<String, String>>>.from(
                  item.selectedItemNumbersPerUnit ?? {});
              final list =
                  List<Map<String, String>>.from(perUnit[event.itemType] ?? []);
              // Ensure list has length up to quantity
              while (list.length < item.quantity) {
                list.add({});
              }
              final idx = event.unitIndex!.clamp(0, item.quantity - 1);
              list[idx] = {
                'item_number': event.itemNumber,
                if (event.jenisKain != null) 'jenis_kain': event.jenisKain!,
                if (event.warnaKain != null) 'warna_kain': event.warnaKain!,
              };
              perUnit[event.itemType] = list;
              return item.copyWith(selectedItemNumbersPerUnit: perUnit);
            } else {
              // Legacy per-component selection
              final currentSelections = Map<String, Map<String, String>>.from(
                  item.selectedItemNumbers ?? {});
              currentSelections[event.itemType] = {
                'item_number': event.itemNumber,
                if (event.jenisKain != null) 'jenis_kain': event.jenisKain!,
                if (event.warnaKain != null) 'warna_kain': event.warnaKain!,
              };
              return item.copyWith(selectedItemNumbers: currentSelections);
            }
          }
          return item;
        }).toList();

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    on<UpdateCartQuantity>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
            // Update bonus quantities to match new product quantity
            final updatedBonus = item.product.bonus.map((bonus) {
              // bonus.originalQuantity = bonus per 1 product
              // maxQuantity = originalQuantity * productQuantity
              // Calculate new max quantity based on new product quantity
              final perUnit = bonus.originalQuantity > 0
                  ? bonus.originalQuantity
                  : bonus.quantity;
              final newMaxQuantity = perUnit * 2 * event.quantity;

              // Scale bonus quantity proportionally
              // Example: if product qty changes from 2→3, bonus qty should scale too
              final scaleFactor = event.quantity / item.quantity.toDouble();
              final scaledQuantity = (bonus.quantity * scaleFactor).round();

              // Ensure bonus quantity doesn't exceed new max
              final finalQuantity = scaledQuantity.clamp(1, newMaxQuantity);

              return BonusItem(
                name: bonus.name,
                quantity: finalQuantity,
                originalQuantity: bonus.originalQuantity,
                takeAway: bonus.takeAway,
              );
            }).toList();

            // Create updated product with new bonus quantities
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
              cartLineId: item.cartLineId,
              product: updatedProduct,
              quantity: event.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
              bonusTakeAway: item.bonusTakeAway,
              selectedItemNumbers: item.selectedItemNumbers,
              selectedItemNumbersPerUnit: item.selectedItemNumbersPerUnit,
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
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
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
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
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
          return !event.itemsToRemove
              .any((removeItem) => removeItem.cartLineId == item.cartLineId);
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

    on<ClearDraftsAfterCheckout>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final userId = await AuthService.getCurrentUserId();
        if (userId != null) {
          final key = 'checkout_drafts_$userId';
          await prefs.remove(key);
        }
      } catch (e) {
        // Silent fail
      }
    });

    on<ReloadCartForUser>((event, emit) async {
      add(LoadCart());
    });

    on<UpdateCartBonus>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final updatedItems = currentState.cartItems.map((item) {
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
            // Create updated bonus list
            final updatedBonus = List<BonusItem>.from(item.product.bonus);
            if (event.bonusIndex < updatedBonus.length) {
              if (event.bonusQuantity <= 0) {
                // Remove bonus if quantity is 0 or less
                updatedBonus.removeAt(event.bonusIndex);
              } else {
                // Get original bonus to preserve originalQuantity and apply max limit
                final originalBonus = updatedBonus[event.bonusIndex];
                final perUnit = originalBonus.originalQuantity > 0
                    ? originalBonus.originalQuantity
                    : originalBonus.quantity;
                final maxQuantity = perUnit * 2 * item.quantity;
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
              cartLineId: item.cartLineId,
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
              bonusTakeAway: item.bonusTakeAway,
              selectedItemNumbers: item.selectedItemNumbers,
              selectedItemNumbersPerUnit: item.selectedItemNumbersPerUnit,
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
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
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
              cartLineId: item.cartLineId,
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: item.netPrice,
              discountPercentages: item.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
              bonusTakeAway: item.bonusTakeAway,
              selectedItemNumbers: item.selectedItemNumbers,
              selectedItemNumbersPerUnit: item.selectedItemNumbersPerUnit,
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
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
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
              cartLineId: item.cartLineId,
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
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.netPrice)) {
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
              final double recalculatedNet = _applyDiscountsUsecase
                  .applySequentially(basePrice, item.discountPercentages);

              // Determine default bonus sets (old vs new)
              final currentDefault = products.firstWhere(
                (p) =>
                    (p.kasur == item.product.kasur) &&
                    (p.divan == item.product.divan) &&
                    (p.headboard == item.product.headboard) &&
                    (p.sorong == item.product.sorong) &&
                    (p.ukuran == item.product.ukuran),
                orElse: () => item.product,
              );

              final mergedBonus = _mergeBonusWithDefaults(
                currentDefault,
                matched,
                item.product.bonus,
                item.quantity,
              );

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
                bonus: mergedBonus,
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
                cartLineId: item.cartLineId,
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
              final double recalculatedNet = _applyDiscountsUsecase
                  .applySequentially(basePrice, item.discountPercentages);

              updatedItems.add(CartEntity(
                cartLineId: item.cartLineId,
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
        final getProductUseCase = locator<GetProductUseCase>();
        final List<CartEntity> updatedItems = [];
        for (final item in currentState.cartItems) {
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.oldNetPrice)) {
            // Rebuild bonus with default mapping logic
            final products = await getProductUseCase.callWithFilter(
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
            );

            final currentDefault = products.firstWhere(
              (p) =>
                  (p.kasur == item.product.kasur) &&
                  (p.divan == item.product.divan) &&
                  (p.headboard == item.product.headboard) &&
                  (p.sorong == item.product.sorong) &&
                  (p.ukuran == item.product.ukuran),
              orElse: () => item.product,
            );

            final updatedBonus = _mergeBonusWithDefaults(
              currentDefault,
              item.product, // price changed but detail may be same; keep as new default
              item.product.bonus,
              item.quantity,
            );

            // Create updated product with new bonus quantities
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
            // Derive effective discount per level if none set yet
            List<double> derivedDiscounts = item.discountPercentages;
            final bool hasAnyDiscount = derivedDiscounts.any((d) => d > 0.0);
            if (!hasAnyDiscount) {
              final base = item.product.endUserPrice;
              if (base > 0 && event.newNetPrice >= 0) {
                final eff = (1 - (event.newNetPrice / base)) * 100.0; // percent
                if (eff > 0 && eff < 1000) {
                  derivedDiscounts = _splitAcrossLevels(
                    eff,
                    item.product.disc1,
                    item.product.disc2,
                    item.product.disc3,
                    item.product.disc4,
                    item.product.disc5,
                  );
                }
              }
            }

            updatedItems.add(CartEntity(
              cartLineId: item.cartLineId,
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: event.newNetPrice,
              discountPercentages: derivedDiscounts,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
            ));
          } else {
            updatedItems.add(item);
          }
        }

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));

        // Sync ProductBloc rounded price for UI discount panels
        try {
          final productBloc = locator<ProductBloc>();
          productBloc
              .add(UpdateRoundedPrice(event.productId, event.newNetPrice, 0));
        } catch (_) {}
      }
    });

    on<UpdateCartDiscounts>((event, emit) async {
      if (state is CartLoaded) {
        final currentState = state as CartLoaded;
        final getProductUseCase = locator<GetProductUseCase>();
        final List<CartEntity> updatedItems = [];
        for (final item in currentState.cartItems) {
          if (_matchesLine(item,
              cartLineId: event.cartLineId,
              productId: event.productId,
              netPrice: event.oldNetPrice)) {
            final products = await getProductUseCase.callWithFilter(
              area: item.product.area,
              channel: item.product.channel,
              brand: item.product.brand,
            );
            final currentDefault = products.firstWhere(
              (p) =>
                  (p.kasur == item.product.kasur) &&
                  (p.divan == item.product.divan) &&
                  (p.headboard == item.product.headboard) &&
                  (p.sorong == item.product.sorong) &&
                  (p.ukuran == item.product.ukuran),
              orElse: () => item.product,
            );
            final updatedBonus = _mergeBonusWithDefaults(
              currentDefault,
              item.product,
              item.product.bonus,
              item.quantity,
            );

            // Create updated product with new bonus quantities
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

            // Recalculate net from EUP (endUserPrice) using new discount percentages
            final double recalculatedNet =
                _applyDiscountsUsecase.applySequentially(
                    item.product.endUserPrice, event.discountPercentages);

            updatedItems.add(CartEntity(
              cartLineId: item.cartLineId,
              product: updatedProduct,
              quantity: item.quantity,
              netPrice: recalculatedNet,
              discountPercentages: event.discountPercentages,
              installmentMonths: item.installmentMonths,
              installmentPerMonth: item.installmentPerMonth,
              isSelected: item.isSelected,
              bonusTakeAway: item.bonusTakeAway,
              selectedItemNumbers: item.selectedItemNumbers,
              selectedItemNumbersPerUnit: item.selectedItemNumbersPerUnit,
            ));
          } else {
            updatedItems.add(item);
          }
        }

        await CartStorageService.saveCartItems(updatedItems);
        emit(CartLoaded(updatedItems));
      }
    });

    // Auto-load cart when bloc is created
    add(LoadCart());
  }

  String _generateCartLineId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  bool _matchesLine(CartEntity item,
      {String? cartLineId, int? productId, double? netPrice}) {
    if (cartLineId != null && cartLineId.isNotEmpty) {
      return item.cartLineId == cartLineId;
    }
    if (productId == null || netPrice == null) return false;
    // Fallback to legacy matching with small epsilon for netPrice
    const double eps = 0.5; // 50 cents tolerance
    return item.product.id == productId &&
        (item.netPrice - netPrice).abs() < eps;
  }

  // Split an effective discount (percent) into up to 5 levels respecting max per level
  // discX parameters are fractions (e.g., 0.1 for 10%), convert to percent caps
  List<double> _splitAcrossLevels(double effPercent, double disc1, double disc2,
      double disc3, double disc4, double disc5) {
    final caps = [disc1, disc2, disc3, disc4, disc5]
        .map((d) => (d > 0 ? d * 100.0 : 0.0))
        .toList();
    final result = List<double>.filled(5, 0.0);
    double remaining = effPercent;
    for (int i = 0; i < 5; i++) {
      if (remaining <= 0) break;
      final cap = caps[i];
      if (cap <= 0) continue;
      final take = remaining > cap ? cap : remaining;
      result[i] = take;
      remaining -= take;
    }
    // Trim trailing zeros
    while (result.isNotEmpty && result.last <= 0) {
      result.removeLast();
    }
    return result.isEmpty ? [effPercent] : result;
  }

  /// Ensure each bonus has originalQuantity set; fallback to its default quantity if missing
  ProductEntity _withNormalizedBonusOriginal(ProductEntity product) {
    final normalizedBonus = product.bonus
        .map((b) => BonusItem(
              name: b.name,
              quantity: b.quantity,
              originalQuantity:
                  b.originalQuantity > 0 ? b.originalQuantity : b.quantity,
              takeAway: b.takeAway,
            ))
        .toList();

    return ProductEntity(
      id: product.id,
      area: product.area,
      channel: product.channel,
      brand: product.brand,
      kasur: product.kasur,
      divan: product.divan,
      headboard: product.headboard,
      sorong: product.sorong,
      ukuran: product.ukuran,
      pricelist: product.pricelist,
      program: product.program,
      eupKasur: product.eupKasur,
      eupDivan: product.eupDivan,
      eupHeadboard: product.eupHeadboard,
      endUserPrice: product.endUserPrice,
      bonus: normalizedBonus,
      discounts: product.discounts,
      isSet: product.isSet,
      plKasur: product.plKasur,
      plDivan: product.plDivan,
      plHeadboard: product.plHeadboard,
      plSorong: product.plSorong,
      eupSorong: product.eupSorong,
      bottomPriceAnalyst: product.bottomPriceAnalyst,
      disc1: product.disc1,
      disc2: product.disc2,
      disc3: product.disc3,
      disc4: product.disc4,
      disc5: product.disc5,
      itemNumber: product.itemNumber,
      itemNumberKasur: product.itemNumberKasur,
      itemNumberDivan: product.itemNumberDivan,
      itemNumberHeadboard: product.itemNumberHeadboard,
      itemNumberSorong: product.itemNumberSorong,
      itemNumberAccessories: product.itemNumberAccessories,
      itemNumberBonus1: product.itemNumberBonus1,
      itemNumberBonus2: product.itemNumberBonus2,
      itemNumberBonus3: product.itemNumberBonus3,
      itemNumberBonus4: product.itemNumberBonus4,
      itemNumberBonus5: product.itemNumberBonus5,
    );
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<BonusItem> _mergeBonusWithDefaults(
    ProductEntity oldDefault,
    ProductEntity newDefault,
    List<BonusItem> current,
    int productQuantity,
  ) {
    final int maxLen = newDefault.bonus.length;
    final bool allUntouched =
        _areAllBonusNamesUntouched(oldDefault.bonus, current);

    final List<BonusItem> result = [];
    for (int i = 0; i < maxLen; i++) {
      final BonusItem newDef = newDefault.bonus.length > i
          ? newDefault.bonus[i]
          : BonusItem(name: '', quantity: 1, originalQuantity: 1);
      final BonusItem oldDef = oldDefault.bonus.length > i
          ? oldDefault.bonus[i]
          : BonusItem(name: '', quantity: 1, originalQuantity: 1);
      final BonusItem currentItem = current.length > i
          ? current[i]
          : BonusItem(name: '', quantity: 1, originalQuantity: 1);

      final bool untouchedAtIndex = currentItem.name == oldDef.name;
      final String finalName =
          (allUntouched || untouchedAtIndex) ? newDef.name : currentItem.name;

      final int dynamicQty = (newDef.originalQuantity > 0)
          ? newDef.originalQuantity * productQuantity
          : currentItem.quantity;

      result.add(BonusItem(
        name: finalName,
        quantity: dynamicQty,
        originalQuantity: newDef.originalQuantity,
        takeAway: currentItem.takeAway,
      ));
    }
    return result;
  }

  bool _areAllBonusNamesUntouched(
      List<BonusItem> defaults, List<BonusItem> current) {
    final int len = defaults.length;
    for (int i = 0; i < len; i++) {
      final String defName = defaults.length > i ? defaults[i].name : '';
      final String curName = current.length > i ? current[i].name : '';
      if (defName != curName) return false;
    }
    return true;
  }
}
