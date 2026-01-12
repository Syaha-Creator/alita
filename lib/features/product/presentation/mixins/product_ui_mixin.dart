import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../helpers/product_area_matcher.dart';
import '../helpers/product_size_sorter.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';

/// Mixin untuk menangani semua UI-related event handlers
///
/// Handlers yang ditangani:
/// - ToggleSet: Toggle Set filter on/off
/// - SelectProduct: Select product untuk detail view
/// - ResetProductState: Reset state ke initial
/// - ResetUserSelectedArea: Reset area ke default user
/// - SetUserArea: Set area dari user
/// - ShowAreaNotAvailable: Show error area tidak tersedia
/// - ShowWhatsAppDialog: Show WhatsApp dialog
/// - HideWhatsAppDialog: Hide WhatsApp dialog
mixin ProductUIMixin on Bloc<ProductEvent, ProductState> {
  /// Register semua UI-related event handlers
  void registerUIHandlers() {
    on<ToggleSet>(_onToggleSet);
    on<SelectProduct>(_onSelectProduct);
    on<ResetProductState>(_onResetProductState);
    on<ResetUserSelectedArea>(_onResetUserSelectedArea);
    on<SetUserArea>(_onSetUserArea);
    on<ShowAreaNotAvailable>(_onShowAreaNotAvailable);
    on<ShowWhatsAppDialog>(_onShowWhatsAppDialog);
    on<HideWhatsAppDialog>(_onHideWhatsAppDialog);
  }

  /// Handler untuk toggle Set filter
  void _onToggleSet(
    ToggleSet event,
    Emitter<ProductState> emit,
  ) {
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
    final headboards = filteredByDivan.map((p) => p.headboard).toSet().toList();

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
    final sizes = ProductSizeSorter.sortSizes(
      filteredBySorong.map((p) => p.ukuran).toSet().toList(),
    );

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
  }

  /// Handler untuk select product
  void _onSelectProduct(
    SelectProduct event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(selectProduct: event.product));
  }

  /// Handler untuk reset product state
  void _onResetProductState(
    ResetProductState event,
    Emitter<ProductState> emit,
  ) {
    emit(const ProductState());
  }

  /// Handler untuk reset user selected area ke default
  void _onResetUserSelectedArea(
    ResetUserSelectedArea event,
    Emitter<ProductState> emit,
  ) async {
    // Get user's default area from AuthService
    final userAreaId = await AuthService.getCurrentUserAreaId();

    if (userAreaId != null) {
      String? userAreaName = ProductAreaMatcher.getAreaNameFromId(
        userAreaId,
        state.availableAreas,
      );
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
  }

  /// Handler untuk set user area
  void _onSetUserArea(
    SetUserArea event,
    Emitter<ProductState> emit,
  ) async {
    // Smart matching: cari area yang cocok
    String? userAreaName = ProductAreaMatcher.getAreaNameFromId(
      event.areaId,
      state.availableAreas,
    );

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
  }

  /// Handler untuk show area not available error
  void _onShowAreaNotAvailable(
    ShowAreaNotAvailable event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      userAreaId: event.areaId,
      selectedArea: null,
      areaNotAvailable: true,
    ));
  }

  /// Handler untuk show WhatsApp dialog
  void _onShowWhatsAppDialog(
    ShowWhatsAppDialog event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      showWhatsAppDialog: true,
      whatsAppBrand: event.brand,
      whatsAppArea: event.area,
      whatsAppChannel: event.channel,
    ));
  }

  /// Handler untuk hide WhatsApp dialog
  void _onHideWhatsAppDialog(
    HideWhatsAppDialog event,
    Emitter<ProductState> emit,
  ) {
    emit(state.copyWith(
      showWhatsAppDialog: false,
      whatsAppBrand: null,
      whatsAppArea: null,
      whatsAppChannel: null,
    ));
  }
}
