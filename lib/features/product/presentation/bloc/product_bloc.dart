import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/area_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/brand_repository.dart';
import '../../domain/usecases/get_product_usecase.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProductUseCase;
  late final AreaRepository _areaRepository;
  late final ChannelRepository _channelRepository;
  late final BrandRepository _brandRepository;

  ProductBloc(this.getProductUseCase) : super(ProductInitial()) {
    _areaRepository = locator<AreaRepository>();
    _channelRepository = locator<ChannelRepository>();
    _brandRepository = locator<BrandRepository>();
    on<AppStarted>((event, emit) {
      // Don't fetch products automatically - wait for user to select filters
      add(InitializeDropdowns());
    });

    on<InitializeDropdowns>((event, emit) async {
      try {
        // Get user area_id from AuthService
        final userAreaId = await AuthService.getCurrentUserAreaId();

        // Fetch areas from API or fallback to hardcoded values
        List<AreaEnum> availableAreas = [];
        try {
          availableAreas = await _areaRepository.fetchAreasAsEnum();
          print(
              "ProductBloc: Successfully fetched ${availableAreas.length} areas from API");
        } catch (e) {
          print(
              "ProductBloc: Error fetching areas from API, using hardcoded values: $e");
          availableAreas = AreaEnum.allValues;
        }

        // Fetch channels from API or fallback to hardcoded values
        List<String> availableChannels = [];
        try {
          // Get all channel names from API (most direct approach)
          availableChannels = await _channelRepository.fetchAllChannelNames();
          print(
              "ProductBloc: Successfully fetched ${availableChannels.length} channels from API");
        } catch (e) {
          print(
              "ProductBloc: Error fetching channels from API, using hardcoded values: $e");
          availableChannels = ChannelEnum.values.map((e) => e.value).toList();
        }

        // Fetch brands from API or fallback to hardcoded values
        List<String> availableBrands = [];
        try {
          // Get all brand names from API (most direct approach)
          availableBrands = await _brandRepository.fetchAllBrandNames();
          print(
              "ProductBloc: Successfully fetched ${availableBrands.length} brands from API");
        } catch (e) {
          print(
              "ProductBloc: Error fetching brands from API, using hardcoded values: $e");
          availableBrands = BrandEnum.values.map((e) => e.value).toList();
        }

        // Ensure no duplicate values and create a clean list
        final uniqueAreas = <AreaEnum>[];
        final seenValues = <String>{};

        for (final area in availableAreas) {
          if (!seenValues.contains(area.value)) {
            uniqueAreas.add(area);
            seenValues.add(area.value);
          }
        }

        // If no areas were found, use hardcoded values
        if (uniqueAreas.isEmpty) {
          uniqueAreas.addAll(AreaEnum.allValues);
        }

        // Initialize with empty state and user area if available
        if (userAreaId != null) {
          AreaEnum? userAreaEnum = _getAreaEnumFromId(userAreaId);
          if (userAreaEnum != null) {
            // Ensure user area is in the available areas list
            if (!uniqueAreas.contains(userAreaEnum)) {
              uniqueAreas.add(userAreaEnum);
            }

            emit(ProductState(
              userAreaId: userAreaId,
              selectedArea: userAreaEnum.value,
              selectedAreaEnum: userAreaEnum,
              availableAreaEnums: uniqueAreas,
              isUserAreaSet: true,
              filteredProducts: [],
              isFilterApplied: false,
              availableChannels: availableChannels,
              availableChannelEnums: ChannelEnum.values.toList(),
              availableBrands: availableBrands,
              availableBrandEnums: [], // No longer needed
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
              availableAreaEnums: uniqueAreas,
              availableChannels: availableChannels,
              availableChannelEnums: ChannelEnum.values.toList(),
              availableBrands: availableBrands,
              availableBrandEnums: [], // No longer needed
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
            availableAreaEnums: uniqueAreas,
            availableChannels: availableChannels,
            availableChannelEnums: ChannelEnum.values.toList(),
            availableBrands: availableBrands,
            availableBrandEnums: [], // No longer needed
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
      } catch (e) {
        emit(const ProductError("Terjadi kesalahan yang tidak terduga."));
      }
    });

    on<RefreshAreas>((event, emit) async {
      try {
        // Fetch fresh areas from API
        final availableAreas = await _areaRepository.fetchAreasAsEnum();
        print(
            "ProductBloc: Successfully refreshed ${availableAreas.length} areas from API");

        // Ensure no duplicate values and create a clean list
        final uniqueAreas = <AreaEnum>[];
        final seenValues = <String>{};

        for (final area in availableAreas) {
          if (!seenValues.contains(area.value)) {
            uniqueAreas.add(area);
            seenValues.add(area.value);
          }
        }

        // If no areas were found, use hardcoded values
        if (uniqueAreas.isEmpty) {
          uniqueAreas.addAll(AreaEnum.allValues);
        }

        // Ensure current selected area is still valid
        String? validSelectedArea = state.selectedArea;
        if (validSelectedArea != null) {
          final hasValidArea =
              uniqueAreas.any((area) => area.value == validSelectedArea);
          if (!hasValidArea && uniqueAreas.isNotEmpty) {
            // If current selected area is not valid, use first available area
            validSelectedArea = uniqueAreas.first.value;
          }
        }

        // Update state with new areas
        emit(state.copyWith(
          availableAreaEnums: uniqueAreas,
          selectedArea: validSelectedArea,
        ));
      } catch (e) {
        print("ProductBloc: Error refreshing areas: $e");
        // Keep existing areas if refresh fails
        CustomToast.showToast("Gagal memperbarui data area", ToastType.error);
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

        final kasurWithPrices = <String, double>{};
        for (final product in products) {
          if (product.kasur.isNotEmpty && product.kasur != AppStrings.noKasur) {
            // Use the highest pricelist for each kasur type
            if (!kasurWithPrices.containsKey(product.kasur) ||
                kasurWithPrices[product.kasur]! < product.pricelist) {
              kasurWithPrices[product.kasur] = product.pricelist;
            }
          }
        }

        // Sort kasur by pricelist (highest first)
        final sortedKasurEntries = kasurWithPrices.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final availableKasurs = sortedKasurEntries.map((e) => e.key).toList();

        // Ensure "Tanpa Kasur" option is always available and at the end
        if (!availableKasurs.contains(AppStrings.noKasur)) {
          availableKasurs.add(AppStrings.noKasur);
        }
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
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Server error: ${e.message}",
          ToastType.error,
        );
      } on NetworkException catch (e) {
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Network error: ${e.message}",
          ToastType.error,
        );
      } catch (e) {
        emit(state.copyWith(isLoading: false));
        CustomToast.showToast(
          "Terjadi kesalahan yang tidak terduga: $e",
          ToastType.error,
        );
      }
    });

    on<ToggleSet>((event, emit) {
      final isSetActive = event.isSetActive;
      // Filter produk sesuai kasur yang dipilih dan toggle set
      final filteredProducts = state.products
          .where((p) =>
              (state.selectedKasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == state.selectedKasur) &&
              (!isSetActive || p.isSet == true))
          .toList();

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      String selectedDivan = divans.contains(AppStrings.noDivan)
          ? AppStrings.noDivan
          : (divans.isNotEmpty ? divans.first : AppStrings.noDivan);

      final filteredByDivan = selectedDivan == AppStrings.noDivan
          ? filteredProducts
              .where((p) => p.divan.isEmpty || p.divan == AppStrings.noDivan)
              .toList()
          : filteredProducts.where((p) => p.divan == selectedDivan).toList();
      final headboards =
          filteredByDivan.map((p) => p.headboard).toSet().toList();
      String selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : (headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard);

      final filteredByHeadboard = selectedHeadboard == AppStrings.noHeadboard
          ? filteredByDivan
              .where((p) =>
                  p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
              .toList()
          : filteredByDivan
              .where((p) => p.headboard == selectedHeadboard)
              .toList();
      final sorongs = filteredByHeadboard.map((p) => p.sorong).toSet().toList();
      String selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);

      final filteredBySorong = selectedSorong == AppStrings.noSorong
          ? filteredByHeadboard
              .where((p) => p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
              .toList()
          : filteredByHeadboard
              .where((p) => p.sorong == selectedSorong)
              .toList();
      final sizes = filteredBySorong.map((p) => p.ukuran).toSet().toList();
      String selectedSize = sizes.isNotEmpty ? sizes.first : "";

      // Ambil program unik dari hasil filter terakhir
      final programs = filteredBySorong.map((p) => p.program).toSet().toList();
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Cari program yang bukan set
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }

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
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedKasur>((event, emit) {
      var filteredProducts = event.kasur == AppStrings.noKasur
          ? state.products
              .where((p) => p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
              .toList()
          : state.products.where((p) => p.kasur == event.kasur).toList();
      // Allow selection even if no products match (e.g., for "Tanpa Kasur")
      if (filteredProducts.isEmpty && event.kasur != AppStrings.noKasur) {
        return;
      }
      // If no products match the selected kasur, use default values
      if (filteredProducts.isEmpty) {
        emit(state.copyWith(
          selectedKasur: event.kasur,
          availableDivans: [AppStrings.noDivan],
          selectedDivan: AppStrings.noDivan,
          availableHeadboards: [AppStrings.noHeadboard],
          selectedHeadboard: AppStrings.noHeadboard,
          availableSorongs: [AppStrings.noSorong],
          selectedSorong: AppStrings.noSorong,
          availableSizes: [],
          selectedSize: "",
          availablePrograms: [],
          selectedProgram: "",
        ));
        return;
      }

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      final programs = filteredProducts.map((p) => p.program).toSet().toList();
      String selectedDivan = divans.contains(AppStrings.noDivan)
          ? AppStrings.noDivan
          : (divans.isNotEmpty ? divans.first : AppStrings.noDivan);
      String selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : (headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard);
      String selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }
      emit(state.copyWith(
        selectedKasur: event.kasur,
        availableDivans: divans,
        selectedDivan: selectedDivan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedDivan>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              (state.selectedKasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == state.selectedKasur) &&
              (event.divan == AppStrings.noDivan
                  ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
                  : p.divan == event.divan) &&
              (!state.isSetActive || p.isSet == true))
          .toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      final programs = filteredProducts.map((p) => p.program).toSet().toList();
      String selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : (headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard);
      String selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }
      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedHeadboard>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              (state.selectedKasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == state.selectedKasur) &&
              (state.selectedDivan == AppStrings.noDivan
                  ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
                  : p.divan == state.selectedDivan) &&
              (event.headboard == AppStrings.noHeadboard
                  ? (p.headboard.isEmpty ||
                      p.headboard == AppStrings.noHeadboard)
                  : p.headboard == event.headboard) &&
              (!state.isSetActive || p.isSet == true))
          .toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      final programs = filteredProducts.map((p) => p.program).toSet().toList();
      String selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }
      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedSorong>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              (state.selectedKasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == state.selectedKasur) &&
              (state.selectedDivan == AppStrings.noDivan
                  ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
                  : p.divan == state.selectedDivan) &&
              (state.selectedHeadboard == AppStrings.noHeadboard
                  ? (p.headboard.isEmpty ||
                      p.headboard == AppStrings.noHeadboard)
                  : p.headboard == state.selectedHeadboard) &&
              (event.sorong == AppStrings.noSorong
                  ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
                  : p.sorong == event.sorong) &&
              (!state.isSetActive || p.isSet == true))
          .toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      final programs = filteredProducts.map((p) => p.program).toSet().toList();
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }
      emit(state.copyWith(
        selectedSorong: event.sorong,
        availableSizes: sizes,
        selectedSize: "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
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
        // Don't reset brands - keep the ones from API
        selectedBrand: "", // Reset to empty
        selectedBrandEnum: null,
        availableKasurs: [], // Will be populated when brand is selected
        availableDivans: [], // Will be populated when kasur is selected
        availableHeadboards: [], // Will be populated when divan is selected
        availableSorongs: [], // Will be populated when headboard is selected
        availableSizes: [], // Will be populated when sorong is selected
        availablePrograms: [], // Will be populated when kasur is selected
        selectedKasur: AppStrings.noKasur, // Reset to default
        selectedDivan: AppStrings.noDivan, // Reset to default
        selectedHeadboard: AppStrings.noHeadboard, // Reset to default
        selectedSorong: AppStrings.noSorong, // Reset to default
        selectedSize: "", // Reset to empty
        selectedProgram: "", // Reset to empty
      ));
    });

    on<UpdateSelectedBrand>((event, emit) {
      // Show toast for Spring Air and Therapedic brands
      if (event.brand == BrandEnum.springair.value ||
          event.brand == BrandEnum.therapedic.value ||
          event.brand.toLowerCase().contains('spring air')) {
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
        availablePrograms: [], // Will be populated when kasur is selected
        selectedKasur: AppStrings.noKasur, // Reset to default
        selectedDivan: AppStrings.noDivan, // Reset to default
        selectedHeadboard: AppStrings.noHeadboard, // Reset to default
        selectedSorong: AppStrings.noSorong, // Reset to default
        selectedSize: "", // Reset to empty
        selectedProgram: "", // Reset to empty
      ));

      // Determine which area to use based on brand selection
      String? areaToUse;
      if (event.brand == BrandEnum.springair.value ||
          event.brand == BrandEnum.therapedic.value ||
          event.brand.toLowerCase().contains('spring air')) {
        // Use nasional area for Spring Air (including European Collection) and Therapedic
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

    on<UpdateSelectedUkuran>((event, emit) {
      emit(state.copyWith(selectedSize: event.ukuran));
    });

    on<UpdateSelectedProgram>((event, emit) {
      emit(state.copyWith(selectedProgram: event.program));
    });

    on<FilterProducts>((event, emit) {
      emit(state.copyWith(filteredProducts: event.filteredProducts));
    });

    on<ApplyFilters>((event, emit) async {
      // Determine which area to use based on brand selection
      String areaToUse = event.selectedArea ?? '';

      // If brand is Spring Air or Therapedic, use "nasional" area
      if (event.selectedBrand == BrandEnum.springair.value ||
          event.selectedBrand == BrandEnum.therapedic.value ||
          (event.selectedBrand?.toLowerCase().contains('spring air') ??
              false)) {
        // Try using "nasional" first, if it fails, fallback to user's area
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

        // Fixed logic for kasur filter
        final matchesKasur = event.selectedKasur == null ||
            event.selectedKasur!.isEmpty ||
            (event.selectedKasur == AppStrings.noKasur
                ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                : p.kasur == event.selectedKasur);

        // Fixed logic for divan filter
        final matchesDivan = selectedDivan == AppStrings.noDivan
            ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
            : p.divan == selectedDivan;

        // Fixed logic for headboard filter
        final matchesHeadboard = selectedHeadboard == AppStrings.noHeadboard
            ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
            : p.headboard == selectedHeadboard;

        // Fixed logic for sorong filter
        final matchesSorong = selectedSorong == AppStrings.noSorong
            ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
            : p.sorong == selectedSorong;
        final matchesSize =
            (event.selectedSize != null && event.selectedSize!.isNotEmpty)
                ? p.ukuran == event.selectedSize
                : true;

        // Filter berdasarkan program yang dipilih
        final matchesProgram =
            (event.selectedProgram != null && event.selectedProgram!.isNotEmpty)
                ? p.program == event.selectedProgram
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
            matchesProgram &&
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

      // --- LOGIC: AUTO SPLIT DISKON BERTINGKAT ---
      final product = state.products.firstWhere((p) => p.id == event.productId,
          orElse: () => state.selectProduct!);
      double originalPrice = product.endUserPrice;
      double targetPrice = event.newPrice;
      List<double> maxDiscs = [
        product.disc1,
        product.disc2,
        product.disc3,
        product.disc4,
        product.disc5,
      ];
      List<double> splitDiscs = [];
      List<double> splitNominals = [];
      double currentPrice = originalPrice;
      for (var max in maxDiscs) {
        if (currentPrice <= targetPrice + 0.01) {
          splitDiscs.add(0);
          splitNominals.add(0);
          continue;
        }
        double maxAllowed = max * 100; // persen
        double needed = (1 - (targetPrice / currentPrice)) * 100;
        double useDisc = needed > maxAllowed ? maxAllowed : needed;
        if (useDisc < 0) useDisc = 0;
        splitDiscs.add(useDisc);
        double nominal = currentPrice * (useDisc / 100);
        splitNominals.add(nominal);
        currentPrice = currentPrice * (1 - useDisc / 100);
      }
      updatedDiscounts[event.productId] = splitDiscs;
      // --- END LOGIC ---
      // --- LOGIC: UPDATE NOMINAL DISKON ---
      final updatedNominals =
          Map<int, List<double>>.from(state.productDiscountsNominal);
      updatedNominals[event.productId] = splitNominals;
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
    });

    on<UpdateProductDiscounts>((event, emit) {
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
        productLeaderIds: updatedLeaderIds,
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
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        availableSizes: [],
        availablePrograms: [],
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

    on<ClearFilters>((event, emit) {
      emit(state.copyWith(
        filteredProducts: [],
        isFilterApplied: false,
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
        selectedSize: "",
        selectedProgram: "",
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        availableSizes: [],
        availablePrograms: [],
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
