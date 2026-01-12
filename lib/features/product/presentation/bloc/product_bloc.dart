import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../data/repositories/area_repository.dart';
import '../../data/repositories/channel_repository.dart';
import '../../data/repositories/brand_repository.dart';
import '../../domain/usecases/get_product_usecase.dart';
import '../helpers/product_area_matcher.dart';
import '../helpers/product_size_sorter.dart';
import '../mixins/product_filter_mixin.dart';
import '../mixins/product_price_mixin.dart';
import '../mixins/product_ui_mixin.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState>
    with ProductFilterMixin, ProductPriceMixin, ProductUIMixin {
  final GetProductUseCase getProductUseCase;
  final AreaRepository _areaRepository;
  final ChannelRepository _channelRepository;
  final BrandRepository _brandRepository;

  ProductBloc({
    required this.getProductUseCase,
    required AreaRepository areaRepository,
    required ChannelRepository channelRepository,
    required BrandRepository brandRepository,
  })  : _areaRepository = areaRepository,
        _channelRepository = channelRepository,
        _brandRepository = brandRepository,
        super(ProductInitial()) {
    // Register filter handlers from mixin
    registerFilterHandlers();

    // Register price handlers from mixin
    registerPriceHandlers();

    // Register UI handlers from mixin
    registerUIHandlers();

    on<AppStarted>((event, emit) {
      // Don't fetch products automatically - wait for user to select filters
      add(InitializeDropdowns());
    });

    on<InitializeDropdowns>((event, emit) async {
      try {
        // Get user area info from AuthService
        final userAreaId = await AuthService.getCurrentUserAreaId();
        final userAreaNameFromCWE = await AuthService.getCurrentUserAreaName();

        final results = await Future.wait([
          _areaRepository.fetchAllAreaNames().catchError((e) => <String>[]),
          _channelRepository
              .fetchAllChannelNames()
              .catchError((e) => <String>[]),
          _brandRepository.fetchAllBrandNames().catchError((e) => <String>[]),
        ], eagerError: false);

        // Extract results
        final availableAreas = results[0];
        final availableChannels = results[1];
        final availableBrands = results[2];

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
          String? userAreaName;

          // Method 1: Match by name dari CWE (e.g., "SUMATRA SELATAN" → "Palembang")
          if (userAreaNameFromCWE != null && uniqueAreas.isNotEmpty) {
            userAreaName = ProductAreaMatcher.matchAreaByName(
              userAreaNameFromCWE,
              uniqueAreas,
            );
          }

          // Method 2: Match by ID (fallback)
          if (userAreaName == null && userAreaId != null) {
            userAreaName = ProductAreaMatcher.getAreaNameFromId(
              userAreaId,
              uniqueAreas,
            );
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
        final availableSizes = ProductSizeSorter.sortSizes(
          products.map((p) => p.ukuran).toSet().toList(),
        );

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
  }
}
