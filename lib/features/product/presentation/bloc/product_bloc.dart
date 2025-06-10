import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/usecases/get_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProductUseCase;

  ProductBloc(this.getProductUseCase) : super(ProductInitial()) {
    on<AppStarted>((event, emit) {
      add(FetchProducts());
    });

    on<FetchProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        logger.i("📡 Fetching products from API on Product Bloc...");
        final products = await getProductUseCase();

        if (products.isEmpty) {
          logger.w("⚠️ Tidak ada produk yang ditemukan dari API.");
          emit(ProductError("Produk tidak ditemukan."));
          return;
        }

        final areas = products.map((e) => e.area).toSet().toList();
        emit(ProductState(products: products, availableAreas: areas));

        emit(ProductState(
          products: products,
          availableAreas: areas,
          availableKasurs: [],
          availableDivans: [],
          availableHeadboards: [],
          availableSorongs: [],
          selectedKasur: AppStrings.noKasur,
          selectedDivan: AppStrings.noDivan,
          selectedHeadboard: AppStrings.noHeadboard,
          selectedSorong: AppStrings.noSorong,
        ));

        logger.i("✅ Produk berhasil dimuat: ${products.length} items.");
      } catch (e) {
        logger.e("❌ Error fetching products: $e");
        emit(ProductError("Gagal mengambil data produk: ${e.toString()}"));
      }
    });

    on<ToggleSet>((event, emit) {
      final isSetActive = event.isSetActive;
      final filteredProducts = state.products
          .where((p) =>
              (state.selectedArea == null || p.area == state.selectedArea) &&
              (state.selectedChannel == null ||
                  p.channel == state.selectedChannel) &&
              (state.selectedBrand == null || p.brand == state.selectedBrand) &&
              (!isSetActive || p.isSet == true))
          .toList();

      final kasurs = filteredProducts.map((p) => p.kasur).toSet().toList()
        ..sort();
      final selectedKasur =
          kasurs.length == 1 ? kasurs.first : state.selectedKasur;

      final filteredByKasur =
          filteredProducts.where((p) => p.kasur == selectedKasur).toList();

      final divans = filteredByKasur.map((p) => p.divan).toSet().toList();
      final selectedDivan =
          divans.length == 1 ? divans.first : state.selectedDivan;

      final headboards =
          filteredByKasur.map((p) => p.headboard).toSet().toList();
      final selectedHeadboard =
          headboards.length == 1 ? headboards.first : state.selectedHeadboard;

      final sorongs = filteredByKasur.map((p) => p.sorong).toSet().toList();
      final selectedSorong =
          sorongs.length == 1 ? sorongs.first : state.selectedSorong;

      final sizes = filteredByKasur.map((p) => p.ukuran).toSet().toList();
      final selectedSize = sizes.length == 1 ? sizes.first : state.selectedSize;

      emit(state.copyWith(
        isSetActive: isSetActive,
        availableKasurs: kasurs,
        selectedKasur: selectedKasur,
        availableDivans: divans,
        selectedDivan: selectedDivan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: selectedSize,
      ));
    });

    on<UpdateSelectedArea>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == event.area && (!state.isSetActive || p.isSet == true))
          .toList();
      final channels = filteredProducts.map((p) => p.channel).toSet().toList();
      final selectedChannel = channels.length == 1 ? channels.first : "";

      emit(state.copyWith(
        selectedArea: event.area,
        availableChannels: channels,
        selectedChannel: selectedChannel,
        availableBrands: [],
        selectedBrand: "",
        availableKasurs: [],
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedChannel.isNotEmpty) {}
    });

    on<UpdateSelectedChannel>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == event.channel &&
              (!state.isSetActive || p.isSet == true))
          .toList();
      final brands = filteredProducts.map((p) => p.brand).toSet().toList();
      final selectedBrand = brands.length == 1 ? brands.first : "";

      emit(state.copyWith(
        selectedChannel: event.channel,
        availableBrands: brands,
        selectedBrand: selectedBrand,
        availableKasurs: [],
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedBrand.isNotEmpty) {
        add(UpdateSelectedBrand(selectedBrand));
      }
    });

    on<UpdateSelectedBrand>((event, emit) {
      logger.i("📌 Brand Changed: ${event.brand}");

      final filteredKasurs = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == event.brand)
          .map((p) => p.kasur)
          .toSet()
          .toList();

      final filteredDivans = state.products
          .where((p) => p.brand == event.brand)
          .map((p) => p.divan)
          .toSet()
          .toList();

      final filteredHeadboards = state.products
          .where((p) => p.brand == event.brand)
          .map((p) => p.headboard)
          .toSet()
          .toList();

      final filteredSorongs = state.products
          .where((p) => p.brand == event.brand)
          .map((p) => p.sorong)
          .toSet()
          .toList();

      emit(state.copyWith(
        selectedBrand: event.brand,
        availableKasurs: filteredKasurs,
        availableDivans: filteredDivans,
        availableHeadboards: filteredHeadboards,
        availableSorongs: filteredSorongs,
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
      ));
    });

    on<UpdateSelectedKasur>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == event.kasur &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();

      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();

      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      emit(state.copyWith(
        selectedKasur: event.kasur,
        availableDivans: divans,
        selectedDivan: divans.isNotEmpty ? divans.first : AppStrings.noDivan,
        availableHeadboards: headboards,
        selectedHeadboard:
            headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard,
        availableSorongs: sorongs,
        selectedSorong:
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong,
        availableSizes: sizes,
        selectedSize: "",
      ));
    });

    on<UpdateSelectedDivan>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == state.selectedKasur &&
              p.divan == event.divan &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();

      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();

      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard:
            headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard,
        availableSorongs: sorongs,
        selectedSorong:
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong,
      ));
    });

    on<UpdateSelectedHeadboard>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == state.selectedKasur &&
              p.divan == state.selectedDivan &&
              p.headboard == event.headboard &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();

      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: sorongs.isNotEmpty ? sorongs.first : "Tanpa Sorong",
      ));
    });

    on<UpdateSelectedSorong>((event, emit) {
      emit(state.copyWith(selectedSorong: event.sorong));
    });

    on<UpdateSelectedUkuran>((event, emit) {
      emit(state.copyWith(selectedSize: event.ukuran));
    });

    on<FilterProducts>((event, emit) {
      emit(state.copyWith(filteredProducts: event.filteredProducts));
    });

    on<ApplyFilters>((event, emit) {
      final filteredProducts = state.products.where((p) {
        final matchesArea = event.selectedArea == null ||
            event.selectedArea!.isEmpty ||
            p.area == event.selectedArea;
        final matchesChannel = event.selectedChannel == null ||
            event.selectedChannel!.isEmpty ||
            p.channel == event.selectedChannel;
        final matchesBrand = event.selectedBrand == null ||
            event.selectedBrand!.isEmpty ||
            p.brand == event.selectedBrand;
        final matchesKasur = event.selectedKasur == null ||
            event.selectedKasur!.isEmpty ||
            p.kasur == event.selectedKasur;
        final matchesDivan = event.selectedDivan == null ||
            event.selectedDivan!.isEmpty ||
            p.divan == event.selectedDivan;
        final matchesHeadboard = event.selectedHeadboard == null ||
            event.selectedHeadboard!.isEmpty ||
            p.headboard == event.selectedHeadboard;
        final matchesSorong = event.selectedSorong == null ||
            event.selectedSorong!.isEmpty ||
            p.sorong == event.selectedSorong;
        final matchesSize = event.selectedSize == null ||
            event.selectedSize!.isEmpty ||
            p.ukuran == event.selectedSize;

        final matchesSet = !state.isSetActive || p.isSet == true;

        return matchesArea &&
            matchesChannel &&
            matchesBrand &&
            matchesKasur &&
            matchesDivan &&
            matchesHeadboard &&
            matchesSorong &&
            matchesSize &&
            matchesSet;
      }).toList();

      logger.i("🔍 Filtered Products Count: ${filteredProducts.length}");

      emit(state.copyWith(
          filteredProducts: filteredProducts, isFilterApplied: true));

      if (filteredProducts.isNotEmpty) {
        CustomToast.showToast(
          "Berikut adalah produk yang cocok.",
          ToastType.success,
        );
      }

      if (filteredProducts.isEmpty) {
        CustomToast.showToast(
          "Produk tidak ditemukan.",
          ToastType.error,
        );
      }
    });

    on<SelectProduct>((event, emit) {
      emit(state.copyWith(selectProduct: event.product));
    });

    on<SaveInstallment>((event, emit) {
      final updatedInstallmentMonths =
          Map<int, int>.from(state.installmentMonths)
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
    });

    on<RemoveInstallment>((event, emit) {
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
    });

    on<UpdateRoundedPrice>((event, emit) {
      final updatedPrices = Map<int, double>.from(state.roundedPrices)
        ..[event.productId] = event.newPrice;

      final updatedPercentages =
          Map<int, double>.from(state.priceChangePercentages);
      final updatedDiscounts =
          Map<int, List<double>>.from(state.productDiscountsPercentage);

      updatedPercentages[event.productId] = event.percentageChange;

      if (updatedDiscounts.containsKey(event.productId)) {
        updatedDiscounts[event.productId]?.removeWhere(
            (d) => d == state.priceChangePercentages[event.productId]);
      }

      emit(state.copyWith(
        roundedPrices: updatedPrices,
        priceChangePercentages: updatedPercentages,
        productDiscountsPercentage: updatedDiscounts,
      ));

      if (event.percentageChange != 0.0) {
        CustomToast.showToast(
          "Harga berhasil diubah dan diskon diperbarui.",
          ToastType.success,
        );
      }
    });

    on<UpdateProductDiscounts>((event, emit) {
      final currentState = state;

      Map<int, List<double>> updatedDiscountsPercentage =
          Map.from(currentState.productDiscountsPercentage);
      Map<int, List<double>> updatedDiscountsNominal =
          Map.from(currentState.productDiscountsNominal);
      Map<int, double> updatedRoundedPrices =
          Map.from(currentState.roundedPrices);

      updatedDiscountsPercentage[event.productId] =
          List.from(event.discountPercentages);
      updatedDiscountsNominal[event.productId] =
          List.from(event.discountNominals);

      double basePrice =
          currentState.roundedPrices[event.productId] ?? event.originalPrice;
      for (var discount in event.discountNominals) {
        basePrice -= discount;
      }
      basePrice = basePrice.clamp(0, event.originalPrice);
      updatedRoundedPrices[event.productId] = basePrice;

      emit(currentState.copyWith(
        roundedPrices: updatedRoundedPrices,
        productDiscountsPercentage: updatedDiscountsPercentage,
        productDiscountsNominal: updatedDiscountsNominal,
      ));

      CustomToast.showToast(
        "Diskon berhasil diterapkan.",
        ToastType.success,
      );
    });

    on<ResetProductState>((event, emit) {
      logger.i("🔄 Resetting Product State...");
      emit(ProductState());
    });

    on<SaveProductNote>((event, emit) {
      final updatedNotes = Map<int, String>.from(state.productNotes)
        ..[event.productId] = event.note;
      emit(state.copyWith(productNotes: updatedNotes));
    });

    on<UpdateProductNote>((event, emit) {
      final updatedNotes = Map<int, String>.from(state.productNotes);
      updatedNotes[event.productId] = event.note;
      emit(state.copyWith(productNotes: updatedNotes));
    });
  }
}
