import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_product_usecase.dart';
import 'event/product_event.dart';
import 'state/product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductUseCase getProductUseCase;

  ProductBloc(this.getProductUseCase) : super(ProductInitial()) {
    on<FetchProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        print("📡 Fetching products from API on Product Bloc...");
        final products = await getProductUseCase();

        if (products.isEmpty) {
          print("⚠️ Tidak ada produk yang ditemukan dari API.");
          emit(ProductError("Produk tidak ditemukan."));
          return;
        }

        final areas = products.map((e) => e.area).toSet().toList();
        emit(ProductState(products: products, availableAreas: areas));

        print("✅ Produk berhasil dimuat: ${products.length} items.");
      } catch (e) {
        print("❌ Error fetching products: $e");
        emit(ProductError("Gagal mengambil data produk: ${e.toString()}"));
      }
    });

    on<ToggleSet>((event, emit) {
      final isSetActive = event.isSetActive;
      final filteredProducts = isSetActive
          ? state.products.where((p) => p.isSet == true).toList()
          : state.products;

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
        selectedKasur: "",
        availableDivans: [],
        selectedDivan: "",
        availableHeadboards: [],
        selectedHeadboard: "",
        availableSorongs: [],
        selectedSorong: "",
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
        selectedKasur: "",
        availableDivans: [],
        selectedDivan: "",
        availableHeadboards: [],
        selectedHeadboard: "",
        availableSorongs: [],
        selectedSorong: "",
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedBrand.isNotEmpty) {
        add(UpdateSelectedBrand(selectedBrand));
      }
    });

    on<UpdateSelectedBrand>((event, emit) {
      final filteredKasurs = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == event.brand &&
              (!state.isSetActive || p.isSet == true))
          .map((p) => p.kasur)
          .toSet()
          .toList();
      final selectedKasur =
          filteredKasurs.length == 1 ? filteredKasurs.first : "";

      emit(state.copyWith(
        selectedBrand: event.brand,
        availableKasurs: filteredKasurs,
        selectedKasur: selectedKasur,
        availableDivans: [],
        selectedDivan: "",
        availableHeadboards: [],
        selectedHeadboard: "",
        availableSorongs: [],
        selectedSorong: "",
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedKasur.isNotEmpty) {
        add(UpdateSelectedKasur(selectedKasur));
      }
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
      final selectedDivan = divans.length == 1 ? divans.first : "";

      emit(state.copyWith(
        selectedKasur: event.kasur,
        availableDivans: divans,
        selectedDivan: selectedDivan,
        availableHeadboards: [],
        selectedHeadboard: "",
        availableSorongs: [],
        selectedSorong: "",
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedDivan.isNotEmpty) {
        add(UpdateSelectedDivan(selectedDivan));
      }
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
      final selectedHeadboard = headboards.length == 1 ? headboards.first : "";

      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard: selectedHeadboard,
        availableSorongs: [],
        selectedSorong: "",
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedHeadboard.isNotEmpty) {
        add(UpdateSelectedHeadboard(selectedHeadboard));
      }
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
      final selectedSorong = sorongs.length == 1 ? sorongs.first : "";

      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: selectedSorong,
        availableSizes: [],
        selectedSize: "",
      ));
      if (selectedSorong.isNotEmpty) {
        add(UpdateSelectedSorong(selectedSorong));
      }
    });

    on<UpdateSelectedSorong>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == state.selectedKasur &&
              p.divan == state.selectedDivan &&
              p.headboard == state.selectedHeadboard &&
              p.sorong == event.sorong &&
              (!state.isSetActive || p.isSet == true))
          .toList();

      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      final selectedSize = sizes.length == 1 ? sizes.first : "";

      emit(state.copyWith(
        selectedSorong: event.sorong,
        availableSizes: sizes,
        selectedSize: selectedSize,
      ));
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

      print("🔍 Filtered Products Count: ${filteredProducts.length}");

      emit(state.copyWith(filteredProducts: filteredProducts));
    });
  }
}
