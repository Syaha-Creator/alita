import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../helpers/product_size_sorter.dart';
import '../../../../config/dependency_injection.dart';
import '../../data/repositories/brand_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/models/channel_model.dart';

/// Mixin untuk filter-related event handlers
///
/// Memisahkan filter logic dari ProductBloc untuk meningkatkan maintainability
mixin ProductFilterMixin on Bloc<ProductEvent, ProductState> {
  /// Register filter-related event handlers
  void registerFilterHandlers() {
    on<UpdateSelectedKasur>(_onUpdateSelectedKasur);
    on<UpdateSelectedDivan>(_onUpdateSelectedDivan);
    on<UpdateSelectedHeadboard>(_onUpdateSelectedHeadboard);
    on<UpdateSelectedSorong>(_onUpdateSelectedSorong);
    on<UpdateSelectedArea>(_onUpdateSelectedArea);
    on<UpdateSelectedChannel>(_onUpdateSelectedChannel);
    on<UpdateSelectedBrand>(_onUpdateSelectedBrand);
    on<UpdateSelectedUkuran>(_onUpdateSelectedUkuran);
    on<UpdateSelectedProgram>(_onUpdateSelectedProgram);
    on<FilterProducts>(_onFilterProducts);
    on<ApplyFilters>(_onApplyFilters);
    on<ClearFilters>(_onClearFilters);
    on<ResetFilters>(_onResetFilters);
  }

  void _onUpdateSelectedKasur(
    UpdateSelectedKasur event,
    Emitter<ProductState> emit,
  ) {
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
    // If no products match the selected kasur, set to "Tanpa" options
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

    // Extract divans, ensuring "Tanpa Divan" is included if any product has empty divan
    final divansSet = filteredProducts.map((p) => p.divan).toSet();
    final divans = divansSet.toList();
    if (filteredProducts
        .any((p) => p.divan.isEmpty || p.divan == AppStrings.noDivan)) {
      if (!divans.contains(AppStrings.noDivan)) {
        divans.add(AppStrings.noDivan);
      }
    }

    // Extract headboards, ensuring "Tanpa Headboard" is included if any product has empty headboard
    final headboardsSet = filteredProducts.map((p) => p.headboard).toSet();
    final headboards = headboardsSet.toList();
    if (filteredProducts.any(
        (p) => p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)) {
      if (!headboards.contains(AppStrings.noHeadboard)) {
        headboards.add(AppStrings.noHeadboard);
      }
    }

    // Extract sorongs, ensuring "Tanpa Sorong" is included if any product has empty sorong
    final sorongsSet = filteredProducts.map((p) => p.sorong).toSet();
    final sorongs = sorongsSet.toList();
    if (filteredProducts
        .any((p) => p.sorong.isEmpty || p.sorong == AppStrings.noSorong)) {
      if (!sorongs.contains(AppStrings.noSorong)) {
        sorongs.add(AppStrings.noSorong);
      }
    }
    final sizes = ProductSizeSorter.sortSizes(
      filteredProducts.map((p) => p.ukuran).toSet().toList(),
    );
    final programs = filteredProducts.map((p) => p.program).toSet().toList();

    // Set to "Tanpa" options when kasur is selected
    String? selectedDivan;
    if (state.selectedDivan != null && divans.contains(state.selectedDivan)) {
      // Keep current selection if still valid
      selectedDivan = state.selectedDivan;
    } else {
      // Set to "Tanpa Divan" when kasur changes
      selectedDivan =
          divans.contains(AppStrings.noDivan) ? AppStrings.noDivan : null;
    }

    String? selectedHeadboard;
    if (state.selectedHeadboard != null &&
        headboards.contains(state.selectedHeadboard)) {
      // Keep current selection if still valid
      selectedHeadboard = state.selectedHeadboard;
    } else {
      // Set to "Tanpa Headboard" when kasur changes
      selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : null;
    }

    String? selectedSorong;
    if (state.selectedSorong != null &&
        sorongs.contains(state.selectedSorong)) {
      // Keep current selection if still valid
      selectedSorong = state.selectedSorong;
    } else {
      // Set to "Tanpa Sorong" when kasur changes
      selectedSorong =
          sorongs.contains(AppStrings.noSorong) ? AppStrings.noSorong : null;
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
  }

  void _onUpdateSelectedDivan(
    UpdateSelectedDivan event,
    Emitter<ProductState> emit,
  ) {
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

    // Extract headboards, ensuring "Tanpa Headboard" is included if any product has empty headboard
    final headboardsSet = event.divan == AppStrings.noDivan
        ? state.products
            .where((p) =>
                (state.selectedKasur == AppStrings.noKasur
                    ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                    : p.kasur == state.selectedKasur) &&
                (!state.isSetActive || p.isSet == true))
            .map((p) => p.headboard)
            .toSet()
        : filteredProducts.map((p) => p.headboard).toSet();

    final headboards = headboardsSet.toList();
    // Add "Tanpa Headboard" if any product has empty headboard
    final sourceProducts = event.divan == AppStrings.noDivan
        ? state.products
            .where((p) =>
                (state.selectedKasur == AppStrings.noKasur
                    ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                    : p.kasur == state.selectedKasur) &&
                (!state.isSetActive || p.isSet == true))
            .toList()
        : filteredProducts;

    if (sourceProducts.any(
        (p) => p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)) {
      if (!headboards.contains(AppStrings.noHeadboard)) {
        headboards.add(AppStrings.noHeadboard);
      }
    }

    // Extract sorongs, ensuring "Tanpa Sorong" is included if any product has empty sorong
    final sorongsSet = filteredProducts.map((p) => p.sorong).toSet();
    final sorongs = sorongsSet.toList();
    if (filteredProducts
        .any((p) => p.sorong.isEmpty || p.sorong == AppStrings.noSorong)) {
      if (!sorongs.contains(AppStrings.noSorong)) {
        sorongs.add(AppStrings.noSorong);
      }
    }

    // Now filter by headboard to get accurate sizes
    final filteredByHeadboard = filteredProducts
        .where((p) => (state.selectedHeadboard == AppStrings.noHeadboard
            ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
            : p.headboard == state.selectedHeadboard))
        .toList();
    final sizes = ProductSizeSorter.sortSizes(
      filteredByHeadboard.map((p) => p.ukuran).toSet().toList(),
    );
    final programs = filteredByHeadboard.map((p) => p.program).toSet().toList();

    // Auto-select logic: prioritize "Tanpa X" options when available
    String selectedHeadboard;
    if (state.selectedHeadboard != null &&
        headboards.contains(state.selectedHeadboard)) {
      // Keep current selection if still valid
      selectedHeadboard = state.selectedHeadboard!;
    } else if (state.isSetActive) {
      // Set ON: prioritize "Tanpa Headboard" or first available
      selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : (headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard);
    } else {
      // Set OFF: prioritize "Tanpa Headboard" if available, otherwise first available
      selectedHeadboard = headboards.contains(AppStrings.noHeadboard)
          ? AppStrings.noHeadboard
          : (headboards.isNotEmpty ? headboards.first : AppStrings.noHeadboard);
    }

    String selectedSorong;
    if (state.selectedSorong != null &&
        sorongs.contains(state.selectedSorong)) {
      // Keep current selection if still valid
      selectedSorong = state.selectedSorong!;
    } else if (state.isSetActive) {
      // Set ON: prioritize "Tanpa Sorong" or first available
      selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
    } else {
      // Set OFF: prioritize "Tanpa Sorong" if available, otherwise first available
      selectedSorong = sorongs.contains(AppStrings.noSorong)
          ? AppStrings.noSorong
          : (sorongs.isNotEmpty ? sorongs.first : AppStrings.noSorong);
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
  }

  void _onUpdateSelectedHeadboard(
    UpdateSelectedHeadboard event,
    Emitter<ProductState> emit,
  ) {
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
                ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
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
    final sizes = ProductSizeSorter.sortSizes(
      filteredBySorong.map((p) => p.ukuran).toSet().toList(),
    );
    final programs = filteredBySorong.map((p) => p.program).toSet().toList();

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
          sorongs.contains(AppStrings.noSorong) ? AppStrings.noSorong : "";
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
  }

  void _onUpdateSelectedSorong(
    UpdateSelectedSorong event,
    Emitter<ProductState> emit,
  ) {
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
                ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
                : p.headboard == state.selectedHeadboard) &&
            (event.sorong == AppStrings.noSorong
                ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
                : p.sorong == event.sorong) &&
            (!state.isSetActive || p.isSet == true))
        .toList();
    final sizes = ProductSizeSorter.sortSizes(
      filteredProducts.map((p) => p.ukuran).toSet().toList(),
    );
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
  }

  void _onUpdateSelectedArea(
    UpdateSelectedArea event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      userSelectedArea: event.area, // Store user's manual area selection
      selectedArea: event.area, // Use for current filter
      // No longer need enum conversion
    ));
  }

  Future<void> _onUpdateSelectedChannel(
    UpdateSelectedChannel event,
    Emitter<ProductState> emit,
  ) async {
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

    // Filter brand berdasarkan channel yang dipilih
    try {
      final brandRepo = locator<BrandRepository>();
      final channelRepo = locator<ChannelRepository>();
      final channels = await channelRepo.fetchAllChannels();
      final channel = channels.firstWhere(
        (c) => c.name.toLowerCase() == event.channel.toLowerCase(),
        orElse: () => ChannelModel(id: 0, name: event.channel),
      );
      final channelId = channel.id == 0 ? null : channel.id;
      final brands = await brandRepo.fetchAllBrandNames(channelId: channelId);
      emit(state.copyWith(
        availableBrands: brands,
        selectedBrand: "",
        selectedBrandModel: null,
      ));
    } catch (_) {
      // Jika gagal, biarkan daftar brand sebelumnya
    }
  }

  void _onUpdateSelectedBrand(
    UpdateSelectedBrand event,
    Emitter<ProductState> emit,
  ) {
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
  }

  void _onUpdateSelectedUkuran(
    UpdateSelectedUkuran event,
    Emitter<ProductState> emit,
  ) {
    // Filter produk berdasarkan semua selection sebelumnya DAN ukuran yang baru dipilih
    // "Tanpa" means don't filter (show all), not "must be empty"
    final filteredProducts = state.products
        .where((p) =>
            (state.selectedKasur == AppStrings.noKasur
                ? (p.kasur.isEmpty || p.kasur == AppStrings.noKasur)
                : p.kasur == state.selectedKasur) &&
            // If null or "Tanpa", show all products (don't filter by divan)
            (state.selectedDivan == null ||
                    state.selectedDivan == AppStrings.noDivan
                ? true
                : p.divan == state.selectedDivan) &&
            // If null or "Tanpa", show all products (don't filter by headboard)
            (state.selectedHeadboard == null ||
                    state.selectedHeadboard == AppStrings.noHeadboard
                ? true
                : p.headboard == state.selectedHeadboard) &&
            // If null or "Tanpa", show all products (don't filter by sorong)
            (state.selectedSorong == null ||
                    state.selectedSorong == AppStrings.noSorong
                ? true
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
  }

  void _onUpdateSelectedProgram(
    UpdateSelectedProgram event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(selectedProgram: event.program));
  }

  void _onFilterProducts(
    FilterProducts event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(filteredProducts: event.filteredProducts));
  }

  void _onApplyFilters(
    ApplyFilters event,
    Emitter<ProductState> emit,
  ) async {
    // Determine which area to use based on brand selection
    String areaToUse = event.selectedArea ?? '';

    // If brand is Spring Air, Therapedic, or Sleep Spa, use "nasional" area
    if (event.selectedBrand == "Spring Air" ||
        event.selectedBrand == "Therapedic" ||
        (event.selectedBrand?.toLowerCase().contains('spring air') ?? false) ||
        (event.selectedBrand?.toLowerCase().contains('sleep spa') ?? false)) {
      // Try using "nasional" first, if it fails, fallback to user's area
      areaToUse = "Nasional";
    } else {
      // For other brands, use user's selected area or default area
      areaToUse = state.userSelectedArea ?? state.selectedArea ?? '';
    }

    // Handle default values for divan, headboard, and sorong
    String? selectedDivan = event.selectedDivan;
    String? selectedHeadboard = event.selectedHeadboard;
    String? selectedSorong = event.selectedSorong;

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
      // If null, show all products (don't filter by divan)
      // If "Tanpa Divan", show only products without divan
      // If specific value, show only products with that divan
      final matchesDivan = selectedDivan == null
          ? true
          : (selectedDivan == AppStrings.noDivan
              ? (p.divan.isEmpty || p.divan == AppStrings.noDivan)
              : p.divan == selectedDivan);

      // Fixed logic for headboard filter
      // If null, show all products (don't filter by headboard)
      // If "Tanpa Headboard", show only products without headboard
      // If specific value, show only products with that headboard
      final matchesHeadboard = selectedHeadboard == null
          ? true
          : (selectedHeadboard == AppStrings.noHeadboard
              ? (p.headboard.isEmpty || p.headboard == AppStrings.noHeadboard)
              : p.headboard == selectedHeadboard);

      // Fixed logic for sorong filter
      // If null, show all products (don't filter by sorong)
      // If "Tanpa Sorong", show only products without sorong
      // If specific value, show only products with that sorong
      final matchesSorong = selectedSorong == null
          ? true
          : (selectedSorong == AppStrings.noSorong
              ? (p.sorong.isEmpty || p.sorong == AppStrings.noSorong)
              : p.sorong == selectedSorong);
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
      if (event.selectedProgram != null && event.selectedProgram!.isNotEmpty) {
        if (product.program != event.selectedProgram) {
          passesStrictFilter = false;
        }
      }

      // Kasur filter
      // If null or empty, don't filter (show all)
      // If "Tanpa Kasur", only show products without kasur
      // If specific value, only show products with that kasur
      if (event.selectedKasur != null && event.selectedKasur!.isNotEmpty) {
        if (event.selectedKasur == AppStrings.noKasur) {
          // Only allow products without kasur
          if (product.kasur.isNotEmpty && product.kasur != AppStrings.noKasur) {
            passesStrictFilter = false;
          }
        } else {
          // Only allow products with specific kasur
          if (product.kasur != event.selectedKasur) {
            passesStrictFilter = false;
          }
        }
      }

      // Divan filter
      // If null, don't filter (show all)
      // If "Tanpa Divan", only show products without divan
      // If specific value, only show products with that divan
      if (selectedDivan != null) {
        if (selectedDivan == AppStrings.noDivan) {
          // Only allow products without divan
          if (product.divan.isNotEmpty && product.divan != AppStrings.noDivan) {
            passesStrictFilter = false;
          }
        } else {
          // Only allow products with specific divan
          if (product.divan != selectedDivan) {
            passesStrictFilter = false;
          }
        }
      }

      // Headboard filter
      // If null, don't filter (show all)
      // If "Tanpa Headboard", only show products without headboard
      // If specific value, only show products with that headboard
      if (selectedHeadboard != null) {
        if (selectedHeadboard == AppStrings.noHeadboard) {
          // Only allow products without headboard
          if (product.headboard.isNotEmpty &&
              product.headboard != AppStrings.noHeadboard) {
            passesStrictFilter = false;
          }
        } else {
          // Only allow products with specific headboard
          if (product.headboard != selectedHeadboard) {
            passesStrictFilter = false;
          }
        }
      }

      // Sorong filter
      // If null, don't filter (show all)
      // If "Tanpa Sorong", only show products without sorong
      // If specific value, only show products with that sorong
      if (selectedSorong != null) {
        if (selectedSorong == AppStrings.noSorong) {
          // Only allow products without sorong
          if (product.sorong.isNotEmpty &&
              product.sorong != AppStrings.noSorong) {
            passesStrictFilter = false;
          }
        } else {
          // Only allow products with specific sorong
          if (product.sorong != selectedSorong) {
            passesStrictFilter = false;
          }
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
  }

  void _onClearFilters(
    ClearFilters event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      filteredProducts: [],
      isFilterApplied: false,
    ));
  }

  void _onResetFilters(
    ResetFilters event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      filteredProducts: [],
      isFilterApplied: false,
      selectedChannel: "", // Reset to empty
      selectedBrand: "", // Reset to empty
      selectedKasur: AppStrings.noKasur, // Reset to default
      selectedDivan: AppStrings.noDivan, // Reset to default
      selectedHeadboard: AppStrings.noHeadboard, // Reset to default
      selectedSorong: AppStrings.noSorong, // Reset to default
      selectedSize: "",
      selectedProgram: "",
    ));
  }
}
