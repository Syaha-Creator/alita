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
        // Get user area_id from AuthService
        final userAreaId = await AuthService.getCurrentUserAreaId();

        // Fetch areas from API or fallback to hardcoded values
        List<String> availableAreas = [];
        try {
          availableAreas = await _areaRepository.fetchAllAreaNames();
        } catch (e) {
          availableAreas = [
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
          ];
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

        // Initialize with empty state and user area if available
        if (userAreaId != null) {
          String? userAreaName = _getAreaNameFromId(userAreaId);
          if (userAreaName != null) {
            // Ensure user area is in the available areas list
            if (!uniqueAreas.contains(userAreaName)) {
              uniqueAreas.add(userAreaName);
            }

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
              availableAreas: uniqueAreas,
              availableChannels: availableChannels,
              availableChannelModels: [], // Only API data, no hardcoded enums
              availableBrands: availableBrands,
              availableBrandModels: [], // No longer needed
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
            availableAreas: uniqueAreas,
            availableChannels: availableChannels,
            availableChannelModels: [], // Will be populated from API
            availableBrands: availableBrands,
            availableBrandModels: [], // Will be populated from API
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
      String selectedSize = ""; // Don't auto-select size, let user choose

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
        selectedSize: "", // Reset size selection when kasur changes
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
              (state.selectedSize != null && state.selectedSize!.isNotEmpty
                  ? p.ukuran == state.selectedSize
                  : true) &&
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
        selectedSize: sizes.contains(state.selectedSize)
            ? state.selectedSize
            : "", // Don't auto-select size, let user choose
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
              (state.selectedSize != null && state.selectedSize!.isNotEmpty
                  ? p.ukuran == state.selectedSize
                  : true) &&
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
        selectedSize: sizes.contains(state.selectedSize)
            ? state.selectedSize
            : "", // Don't auto-select size, let user choose
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
              (state.selectedSize != null && state.selectedSize!.isNotEmpty
                  ? p.ukuran == state.selectedSize
                  : true) &&
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
      // Map area_id to area name
      String? userAreaName = _getAreaNameFromId(event.areaId);

      if (userAreaName != null && state.availableAreas.contains(userAreaName)) {
        add(UpdateSelectedArea(userAreaName));
      } else {
        // Emit state with area not available message
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
  String? _getAreaNameFromId(int areaId) {
    // Map area ID to area name
    switch (areaId) {
      case 0:
        return "Nasional";
      case 1:
        return "Jabodetabek";
      case 2:
        return "Bandung";
      case 3:
        return "Surabaya";
      case 4:
        return "Semarang";
      case 5:
        return "Yogyakarta";
      case 6:
        return "Solo";
      case 7:
        return "Malang";
      case 8:
        return "Denpasar";
      case 9:
        return "Medan";
      case 10:
        return "Palembang";
      default:
        return null;
    }
  }

  // Helper method to get available channels for a specific area
}
