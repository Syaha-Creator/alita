import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/custom_toast.dart';
import '../helpers/product_price_calculator.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

/// Mixin untuk menangani semua price-related event handlers
///
/// Handlers yang ditangani:
/// - SaveInstallment: Menyimpan data cicilan
/// - RemoveInstallment: Menghapus data cicilan
/// - UpdateRoundedPrice: Update harga produk dengan auto-split diskon
/// - UpdateProductDiscounts: Update diskon produk
mixin ProductPriceMixin on Bloc<ProductEvent, ProductState> {
  /// Register semua price-related event handlers
  void registerPriceHandlers() {
    on<SaveInstallment>(_onSaveInstallment);
    on<RemoveInstallment>(_onRemoveInstallment);
    on<UpdateRoundedPrice>(_onUpdateRoundedPrice);
    on<UpdateProductDiscounts>(_onUpdateProductDiscounts);
  }

  /// Handler untuk menyimpan data cicilan
  void _onSaveInstallment(
    SaveInstallment event,
    Emitter<ProductState> emit,
  ) {
    final updatedInstallmentMonths = Map<int, int>.from(state.installmentMonths)
      ..[event.productId] = event.months;
    final updatedInstallmentPerMonth =
        Map<int, double>.from(state.installmentPerMonth)
          ..[event.productId] = event.perMonth;

    emit(state.copyWith(
      installmentMonths: updatedInstallmentMonths,
      installmentPerMonth: updatedInstallmentPerMonth,
    ));

    CustomToast.showToast(
      "Cicilan berhasil disimpan.",
      ToastType.success,
    );
  }

  /// Handler untuk menghapus data cicilan
  void _onRemoveInstallment(
    RemoveInstallment event,
    Emitter<ProductState> emit,
  ) {
    final updatedInstallmentMonths =
        Map<int, int>.from(state.installmentMonths);
    final updatedInstallmentPerMonth =
        Map<int, double>.from(state.installmentPerMonth);

    updatedInstallmentMonths.remove(event.productId);
    updatedInstallmentPerMonth.remove(event.productId);

    emit(state.copyWith(
      installmentMonths: updatedInstallmentMonths,
      installmentPerMonth: updatedInstallmentPerMonth,
    ));

    CustomToast.showToast(
      "Cicilan berhasil dihapus.",
      ToastType.success,
    );
  }

  /// Handler untuk update harga produk dengan auto-split diskon bertingkat
  void _onUpdateRoundedPrice(
    UpdateRoundedPrice event,
    Emitter<ProductState> emit,
  ) {
    final updatedPrices = Map<int, double>.from(state.roundedPrices)
      ..[event.productId] = event.newPrice;

    final updatedPercentages =
        Map<int, double>.from(state.priceChangePercentages);
    final updatedDiscounts =
        Map<int, List<double>>.from(state.productDiscountsPercentage);

    updatedPercentages[event.productId] = event.percentageChange;

    // --- LOGIC: AUTO SPLIT DISKON BERTINGKAT ---
    // Logic dipindahkan ke ProductPriceCalculator untuk maintainability
    final product = state.products.firstWhere(
      (p) => p.id == event.productId,
      orElse: () {
        // If product not found in products list, try to use selectProduct
        if (state.selectProduct != null &&
            state.selectProduct!.id == event.productId) {
          return state.selectProduct!;
        }
        // If still not found, throw an exception to prevent crashes
        throw Exception('Product with ID ${event.productId} not found');
      },
    );

    final splitDiscounts = ProductPriceCalculator.calculateSplitDiscounts(
      product,
      event.newPrice,
    );

    updatedDiscounts[event.productId] = splitDiscounts['discounts']!;
    final updatedNominals =
        Map<int, List<double>>.from(state.productDiscountsNominal);
    updatedNominals[event.productId] = splitDiscounts['nominals']!;
    // --- END LOGIC ---

    emit(state.copyWith(
      roundedPrices: updatedPrices,
      priceChangePercentages: updatedPercentages,
      productDiscountsPercentage: updatedDiscounts,
      productDiscountsNominal: updatedNominals,
    ));

    if (event.percentageChange != 0.0) {
      CustomToast.showToast(
        "Harga berhasil diubah dan diskon diperbarui.",
        ToastType.success,
      );
    }
  }

  /// Handler untuk update diskon produk
  void _onUpdateProductDiscounts(
    UpdateProductDiscounts event,
    Emitter<ProductState> emit,
  ) {
    final currentState = state;

    Map<int, List<double>> updatedDiscountsPercentage =
        Map.from(currentState.productDiscountsPercentage);
    Map<int, List<double>> updatedDiscountsNominal =
        Map.from(currentState.productDiscountsNominal);
    Map<int, double> updatedRoundedPrices =
        Map.from(currentState.roundedPrices);
    Map<int, List<int?>> updatedLeaderIds =
        Map.from(currentState.productLeaderIds);

    Map<int, double> updatedPriceChangePercentages =
        Map.from(currentState.priceChangePercentages);
    updatedPriceChangePercentages.remove(event.productId);

    updatedDiscountsPercentage[event.productId] =
        List.from(event.discountPercentages);
    updatedDiscountsNominal[event.productId] =
        List.from(event.discountNominals);

    if (event.leaderIds != null) {
      updatedLeaderIds[event.productId] = List.from(event.leaderIds!);
    }

    // Calculate final price using helper
    final finalPrice = ProductPriceCalculator.calculateFinalPrice(
      event.originalPrice,
      event.discountPercentages,
    );
    updatedRoundedPrices[event.productId] = finalPrice;

    emit(currentState.copyWith(
      roundedPrices: updatedRoundedPrices,
      productDiscountsPercentage: updatedDiscountsPercentage,
      productDiscountsNominal: updatedDiscountsNominal,
      productLeaderIds: updatedLeaderIds,
      priceChangePercentages: updatedPriceChangePercentages,
    ));

    CustomToast.showToast(
      "Diskon berhasil diterapkan.",
      ToastType.success,
    );
  }
}
