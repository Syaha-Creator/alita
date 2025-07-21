import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../domain/usecases/get_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProductUseCase;

  ProductBloc(this.getProductUseCase) : super(ProductInitial()) {
    on<AppStarted>((event, emit) {
      // Don't fetch products automatically - wait for user to select filters
      add(InitializeDropdowns());
    });

    on<InitializeDropdowns>((event, emit) async {
      try {
        // Get user area_id from AuthService
        final userAreaId = await AuthService.getCurrentUserAreaId();

        // Initialize with empty state and user area if available
        if (userAreaId != null) {
          AreaEnum? userAreaEnum = _getAreaEnumFromId(userAreaId);
          if (userAreaEnum != null) {
            emit(ProductState(
              userAreaId: userAreaId,
              selectedArea: userAreaEnum.value,
              selectedAreaEnum: userAreaEnum,
              isUserAreaSet: true,
              filteredProducts: [],
              isFilterApplied: false,
              availableChannels:
                  ChannelEnum.values.map((e) => e.value).toList(),
              availableChannelEnums: ChannelEnum.values.toList(),
              availableBrands: [],
              availableBrandEnums: [],
              availableKasurs: [],
              availableDivans: [],
              availableHeadboards: [],
              availableSorongs: [],
              availableSizes: [],
              selectedKasur: AppStrings.noKasur, // Default value
              selectedDivan: AppStrings.noDivan, // Default value
              selectedHeadboard: AppStrings.noHeadboard, // Default value
              selectedSorong: AppStrings.noSorong, // Default value
              selectedSize: "", // Default value
            ));
          } else {
            emit(ProductState(
              userAreaId: userAreaId,
              areaNotAvailable: true,
              availableChannels:
                  ChannelEnum.values.map((e) => e.value).toList(),
              availableChannelEnums: ChannelEnum.values.toList(),
              availableKasurs: [],
              availableDivans: [],
              availableHeadboards: [],
              availableSorongs: [],
              selectedKasur: AppStrings.noKasur, // Default value
              selectedDivan: AppStrings.noDivan, // Default value
              selectedHeadboard: AppStrings.noHeadboard, // Default value
              selectedSorong: AppStrings.noSorong, // Default value
              selectedSize: "", // Default value
            ));
          }
        } else {
          // No user area, show normal state
          emit(ProductState(
            userAreaId: userAreaId,
            availableChannels: ChannelEnum.values.map((e) => e.value).toList(),
            availableChannelEnums: ChannelEnum.values.toList(),
            availableKasurs: [],
            availableDivans: [],
            availableHeadboards: [],
            availableSorongs: [],
            selectedKasur: AppStrings.noKasur, // Default value
            selectedDivan: AppStrings.noDivan, // Default value
            selectedHeadboard: AppStrings.noHeadboard, // Default value
            selectedSorong: AppStrings.noSorong, // Default value
            selectedSize: "", // Default value
          ));
        }
      } catch (e, s) {
        logger.e("Unexpected error in ProductBloc", error: e, stackTrace: s);
        emit(const ProductError("Terjadi kesalahan yang tidak terduga."));
      }
    });

    on<FetchProductsByFilter>((event, emit) async {
      // Set loading state while preserving current selections
      emit(state.copyWith(isLoading: true));
      try {
        // Determine which area to use based on brand selection
        String areaToUse = event.selectedArea ?? '';

        // If brand is Spring Air or Therapedic, use "nasional" area
        if (event.selectedBrand == BrandEnum.springair.value ||
            event.selectedBrand == BrandEnum.therapedic.value) {
          areaToUse = AreaEnum.nasional.value;
        }

        final products = await getProductUseCase.callWithFilter(
          area: areaToUse,
          channel: event.selectedChannel ?? '',
          brand: event.selectedBrand ?? '',
        );

        if (products.isEmpty) {
          emit(state.copyWith(isLoading: false));

          // Show toast message
          CustomToast.showToast(
            "Tidak ada produk yang ditemukan dengan filter yang dipilih. Silakan coba filter lain.",
            ToastType.warning,
          );

          // Show WhatsApp dialog for unavailable area/channel
          emit(state.copyWith(
            showWhatsAppDialog: true,
            whatsAppBrand: event.selectedBrand ?? 'Unknown',
            whatsAppArea: areaToUse,
            whatsAppChannel: event.selectedChannel ?? 'Unknown',
          ));

          return;
        }

        // Update available options based on products (already filtered from API)
        final availableKasurs = products.map((p) => p.kasur).toSet().toList()
          ..sort();
        final availableDivans = products.map((p) => p.divan).toSet().toList()
          ..sort();
        final availableHeadboards =
            products.map((p) => p.headboard).toSet().toList()..sort();
        final availableSorongs = products.map((p) => p.sorong).toSet().toList()
          ..sort();
        final availableSizes = products.map((p) => p.ukuran).toSet().toList()
          ..sort();

        emit(state.copyWith(
          products: products,
          filteredProducts: products, // Products are already filtered
          availableKasurs: availableKasurs,
          availableDivans: availableDivans,
          availableHeadboards: availableHeadboards,
          availableSorongs: availableSorongs,
          availableSizes: availableSizes,
          isLoading: false,
        ));

        CustomToast.showToast(
          "Produk berhasil diperbarui berdasarkan filter.",
          ToastType.success,
        );
      } on ServerException catch (e) {
        logger.e("Server error in ProductBloc", error: e);
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Server error: ${e.message}",
          ToastType.error,
        );
      } on NetworkException catch (e) {
        logger.e("Network error in ProductBloc", error: e);
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Network error: ${e.message}",
          ToastType.error,
        );
      } catch (e, s) {
        logger.e("Unexpected error in ProductBloc", error: e, stackTrace: s);
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Terjadi kesalahan yang tidak terduga: $e",
          ToastType.error,
        );
      }
    });

    on<UpdateSelectedDivan>((event, emit) {
      // Filter berdasarkan kasur & divan yang dipilih
      final filteredProducts = state.products
          .where((p) =>
              p.kasur == state.selectedKasur &&
              p.divan == event.divan &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      // Pilih headboard default
      String selectedHeadboard =
          headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard;
      if (state.isSetActive &&
          headboards.length == 2 &&
          headboards.contains(AppStrings.noHeadboard)) {
        selectedHeadboard =
            headboards.firstWhere((h) => h != AppStrings.noHeadboard);
      }

      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: sorongs,
        selectedSorong:
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong,
        availableSizes: sizes,
        selectedSize: "",
      ));
    });

    on<UpdateSelectedHeadboard>((event, emit) {
      // Filter berdasarkan kasur, divan, headboard yang dipilih
      final filteredProducts = state.products
          .where((p) =>
              p.kasur == state.selectedKasur &&
              p.divan == state.selectedDivan &&
              p.headboard == event.headboard &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      // Pilih sorong default
      String selectedSorong =
          sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong;
      if (state.isSetActive &&
          sorongs.length == 2 &&
          sorongs.contains(AppStrings.noSorong)) {
        selectedSorong = sorongs.firstWhere((s) => s != AppStrings.noSorong);
      }

      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: "",
      ));
    });

    on<UpdateSelectedSorong>((event, emit) {
      // Filter berdasarkan kasur, divan, headboard, sorong yang dipilih
      final filteredProducts = state.products
          .where((p) =>
              p.kasur == state.selectedKasur &&
              p.divan == state.selectedDivan &&
              p.headboard == state.selectedHeadboard &&
              p.sorong == event.sorong &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      emit(state.copyWith(
        selectedSorong: event.sorong,
        availableSizes: sizes,
        selectedSize: "",
      ));
    });

    on<ToggleSet>((event, emit) {
      final isSetActive = event.isSetActive;
      // Filter produk sesuai kasur yang dipilih dan toggle set
      final filteredProducts = state.products
          .where((p) =>
              p.kasur == state.selectedKasur &&
              (!isSetActive || p.isSet == true))
          .toList();

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      String selectedDivan =
          divans.isNotEmpty ? divans.first : AppStrings.noDivan;
      if (isSetActive &&
          divans.length == 2 &&
          divans.contains(AppStrings.noDivan)) {
        selectedDivan = divans.firstWhere((d) => d != AppStrings.noDivan);
      }

      final filteredByDivan =
          filteredProducts.where((p) => p.divan == selectedDivan).toList();
      final headboards =
          filteredByDivan.map((p) => p.headboard).toSet().toList();
      String selectedHeadboard =
          headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard;
      if (isSetActive &&
          headboards.length == 2 &&
          headboards.contains(AppStrings.noHeadboard)) {
        selectedHeadboard =
            headboards.firstWhere((h) => h != AppStrings.noHeadboard);
      }

      final filteredByHeadboard = filteredByDivan
          .where((p) => p.headboard == selectedHeadboard)
          .toList();
      final sorongs = filteredByHeadboard.map((p) => p.sorong).toSet().toList();
      String selectedSorong =
          sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong;
      if (isSetActive &&
          sorongs.length == 2 &&
          sorongs.contains(AppStrings.noSorong)) {
        selectedSorong = sorongs.firstWhere((s) => s != AppStrings.noSorong);
      }

      final filteredBySorong =
          filteredByHeadboard.where((p) => p.sorong == selectedSorong).toList();
      final sizes = filteredBySorong.map((p) => p.ukuran).toSet().toList();
      String selectedSize = sizes.isNotEmpty ? sizes.first : "";

      emit(state.copyWith(
        isSetActive: isSetActive,
        selectedKasur: state.selectedKasur,
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
      emit(state.copyWith(
        userSelectedArea: event.area, // Store user's manual area selection
        selectedArea: event.area, // Use for current filter
        selectedAreaEnum: AreaEnum.fromString(event.area), // Convert to enum
      ));
    });

    on<UpdateSelectedChannel>((event, emit) {
      emit(state.copyWith(
        selectedChannel: event.channel, // User selected channel
        selectedChannelEnum:
            ChannelEnum.fromString(event.channel), // Convert to enum
        availableBrands: BrandEnum.values.map((e) => e.value).toList(),
        availableBrandEnums: BrandEnum.values.toList(),
        selectedBrand: "", // Reset to empty
        selectedBrandEnum: null,
        availableKasurs: [], // Will be populated when brand is selected
        availableDivans: [], // Will be populated when kasur is selected
        availableHeadboards: [], // Will be populated when divan is selected
        availableSorongs: [], // Will be populated when headboard is selected
        availableSizes: [], // Will be populated when sorong is selected
        selectedKasur: AppStrings.noKasur, // Reset to default
        selectedDivan: AppStrings.noDivan, // Reset to default
        selectedHeadboard: AppStrings.noHeadboard, // Reset to default
        selectedSorong: AppStrings.noSorong, // Reset to default
        selectedSize: "", // Reset to empty
      ));
    });

    on<UpdateSelectedBrand>((event, emit) {
      // Show toast for Spring Air and Therapedic brands
      if (event.brand == BrandEnum.springair.value ||
          event.brand == BrandEnum.therapedic.value) {
        CustomToast.showToast(
          "Brand ${event.brand} akan menggunakan area nasional untuk pencarian produk.",
          ToastType.info,
        );
      }

      emit(state.copyWith(
        selectedBrand: event.brand,
        selectedBrandEnum: BrandEnum.fromString(event.brand), // Convert to enum
        availableKasurs: [], // Will be populated after fetch
        availableDivans: [], // Will be populated when kasur is selected
        availableHeadboards: [], // Will be populated when divan is selected
        availableSorongs: [], // Will be populated when headboard is selected
        availableSizes: [], // Will be populated when sorong is selected
        selectedKasur: AppStrings.noKasur, // Reset to default
        selectedDivan: AppStrings.noDivan, // Reset to default
        selectedHeadboard: AppStrings.noHeadboard, // Reset to default
        selectedSorong: AppStrings.noSorong, // Reset to default
        selectedSize: "", // Reset to empty
      ));

      // Determine which area to use based on brand selection
      String? areaToUse;
      if (event.brand == BrandEnum.springair.value ||
          event.brand == BrandEnum.therapedic.value) {
        // Use nasional area for Spring Air and Therapedic
        areaToUse = AreaEnum.nasional.value;
      } else {
        // Use user's selected area for other brands
        areaToUse = state.userSelectedArea ?? state.selectedArea;
      }

      // Fetch products based on selected filters
      add(FetchProductsByFilter(
        selectedArea: areaToUse,
        selectedChannel: state.selectedChannel,
        selectedBrand: event.brand, // Pass selected brand to fetch
      ));
    });

    on<UpdateSelectedKasur>((event, emit) {
      // Filter produk berdasarkan kasur yang dipilih dengan pendekatan yang lebih sederhana
      var filteredProducts =
          state.products.where((p) => p.kasur == event.kasur).toList();

      // Jika masih kosong, coba filter yang lebih longgar
      if (filteredProducts.isEmpty) {
        return; // Jangan update state jika tidak ada produk
      }

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      emit(state.copyWith(
        selectedKasur: event.kasur,
        availableDivans: divans, // Populate with available divans
        selectedDivan: divans.isNotEmpty ? divans.first : AppStrings.noDivan,
        availableHeadboards: headboards, // Populate with available headboards
        selectedHeadboard:
            headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard,
        availableSorongs: sorongs, // Populate with available sorongs
        selectedSorong:
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong,
        availableSizes: sizes,
        selectedSize: "",
      ));
    });

    on<UpdateSelectedUkuran>((event, emit) {
      emit(state.copyWith(selectedSize: event.ukuran));
    });

    on<FilterProducts>((event, emit) {
      emit(state.copyWith(filteredProducts: event.filteredProducts));
    });

    on<ApplyFilters>((event, emit) async {
      // Determine which area to use based on brand selection
      String areaToUse = event.selectedArea ?? '';

      // If brand is Spring Air or Therapedic, use "nasional" area
      if (event.selectedBrand == BrandEnum.springair.value ||
          event.selectedBrand == BrandEnum.therapedic.value) {
        // Try usingnasional" first, if it fails, fallback to user's area
        areaToUse = AreaEnum.nasional.value;
      } else {
        // For other brands, use user's selected area or default area
        areaToUse = state.userSelectedArea ?? state.selectedArea ?? '';
      }

      // Handle default values for divan, headboard, and sorong
      String selectedDivan = event.selectedDivan ?? AppStrings.noDivan;
      String selectedHeadboard =
          event.selectedHeadboard ?? AppStrings.noHeadboard;
      String selectedSorong = event.selectedSorong ?? AppStrings.noSorong;

      final filteredProducts = state.products.where((p) {
        final matchesArea = areaToUse.isEmpty || p.area == areaToUse;
        final matchesChannel = event.selectedChannel == null ||
            event.selectedChannel!.isEmpty ||
            p.channel == event.selectedChannel;
        final matchesBrand = event.selectedBrand == null ||
            event.selectedBrand!.isEmpty ||
            p.brand == event.selectedBrand;
        final matchesKasur = event.selectedKasur == null ||
            event.selectedKasur!.isEmpty ||
            p.kasur == event.selectedKasur;
        final matchesDivan = p.divan == selectedDivan;
        final matchesHeadboard = p.headboard == selectedHeadboard;
        final matchesSorong = p.sorong == selectedSorong;
        // Perbaiki: jika user memilih ukuran, harus sama persis
        final matchesSize =
            (event.selectedSize != null && event.selectedSize!.isNotEmpty)
                ? p.ukuran == event.selectedSize
                : true;

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

      emit(state.copyWith(
          filteredProducts: filteredProducts, isFilterApplied: true));

      if (filteredProducts.isNotEmpty) {
        CustomToast.showToast(
          "Berikut adalah produk yang cocok.",
          ToastType.success,
        );
      } else {
        CustomToast.showToast(
          "Produk tidak ditemukan.",
          ToastType.error,
        );

        // Show WhatsApp dialog for unavailable area/channel
        emit(state.copyWith(
          showWhatsAppDialog: true,
          whatsAppBrand: event.selectedBrand ?? 'Unknown',
          whatsAppArea: event.selectedArea ?? 'Unknown',
          whatsAppChannel: event.selectedChannel ?? 'Unknown',
        ));
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

      Map<int, double> updatedPriceChangePercentages =
          Map.from(currentState.priceChangePercentages);
      updatedPriceChangePercentages.remove(event.productId);

      updatedDiscountsPercentage[event.productId] =
          List.from(event.discountPercentages);
      updatedDiscountsNominal[event.productId] =
          List.from(event.discountNominals);

      double finalPrice = event.originalPrice;
      for (var discount in event.discountPercentages) {
        finalPrice -= finalPrice * (discount / 100);
      }
      finalPrice = finalPrice.clamp(0, event.originalPrice);
      updatedRoundedPrices[event.productId] = finalPrice;

      emit(currentState.copyWith(
        roundedPrices: updatedRoundedPrices,
        productDiscountsPercentage: updatedDiscountsPercentage,
        productDiscountsNominal: updatedDiscountsNominal,
        priceChangePercentages: updatedPriceChangePercentages,
      ));

      CustomToast.showToast(
        "Diskon berhasil diterapkan.",
        ToastType.success,
      );
    });

    on<ResetProductState>((event, emit) {
      emit(ProductState());
    });

    on<ResetFilters>((event, emit) {
      emit(state.copyWith(
        filteredProducts: [],
        isFilterApplied: false,
        selectedChannel: "", // Reset to empty
        selectedBrand: "", // Reset to empty
        selectedKasur: AppStrings.noKasur, // Reset to default
        selectedDivan: AppStrings.noDivan, // Reset to default
        selectedHeadboard: AppStrings.noHeadboard, // Reset to default
        selectedSorong: AppStrings.noSorong, // Reset to default
        selectedSize: "", // Reset to empty
        availableBrands: [], // Reset to empty
        availableKasurs: [], // Reset to empty
        availableDivans: [], // Reset to empty
        availableHeadboards: [], // Reset to empty
        availableSorongs: [], // Reset to empty
        availableSizes: [], // Reset to empty
        // Note: userSelectedArea is NOT reset to preserve user's manual area selection
      ));

      CustomToast.showToast(
        "Filter berhasil direset.",
        ToastType.info,
      );
    });

    on<ResetUserSelectedArea>((event, emit) async {
      // Get user's default area from AuthService
      final userAreaId = await AuthService.getCurrentUserAreaId();

      if (userAreaId != null) {
        AreaEnum? userAreaEnum = _getAreaEnumFromId(userAreaId);
        if (userAreaEnum != null) {
          final newState = state.copyWith(
            userSelectedArea: null,
            selectedArea: userAreaEnum.value,
            selectedAreaEnum: userAreaEnum,
          );

          emit(newState);

          CustomToast.showToast(
            "Area berhasil direset ke area default: ${userAreaEnum.value}",
            ToastType.success,
          );
        } else {
          emit(state.copyWith(
            userSelectedArea: null,
          ));
          CustomToast.showToast(
            "Area manual berhasil direset.",
            ToastType.info,
          );
        }
      } else {
        emit(state.copyWith(
          userSelectedArea: null,
        ));
        CustomToast.showToast(
          "Area manual berhasil direset.",
          ToastType.info,
        );
      }
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

    on<SetUserArea>((event, emit) async {
      // Map area_id to area enum
      AreaEnum? userAreaEnum = _getAreaEnumFromId(event.areaId);

      if (userAreaEnum != null &&
          state.availableAreas.contains(userAreaEnum.value)) {
        add(UpdateSelectedArea(userAreaEnum.value));
      } else {
        // Emit state with area not available message
        emit(state.copyWith(
          userAreaId: event.areaId,
          selectedArea: null,
          selectedAreaEnum: null,
          areaNotAvailable: true,
        ));
      }
    });

    on<ShowAreaNotAvailable>((event, emit) {
      emit(state.copyWith(
        userAreaId: event.areaId,
        selectedArea: null,
        areaNotAvailable: true,
      ));
    });

    on<ShowWhatsAppDialog>((event, emit) {
      emit(state.copyWith(
        showWhatsAppDialog: true,
        whatsAppBrand: event.brand,
        whatsAppArea: event.area,
        whatsAppChannel: event.channel,
      ));
    });

    on<HideWhatsAppDialog>((event, emit) {
      emit(state.copyWith(
        showWhatsAppDialog: false,
        whatsAppBrand: null,
        whatsAppArea: null,
        whatsAppChannel: null,
      ));
    });
  }

  // Helper method to map area_id to area enum
  AreaEnum? _getAreaEnumFromId(int areaId) {
    try {
      final areaEnum = AreaEnum.values.firstWhere(
        (area) => AreaEnum.getId(area) == areaId,
      );
      return areaEnum;
    } catch (e) {
      return null;
    }
  }

  // Helper method to get available channels for a specific area
}
