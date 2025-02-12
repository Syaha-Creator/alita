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
        print("📡 Fetching products from API...");
        final products = await getProductUseCase();

        if (products.isEmpty) {
          print("⚠️ Tidak ada produk yang ditemukan dari API.");
          emit(ProductError("Produk tidak ditemukan."));
          return;
        }

        // Mengambil area yang unik dari produk
        final areas = products.map((e) => e.area).toSet().toList();

        // Emit state baru dengan produk yang sudah di-fetch
        emit(ProductState(
          products: products, // ✅ Pastikan products terupdate
          availableAreas:
              areas, // ✅ Gunakan availableAreas, bukan availableChannels
        ));

        print("✅ Produk berhasil dimuat: ${products.length} items.");
      } catch (e) {
        print("❌ Error fetching products: $e");
        emit(ProductError("Gagal mengambil data produk: ${e.toString()}"));
      }
    });

    on<UpdateSelectedArea>((event, emit) {
      final filteredProducts =
          state.products.where((p) => p.area == event.area).toList();
      final channels = filteredProducts.map((p) => p.channel).toSet().toList();
      emit(state.copyWith(
        selectedArea: event.area,
        availableChannels: channels,
        selectedChannel: null,
      ));
    });

    on<UpdateSelectedChannel>((event, emit) {
      final filteredProducts = state.products
          .where(
              (p) => p.area == state.selectedArea && p.channel == event.channel)
          .toList();
      final brands = filteredProducts.map((p) => p.brand).toSet().toList();
      emit(state.copyWith(
        selectedChannel: event.channel,
        availableBrands: brands,
        selectedBrand: null,
      ));
    });

    on<UpdateSelectedBrand>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == event.brand)
          .toList();
      final kasurs = filteredProducts.map((p) => p.kasur).toSet().toList();
      emit(state.copyWith(
        selectedBrand: event.brand,
        availableKasurs: kasurs,
        selectedKasur: null,
      ));
    });

    on<UpdateSelectedKasur>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == event.kasur)
          .toList();
      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      emit(state.copyWith(
        selectedKasur: event.kasur,
        availableDivans: divans,
        selectedDivan: null,
      ));
    });

    on<UpdateSelectedDivan>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.area == state.selectedArea &&
              p.channel == state.selectedChannel &&
              p.brand == state.selectedBrand &&
              p.kasur == state.selectedKasur &&
              p.divan == event.divan)
          .toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      emit(state.copyWith(
        selectedDivan: event.divan,
        availableHeadboards: headboards,
        selectedHeadboard: null,
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
              p.headboard == event.headboard)
          .toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      emit(state.copyWith(
        selectedHeadboard: event.headboard,
        availableSorongs: sorongs,
        selectedSorong: null,
      ));
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
              p.sorong == event.sorong)
          .toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();
      emit(state.copyWith(
        selectedSorong: event.sorong,
        availableSizes: sizes,
        selectedSize: null,
      ));
    });

    on<UpdateSelectedUkuran>((event, emit) {
      emit(state.copyWith(selectedSize: event.ukuran));
    });
  }
}
