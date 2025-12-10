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
import '../../domain/entities/product_entity.dart';
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
        // Get user area info from AuthService
        final userAreaId = await AuthService.getCurrentUserAreaId();
        final userAreaNameFromCWE = await AuthService.getCurrentUserAreaName();

        // Fetch areas from API (AreaRepository handles cache fallback internally)
        List<String> availableAreas = [];
        try {
          availableAreas = await _areaRepository.fetchAllAreaNames();
        } catch (e) {
          // AreaRepository sudah handle cache, jika gagal total return empty
          availableAreas = [];
        }

        // Fetch channels from API only (no hardcoded fallback)
        List<String> availableChannels = [];
        try {
          // Get all channel names from API (most direct approach)
          availableChannels = await _channelRepository.fetchAllChannelNames();
        } catch (e) {
          availableChannels = [];
        }

        List<String> availableBrands = [];
        try {
          // Get all brand names from API (most direct approach)
          availableBrands = await _brandRepository.fetchAllBrandNames();
        } catch (e) {
          availableBrands = [];
        }

        // Ensure no duplicate values and create a clean list
        final uniqueAreas = <String>[];
        final seenValues = <String>{};

        for (final area in availableAreas) {
          if (!seenValues.contains(area)) {
            uniqueAreas.add(area);
            seenValues.add(area);
          }
        }

        // Initialize with empty state and user area if available
        if (userAreaId != null || userAreaNameFromCWE != null) {
          // Smart matching:
          // 1. Coba match by area name dari CWE (lebih akurat)
          // 2. Fallback ke match by area ID
          // 3. Fallback ke Nasional
          String? userAreaName;

          // Method 1: Match by name dari CWE (e.g., "SUMATRA SELATAN" → "Palembang")
          if (userAreaNameFromCWE != null && uniqueAreas.isNotEmpty) {
            userAreaName = _matchAreaByName(userAreaNameFromCWE, uniqueAreas);
          }

          // Method 2: Match by ID (fallback)
          if (userAreaName == null && userAreaId != null) {
            userAreaName =
                _getAreaNameFromId(userAreaId, availableAreas: uniqueAreas);
          }

          // Method 3: Fallback ke Nasional atau first area
          if (userAreaName == null && uniqueAreas.isNotEmpty) {
            userAreaName = uniqueAreas.contains("Nasional")
                ? "Nasional"
                : uniqueAreas.first;
          }

          // Method 4: Jika masih null tapi ada area Nasional, gunakan Nasional
          // Ini untuk memastikan user tidak melihat error meskipun area mereka tidak ditemukan
          if (userAreaName == null && uniqueAreas.contains("Nasional")) {
            userAreaName = "Nasional";
          }

          if (userAreaName != null) {
            emit(ProductState(
              userAreaId: userAreaId,
              selectedArea: userAreaName,
              availableAreas: uniqueAreas,
              isUserAreaSet: true,
              filteredProducts: [],
              isFilterApplied: false,
              availableChannels: availableChannels,
              availableChannelModels: [],
              availableBrands: availableBrands,
              availableBrandModels: [],
              availableKasurs: [],
              availableDivans: [],
              availableHeadboards: [],
              availableSorongs: [],
              availableSizes: [],
              selectedKasur: AppStrings.noKasur,
              selectedDivan: AppStrings.noDivan,
              selectedHeadboard: AppStrings.noHeadboard,
              selectedSorong: AppStrings.noSorong,
              selectedSize: "",
            ));
          } else {
            emit(ProductState(
              userAreaId: userAreaId,
              areaNotAvailable: uniqueAreas.isEmpty,
              selectedArea: uniqueAreas.isNotEmpty
                  ? (uniqueAreas.contains("Nasional")
                      ? "Nasional"
                      : uniqueAreas.first)
                  : null,
              availableAreas: uniqueAreas,
              availableChannels: availableChannels,
              availableChannelModels: [],
              availableBrands: availableBrands,
              availableBrandModels: [],
              availableKasurs: [],
              availableDivans: [],
              availableHeadboards: [],
              availableSorongs: [],
              selectedKasur: AppStrings.noKasur,
              selectedDivan: AppStrings.noDivan,
              selectedHeadboard: AppStrings.noHeadboard,
              selectedSorong: AppStrings.noSorong,
              selectedSize: "",
            ));
          }
        } else {
          // No user area (tanpa login) → default ke Nasional atau first area
          final defaultArea = uniqueAreas.isNotEmpty
              ? (uniqueAreas.contains("Nasional")
                  ? "Nasional"
                  : uniqueAreas.first)
              : null;

          emit(ProductState(
            userAreaId: null,
            selectedArea: defaultArea, // Default area untuk guest/tanpa login
            availableAreas: uniqueAreas,
            availableChannels: availableChannels,
            availableChannelModels: [],
            availableBrands: availableBrands,
            availableBrandModels: [],
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
        final availableAreas = await _areaRepository.fetchAllAreaNames();

        // Ensure no duplicate values and create a clean list
        final uniqueAreas = <String>[];
        final seenValues = <String>{};

        for (final area in availableAreas) {
          if (!seenValues.contains(area)) {
            uniqueAreas.add(area);
            seenValues.add(area);
          }
        }

        // If no areas were found, use hardcoded values
        if (uniqueAreas.isEmpty) {
          uniqueAreas.addAll([
            "Nasional",
            "Jabodetabek",
            "Bandung",
            "Surabaya",
            "Semarang",
            "Yogyakarta",
            "Solo",
            "Malang",
            "Denpasar",
            "Medan",
            "Palembang"
          ]);
        }

        // Ensure current selected area is still valid
        String? validSelectedArea = state.selectedArea;
        if (validSelectedArea != null) {
          final hasValidArea =
              uniqueAreas.any((area) => area == validSelectedArea);
          if (!hasValidArea && uniqueAreas.isNotEmpty) {
            // If current selected area is not valid, use first available area
            validSelectedArea = uniqueAreas.first;
          }
        }

        // Update state with new areas
        emit(state.copyWith(
          availableAreas: uniqueAreas,
          selectedArea: validSelectedArea,
        ));
      } catch (e) {
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

        // If brand is Spring Air, Therapedic, or Sleep Spa, use "nasional" area
        if (event.selectedBrand == "Spring Air" ||
            event.selectedBrand == "Therapedic" ||
            event.selectedBrand?.toLowerCase().contains('sleep spa') == true) {
          areaToUse = "Nasional";
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
      final baseFilteredProducts = state.products
          .where((p) =>
              (state.selectedKasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == state.selectedKasur) &&
              (!isSetActive || p.isSet == true))
          .toList();

      // Get ALL available divans from base filtered products
      final divans = baseFilteredProducts.map((p) => p.divan).toSet().toList();

      // Keep current divan selection if still valid, otherwise select default
      String selectedDivan = divans.contains(state.selectedDivan)
          ? state.selectedDivan!
          : (divans.contains(AppStrings.noDivan)
              ? AppStrings.noDivan
              : (divans.isNotEmpty ? divans.first : AppStrings.noDivan));

      // Get ALL available headboards from products matching kasur + divan + isSetActive
      final filteredByDivan = baseFilteredProducts
          .where((p) => selectedDivan == AppStrings.noDivan
              ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
              : p.divan == selectedDivan)
          .toList();
      final headboards =
          filteredByDivan.map((p) => p.headboard).toSet().toList();

      // Keep current headboard selection if still valid
      String selectedHeadboard = headboards.contains(state.selectedHeadboard)
          ? state.selectedHeadboard!
          : (headboards.contains(AppStrings.noHeadboard)
              ? AppStrings.noHeadboard
              : (headboards.isNotEmpty
                  ? headboards.first
                  : AppStrings.noHeadboard));

      // Get ALL available sorongs from products matching kasur + divan + headboard + isSetActive
      final filteredByHeadboard = filteredByDivan
          .where((p) => selectedHeadboard == AppStrings.noHeadboard
              ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
              : p.headboard == selectedHeadboard)
          .toList();
      final sorongs = filteredByHeadboard.map((p) => p.sorong).toSet().toList();

      // Keep current sorong selection if still valid
      String selectedSorong = sorongs.contains(state.selectedSorong)
          ? state.selectedSorong!
          : (sorongs.contains(AppStrings.noSorong)
              ? AppStrings.noSorong
              : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong));

      // Get sizes from final filtered products
      final filteredBySorong = filteredByHeadboard
          .where((p) => selectedSorong == AppStrings.noSorong
              ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
              : p.sorong == selectedSorong)
          .toList();
      final sizes = filteredBySorong.map((p) => p.ukuran).toSet().toList();

      // Keep current size if still valid, otherwise reset
      String selectedSize =
          sizes.contains(state.selectedSize) ? state.selectedSize! : "";

      // Get programs from final filtered products
      final programs = filteredBySorong.map((p) => p.program).toSet().toList();
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Keep current program if still valid
        if (programs.contains(state.selectedProgram) &&
            state.selectedProgram != null &&
            state.selectedProgram!.isNotEmpty) {
          selectedProgram = state.selectedProgram!;
        } else {
          // Select non-set program by default
          final nonSet = programs.firstWhere(
            (prog) => !prog.toLowerCase().contains('set'),
            orElse: () => programs.first,
          );
          selectedProgram = nonSet;
        }
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
      // Filter products by kasur AND respect isSetActive toggle
      var filteredProducts = state.products
          .where((p) =>
              (event.kasur == AppStrings.noKasur
                  ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                  : p.kasur == event.kasur) &&
              (!state.isSetActive || p.isSet == true)) // Apply Set filter
          .toList();

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

      // Auto-select ONLY when Set toggle is ON
      // When Set toggle is OFF, preserve current or use first available (no "Tanpa X" priority)
      String selectedDivan;
      if (state.selectedDivan != null && divans.contains(state.selectedDivan)) {
        selectedDivan = state.selectedDivan!;
      } else if (state.isSetActive) {
        // Set ON: prioritize "Tanpa Divan"
        selectedDivan = divans.contains(AppStrings.noDivan)
            ? AppStrings.noDivan
            : (divans.isNotEmpty ? divans.first : AppStrings.noDivan);
      } else {
        selectedDivan = divans.isNotEmpty ? divans.first : AppStrings.noDivan;
      }

      String selectedHeadboard;
      if (state.selectedHeadboard != null &&
          headboards.contains(state.selectedHeadboard)) {
        selectedHeadboard = state.selectedHeadboard!;
      } else if (state.isSetActive) {
        selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
            ? AppStrings.noHeadboard
            : (headboards.isNotEmpty
                ? headboards.first
                : AppStrings.noHeadboard);
      } else {
        selectedHeadboard =
            headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard;
      }

      String selectedSorong;
      if (state.selectedSorong != null &&
          sorongs.contains(state.selectedSorong)) {
        selectedSorong = state.selectedSorong!;
      } else if (state.isSetActive) {
        selectedSorong = sorongs.contains(AppStrings.noSorong)
            ? AppStrings.noSorong
            : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      } else {
        selectedSorong =
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong;
      }

      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Preserve current program if still valid
        if (state.selectedProgram != null &&
            programs.contains(state.selectedProgram)) {
          selectedProgram = state.selectedProgram!;
        } else {
          final nonSet = programs.firstWhere(
            (prog) => !prog.toLowerCase().contains('set'),
            orElse: () => programs.first,
          );
          selectedProgram = nonSet;
        }
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
        selectedSize:
            sizes.contains(state.selectedSize) ? state.selectedSize : "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedDivan>((event, emit) {
      // First, filter products by kasur + divan (without size filter)
      // to get all available options for headboard, sorong, and sizes
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

      // Now filter by headboard to get accurate sizes
      final filteredByHeadboard = filteredProducts
          .where((p) => (state.selectedHeadboard == AppStrings.noHeadboard
              ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
              : p.headboard == state.selectedHeadboard))
          .toList();
      final sizes = filteredByHeadboard.map((p) => p.ukuran).toSet().toList();
      final programs =
          filteredByHeadboard.map((p) => p.program).toSet().toList();

      // Auto-select ONLY when Set toggle is ON
      String selectedHeadboard;
      if (state.selectedHeadboard != null &&
          headboards.contains(state.selectedHeadboard)) {
        selectedHeadboard = state.selectedHeadboard!;
      } else if (state.isSetActive) {
        selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
            ? AppStrings.noHeadboard
            : (headboards.isNotEmpty
                ? headboards.first
                : AppStrings.noHeadboard);
      } else {
        selectedHeadboard =
            headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard;
      }

      String selectedSorong;
      if (state.selectedSorong != null &&
          sorongs.contains(state.selectedSorong)) {
        selectedSorong = state.selectedSorong!;
      } else if (state.isSetActive) {
        selectedSorong = sorongs.contains(AppStrings.noSorong)
            ? AppStrings.noSorong
            : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      } else {
        selectedSorong =
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong;
      }

      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Preserve current program if still valid
        if (state.selectedProgram != null &&
            programs.contains(state.selectedProgram)) {
          selectedProgram = state.selectedProgram!;
        } else {
          final nonSet = programs.firstWhere(
            (prog) => !prog.toLowerCase().contains('set'),
            orElse: () => programs.first,
          );
          selectedProgram = nonSet;
        }
      }

      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: sizes.contains(state.selectedSize)
            ? state.selectedSize
            : "", // Don't auto-select size, let user choose
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedHeadboard>((event, emit) {
      // First, filter products by kasur + divan + headboard (without size filter)
      // to get all available options for sorong and sizes
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

      // Now filter by sorong to get accurate sizes
      final filteredBySorong = filteredProducts
          .where((p) => (state.selectedSorong == AppStrings.noSorong
              ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
              : p.sorong == state.selectedSorong))
          .toList();
      final sizes = filteredBySorong.map((p) => p.ukuran).toSet().toList();
      final programs = filteredBySorong.map((p) => p.program).toSet().toList();

      // Auto-select ONLY when Set toggle is ON
      String selectedSorong;
      if (state.selectedSorong != null &&
          sorongs.contains(state.selectedSorong)) {
        selectedSorong = state.selectedSorong!;
      } else if (state.isSetActive) {
        // Set ON: prioritize "Tanpa Sorong"
        selectedSorong = sorongs.contains(AppStrings.noSorong)
            ? AppStrings.noSorong
            : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
      } else {
        // Set OFF: just use first available
        selectedSorong =
            sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong;
      }

      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Preserve current program if still valid
        if (state.selectedProgram != null &&
            programs.contains(state.selectedProgram)) {
          selectedProgram = state.selectedProgram!;
        } else {
          final nonSet = programs.firstWhere(
            (prog) => !prog.toLowerCase().contains('set'),
            orElse: () => programs.first,
          );
          selectedProgram = nonSet;
        }
      }

      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: sizes,
        selectedSize: sizes.contains(state.selectedSize)
            ? state.selectedSize
            : "", // Don't auto-select size, let user choose
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedSorong>((event, emit) {
      // Filter products by kasur + divan + headboard + sorong (without size filter)
      // to get all available sizes
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
        selectedSize:
            sizes.contains(state.selectedSize) ? state.selectedSize : "",
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
    });

    on<UpdateSelectedArea>((event, emit) {
      emit(state.copyWith(
        userSelectedArea: event.area, // Store user's manual area selection
        selectedArea: event.area, // Use for current filter
        // No longer need enum conversion
      ));
    });

    on<UpdateSelectedChannel>((event, emit) {
      emit(state.copyWith(
        selectedChannel: event.channel,
        selectedChannelModel: null,
        selectedBrand: "",
        selectedBrandModel: null,
        availableKasurs: [],
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        availableSizes: [],
        availablePrograms: [],
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
        selectedSize: "",
        selectedProgram: "",
      ));
    });

    on<UpdateSelectedBrand>((event, emit) {
      // Show toast for Spring Air, Therapedic, and Sleep Spa brands
      if (event.brand == "Spring Air" ||
          event.brand == "Therapedic" ||
          event.brand.toLowerCase().contains('spring air') ||
          event.brand.toLowerCase().contains('sleep spa')) {
        CustomToast.showToast(
          "Brand ${event.brand} akan menggunakan area nasional untuk pencarian produk.",
          ToastType.info,
        );
      }

      emit(state.copyWith(
        selectedBrand: event.brand,
        selectedBrandModel: null,
        availableKasurs: [],
        availableDivans: [],
        availableHeadboards: [],
        availableSorongs: [],
        availableSizes: [],
        availablePrograms: [],
        selectedKasur: AppStrings.noKasur,
        selectedDivan: AppStrings.noDivan,
        selectedHeadboard: AppStrings.noHeadboard,
        selectedSorong: AppStrings.noSorong,
        selectedSize: "",
        selectedProgram: "",
        filteredProducts: [],
        isFilterApplied: false,
      ));

      String? areaToUse;
      if (event.brand == "Spring Air" ||
          event.brand == "Therapedic" ||
          event.brand.toLowerCase().contains('spring air') ||
          event.brand.toLowerCase().contains('sleep spa')) {
        areaToUse = "Nasional";
      } else {
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
      // Filter produk berdasarkan semua selection sebelumnya DAN ukuran yang baru dipilih
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
              (state.selectedSorong == AppStrings.noSorong
                  ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
                  : p.sorong == state.selectedSorong) &&
              (event.ukuran.isNotEmpty ? p.ukuran == event.ukuran : true) &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      // Ambil program unik dari produk yang sudah difilter berdasarkan ukuran
      final programs = filteredProducts.map((p) => p.program).toSet().toList();

      // Pilih program secara otomatis berdasarkan filter (selalu pilih yang baru, jangan keep program lama)
      String selectedProgram = "";
      if (programs.isNotEmpty) {
        // Pilih program yang bukan set (atau program pertama jika semua set)
        final nonSet = programs.firstWhere(
          (prog) => !prog.toLowerCase().contains('set'),
          orElse: () => programs.first,
        );
        selectedProgram = nonSet;
      }

      emit(state.copyWith(
        selectedSize: event.ukuran,
        availablePrograms: programs,
        selectedProgram: selectedProgram,
      ));
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

      // If brand is Spring Air, Therapedic, or Sleep Spa, use "nasional" area
      if (event.selectedBrand == "Spring Air" ||
          event.selectedBrand == "Therapedic" ||
          (event.selectedBrand?.toLowerCase().contains('spring air') ??
              false) ||
          (event.selectedBrand?.toLowerCase().contains('sleep spa') ?? false)) {
        // Try using "nasional" first, if it fails, fallback to user's area
        areaToUse = "Nasional";
      } else {
        // For other brands, use user's selected area or default area
        areaToUse = state.userSelectedArea ?? state.selectedArea ?? '';
      }

      // Handle default values for divan, headboard, and sorong
      String selectedDivan = event.selectedDivan ?? AppStrings.noDivan;
      String selectedHeadboard =
          event.selectedHeadboard ?? AppStrings.noHeadboard;
      String selectedSorong = event.selectedSorong ?? AppStrings.noSorong;

      var filteredProducts = state.products.where((p) {
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

        final finalMatch = matchesArea &&
            matchesChannel &&
            matchesBrand &&
            matchesKasur &&
            matchesDivan &&
            matchesHeadboard &&
            matchesSorong &&
            matchesSize &&
            matchesProgram &&
            matchesSet;

        return finalMatch;
      }).toList();

      // Apply STRICT filtering - only show products that match ALL selected criteria

      // Apply additional strict filtering based on the debug analysis
      final strictlyFilteredProducts = filteredProducts.where((product) {
        bool passesStrictFilter = true;

        // Size filter (if selected)
        if (event.selectedSize != null && event.selectedSize!.isNotEmpty) {
          if (product.ukuran != event.selectedSize) {
            passesStrictFilter = false;
          }
        }

        // Program filter (if selected)
        if (event.selectedProgram != null &&
            event.selectedProgram!.isNotEmpty) {
          if (product.program != event.selectedProgram) {
            passesStrictFilter = false;
          }
        }

        // Kasur filter (if selected)
        if (event.selectedKasur != null &&
            event.selectedKasur!.isNotEmpty &&
            event.selectedKasur != AppStrings.noKasur) {
          if (product.kasur != event.selectedKasur) {
            passesStrictFilter = false;
          }
        }

        // Divan filter (if selected)
        if (selectedDivan != AppStrings.noDivan) {
          if (product.divan != selectedDivan) {
            passesStrictFilter = false;
          }
        }

        // Headboard filter (if selected)
        if (selectedHeadboard != AppStrings.noHeadboard) {
          if (product.headboard != selectedHeadboard) {
            passesStrictFilter = false;
          }
        }

        // Sorong filter (if selected)
        if (selectedSorong != AppStrings.noSorong) {
          if (product.sorong != selectedSorong) {
            passesStrictFilter = false;
          }
        }

        return passesStrictFilter;
      }).toList();

      // Update filteredProducts with strictly filtered results
      filteredProducts = strictlyFilteredProducts;

      // Check if products are truly duplicates or actually different
      if (filteredProducts.length > 1) {
        // Create a map to group products by their unique key
        final Map<String, List<ProductEntity>> productGroups = {};

        for (final product in filteredProducts) {
          // Create a unique key based on all filterable attributes
          final uniqueKey =
              '${product.ukuran}|${product.program}|${product.kasur}|${product.divan}|${product.headboard}|${product.sorong}|${product.brand}|${product.channel}';

          if (!productGroups.containsKey(uniqueKey)) {
            productGroups[uniqueKey] = [];
          }
          productGroups[uniqueKey]!.add(product);
        }

        // If all products have the same key, they are true duplicates - show only 1
        if (productGroups.length == 1) {
          final firstProduct = productGroups.values.first.first;
          filteredProducts = [firstProduct];
        }
      }

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
      double originalPrice = product.endUserPrice;
      double targetPrice = event.newPrice;

      // Ensure target price is not below bottom price analyst
      if (targetPrice < product.bottomPriceAnalyst) {
        targetPrice = product.bottomPriceAnalyst;
      }

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

      // Calculate discounts sequentially to ensure final price matches target
      for (int i = 0; i < maxDiscs.length; i++) {
        if (currentPrice <= targetPrice + 0.01) {
          // Already reached or exceeded target price
          splitDiscs.add(0);
          splitNominals.add(0);
          continue;
        }

        double maxAllowed = maxDiscs[i] * 100;
        if (maxAllowed <= 0) {
          splitDiscs.add(0);
          splitNominals.add(0);
          continue;
        }

        // Calculate how much discount is needed to reach target price
        // Formula: currentPrice * (1 - discount/100) = targetPrice
        // Solving for discount: discount = (1 - targetPrice/currentPrice) * 100
        double neededDiscount = (1 - (targetPrice / currentPrice)) * 100;

        // Use the minimum of needed discount and max allowed
        double useDisc =
            neededDiscount > maxAllowed ? maxAllowed : neededDiscount;
        if (useDisc < 0) useDisc = 0;

        splitDiscs.add(useDisc);
        double nominal = currentPrice * (useDisc / 100);
        splitNominals.add(nominal);

        // Update current price after applying this discount
        currentPrice = currentPrice * (1 - useDisc / 100);
      }

      // Verify final price matches target (with small tolerance for rounding)
      double verifyPrice = originalPrice;
      for (int i = 0; i < splitDiscs.length; i++) {
        if (splitDiscs[i] > 0) {
          verifyPrice = verifyPrice * (1 - splitDiscs[i] / 100);
        }
      }

      // If there's a significant difference, adjust the last non-zero discount
      if ((verifyPrice - targetPrice).abs() > 0.01 &&
          splitDiscs.any((d) => d > 0)) {
        // Find last non-zero discount index
        int lastIndex = -1;
        for (int i = splitDiscs.length - 1; i >= 0; i--) {
          if (splitDiscs[i] > 0) {
            lastIndex = i;
            break;
          }
        }

        if (lastIndex >= 0) {
          // Recalculate from beginning to lastIndex-1
          double priceBeforeLast = originalPrice;
          for (int i = 0; i < lastIndex; i++) {
            if (splitDiscs[i] > 0) {
              priceBeforeLast = priceBeforeLast * (1 - splitDiscs[i] / 100);
            }
          }

          // Calculate exact discount needed for last level
          if (priceBeforeLast > targetPrice + 0.01) {
            double exactDiscount = (1 - (targetPrice / priceBeforeLast)) * 100;
            double maxAllowed = maxDiscs[lastIndex] * 100;
            splitDiscs[lastIndex] = exactDiscount > maxAllowed
                ? maxAllowed
                : (exactDiscount < 0 ? 0 : exactDiscount);
            splitNominals[lastIndex] =
                priceBeforeLast * (splitDiscs[lastIndex] / 100);
          }
        }
      }

      updatedDiscounts[event.productId] = splitDiscs;
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
        selectedProgram: "", // Reset to empty
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
        String? userAreaName = _getAreaNameFromId(userAreaId);
        if (userAreaName != null) {
          final newState = state.copyWith(
            userSelectedArea: null,
            selectedArea: userAreaName,
          );

          emit(newState);

          CustomToast.showToast(
            "Area berhasil direset ke area default: $userAreaName",
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

    on<SetUserArea>((event, emit) async {
      // Smart matching: cari area yang cocok
      String? userAreaName = _getAreaNameFromId(event.areaId);

      if (userAreaName != null) {
        add(UpdateSelectedArea(userAreaName));
      } else if (state.availableAreas.isNotEmpty) {
        // Fallback ke Nasional atau first available
        final fallbackArea = state.availableAreas.contains("Nasional")
            ? "Nasional"
            : state.availableAreas.first;
        add(UpdateSelectedArea(fallbackArea));
      } else {
        // Tidak ada areas sama sekali
        emit(state.copyWith(
          userAreaId: event.areaId,
          selectedArea: null,
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
  /// Smart area matching - cocokkan area_id user dengan available areas
  /// Jika tidak cocok, fallback ke "Nasional"
  String? _getAreaNameFromId(int areaId, {List<String>? availableAreas}) {
    final regionToPlArea = <String, String>{
      // Jabodetabek variants
      'jabodetabek': 'Jabodetabek',
      'dki jakarta': 'Jabodetabek',
      'jakarta': 'Jabodetabek',
      'bogor': 'Jabodetabek',
      'depok': 'Jabodetabek',
      'tangerang': 'Jabodetabek',
      'bekasi': 'Jabodetabek',
      // Jawa
      'bandung': 'Bandung',
      'jawa barat': 'Bandung',
      'surabaya': 'Surabaya',
      'jawa timur': 'Surabaya',
      'semarang': 'Semarang',
      'jawa tengah': 'Semarang',
      'yogyakarta': 'Yogyakarta',
      'diy': 'Yogyakarta',
      'solo': 'Solo',
      'surakarta': 'Solo',
      'malang': 'Malang',
      'denpasar': 'Denpasar',
      'bali': 'Denpasar',
      // Sumatera - berbagai variasi spelling
      'medan': 'Medan',
      'sumatera utara': 'Medan',
      'sumatra utara': 'Medan',
      'palembang': 'Palembang',
      'sumatera selatan': 'Palembang',
      'sumatra selatan': 'Palembang',
      'pekanbaru': 'Pekanbaru',
      'riau': 'Pekanbaru',
      'padang': 'Padang',
      'sumatera barat': 'Padang',
      'sumatra barat': 'Padang',
      'lampung': 'Lampung',
      'bandar lampung': 'Lampung',
    };

    // Legacy ID mapping (untuk backward compatibility)
    final areaMapping = <int, List<String>>{
      0: ["Nasional"],
      1: ["Jabodetabek"],
      2: ["Bandung"],
      9: ["Medan"],
      10: ["Palembang"],
      11: ["Pekanbaru"],
      12: ["Padang"],
      13: ["Lampung"],
      20: ["Palembang"],
    };

    // Jika tidak ada availableAreas, gunakan state.availableAreas
    final areas = availableAreas ?? state.availableAreas;

    // Method 1: Cek dari areaMapping by ID
    final possibleNames = areaMapping[areaId];
    if (possibleNames != null) {
      for (final name in possibleNames) {
        if (areas.contains(name)) {
          return name;
        }
      }
    }

    // Method 2: Gunakan regionToPlArea mapping (lebih flexible)
    // Ini akan catch case seperti "SUMATRA SELATAN" → "Palembang"
    for (final entry in regionToPlArea.entries) {
      // Cek apakah ada area yang match dengan key (region name)
      for (final availableArea in areas) {
        final plAreaName = entry.value;
        if (availableArea == plAreaName && areas.contains(plAreaName)) {
          if (possibleNames?.any((n) => n.toLowerCase() == entry.key) ??
              false) {
            return plAreaName;
          }
        }
      }
    }

    // Method 3: Fallback ke "Nasional" jika tersedia
    if (areas.contains("Nasional")) {
      return "Nasional";
    }

    // Last resort: return area pertama yang tersedia
    if (areas.isNotEmpty) {
      return areas.first;
    }

    return null;
  }

  /// Helper: Match user area name dari CWE ke pl_areas name
  String? _matchAreaByName(String? userAreaName, List<String> availableAreas) {
    if (userAreaName == null || userAreaName.isEmpty) return null;

    final regionToPlArea = <String, String>{
      'jabodetabek': 'Jabodetabek',
      'dki jakarta': 'Jabodetabek',
      'jakarta': 'Jabodetabek',
      'bandung': 'Bandung',
      'jawa barat': 'Bandung',
      'medan': 'Medan',
      'sumatera utara': 'Medan',
      'sumatra utara': 'Medan',
      'palembang': 'Palembang',
      'sumatera selatan': 'Palembang',
      'sumatra selatan': 'Palembang',
      'pekanbaru': 'Pekanbaru',
      'riau': 'Pekanbaru',
      'padang': 'Padang',
      'sumatera barat': 'Padang',
      'sumatra barat': 'Padang',
      'lampung': 'Lampung',
      'bandar lampung': 'Lampung',
    };

    final normalizedName = userAreaName.toLowerCase().trim();

    // Exact match first
    final exactMatch = regionToPlArea[normalizedName];
    if (exactMatch != null && availableAreas.contains(exactMatch)) {
      return exactMatch;
    }

    // Partial match
    for (final entry in regionToPlArea.entries) {
      if (normalizedName.contains(entry.key) ||
          entry.key.contains(normalizedName)) {
        if (availableAreas.contains(entry.value)) {
          return entry.value;
        }
      }
    }

    // Direct match with available areas
    for (final area in availableAreas) {
      if (area.toLowerCase() == normalizedName) {
        return area;
      }
    }

    return null;
  }
}
