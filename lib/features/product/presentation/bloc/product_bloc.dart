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

        final setProducts = products.where((p) => p.isSet == true).toList();

        print("✅ Produk berhasil dimuat: ${products.length} items.");
        print("🔥 Total produk dengan Set aktif: ${setProducts.length} items");
      } catch (e) {
        print("❌ Error fetching products: $e");
        emit(ProductError("Gagal mengambil data produk: ${e.toString()}"));
      }
    });

    on<ToggleSet>((event, emit) {
      emit(state.copyWith(isSetActive: event.isSetActive));

      if (event.isSetActive) {
        // ✅ Hanya tampilkan kasur yang memiliki `set == true`
        final filteredKasurs = state.products
            .where((p) =>
                p.isSet == true &&
                (state.selectedArea == null || p.area == state.selectedArea) &&
                (state.selectedChannel == null ||
                    p.channel == state.selectedChannel) &&
                (state.selectedBrand == null || p.brand == state.selectedBrand))
            .map((p) => p.kasur)
            .toSet()
            .toList();

        // ✅ Pertahankan kasur yang sudah dipilih jika masih valid
        final validSelectedKasur = state.selectedKasur != null &&
                filteredKasurs.contains(state.selectedKasur)
            ? state.selectedKasur
            : null;

        // 🔹 Jika kasur valid, update opsi Divan, Headboard, Sorong, dan Ukuran
        final filteredProducts = state.products
            .where((p) =>
                p.kasur == validSelectedKasur &&
                p.isSet == true &&
                (state.selectedArea == null || p.area == state.selectedArea) &&
                (state.selectedChannel == null ||
                    p.channel == state.selectedChannel) &&
                (state.selectedBrand == null || p.brand == state.selectedBrand))
            .toList();

        final divans = filteredProducts.map((p) => p.divan).toSet().toList();
        final headboards =
            filteredProducts.map((p) => p.headboard).toSet().toList();
        final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
        final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

        emit(state.copyWith(
          availableKasurs: filteredKasurs,
          selectedKasur: validSelectedKasur,
          availableDivans: divans,
          selectedDivan:
              divans.contains(state.selectedDivan) ? state.selectedDivan : null,
          availableHeadboards: headboards,
          selectedHeadboard: headboards.contains(state.selectedHeadboard)
              ? state.selectedHeadboard
              : null,
          availableSorongs: sorongs,
          selectedSorong: sorongs.contains(state.selectedSorong)
              ? state.selectedSorong
              : null,
          availableSizes: sizes,
          selectedSize:
              sizes.contains(state.selectedSize) ? state.selectedSize : null,
        ));
      } else {
        // ✅ Jika Set tidak aktif, tampilkan semua kasur sesuai area, channel, dan brand
        final allKasurs = state.products
            .where((p) =>
                (state.selectedArea == null || p.area == state.selectedArea) &&
                (state.selectedChannel == null ||
                    p.channel == state.selectedChannel) &&
                (state.selectedBrand == null || p.brand == state.selectedBrand))
            .map((p) => p.kasur)
            .toSet()
            .toList();

        // ✅ Pertahankan kasur yang sudah dipilih jika masih valid
        final validSelectedKasur = state.selectedKasur != null &&
                allKasurs.contains(state.selectedKasur)
            ? state.selectedKasur
            : null;

        // 🔹 Jika kasur valid, update opsi Divan, Headboard, Sorong, dan Ukuran
        final filteredProducts = state.products
            .where((p) =>
                p.kasur == validSelectedKasur &&
                (state.selectedArea == null || p.area == state.selectedArea) &&
                (state.selectedChannel == null ||
                    p.channel == state.selectedChannel) &&
                (state.selectedBrand == null || p.brand == state.selectedBrand))
            .toList();

        final divans = filteredProducts.map((p) => p.divan).toSet().toList();
        final headboards =
            filteredProducts.map((p) => p.headboard).toSet().toList();
        final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
        final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

        emit(state.copyWith(
          availableKasurs: allKasurs,
          selectedKasur: validSelectedKasur,
          availableDivans: divans,
          selectedDivan:
              divans.contains(state.selectedDivan) ? state.selectedDivan : null,
          availableHeadboards: headboards,
          selectedHeadboard: headboards.contains(state.selectedHeadboard)
              ? state.selectedHeadboard
              : null,
          availableSorongs: sorongs,
          selectedSorong: sorongs.contains(state.selectedSorong)
              ? state.selectedSorong
              : null,
          availableSizes: sizes,
          selectedSize:
              sizes.contains(state.selectedSize) ? state.selectedSize : null,
        ));
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
      final isSetActive = state.isSetActive;

      final filteredKasurs = state.products
          .where((p) =>
              (!isSetActive || p.isSet == true) && // Hanya Set jika aktif
              (state.selectedArea == null || p.area == state.selectedArea) &&
              (state.selectedChannel == null ||
                  p.channel == state.selectedChannel) &&
              (p.brand == event.brand))
          .toList();

      final kasurOptions = filteredKasurs.map((p) => p.kasur).toSet().toList();

      // ✅ Pilih otomatis jika hanya ada satu opsi
      final selectedKasur = kasurOptions.length == 1
          ? kasurOptions.first
          : (kasurOptions.contains(state.selectedKasur)
              ? state.selectedKasur
              : null);

      // 🔹 Update opsi dropdown lainnya
      final filteredProducts =
          filteredKasurs.where((p) => p.kasur == selectedKasur).toList();

      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      final selectedDivan = divans.length == 1 ? divans.first : null;
      final selectedHeadboard =
          headboards.length == 1 ? headboards.first : null;
      final selectedSorong = sorongs.length == 1 ? sorongs.first : null;
      final selectedSize = sizes.length == 1 ? sizes.first : null;

      emit(state.copyWith(
        selectedBrand: event.brand,
        availableKasurs: kasurOptions,
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

    on<UpdateSelectedKasur>((event, emit) {
      final filteredProducts = state.products
          .where((p) =>
              p.kasur == event.kasur &&
              (state.selectedArea == null || p.area == state.selectedArea) &&
              (state.selectedChannel == null ||
                  p.channel == state.selectedChannel) &&
              (state.selectedBrand == null || p.brand == state.selectedBrand))
          .toList();

      // 🔹 Ambil daftar unik untuk masing-masing opsi
      final divans = filteredProducts.map((p) => p.divan).toSet().toList();
      final headboards =
          filteredProducts.map((p) => p.headboard).toSet().toList();
      final sorongs = filteredProducts.map((p) => p.sorong).toSet().toList();
      final sizes = filteredProducts.map((p) => p.ukuran).toSet().toList();

      // 🔹 Cek apakah pilihan sebelumnya masih valid
      final selectedDivan =
          divans.contains(state.selectedDivan) ? state.selectedDivan : null;
      final selectedHeadboard = headboards.contains(state.selectedHeadboard)
          ? state.selectedHeadboard
          : null;
      final selectedSorong =
          sorongs.contains(state.selectedSorong) ? state.selectedSorong : null;
      final selectedSize =
          sizes.contains(state.selectedSize) ? state.selectedSize : null;

      // 🔹 Emit state baru dengan data yang diperbarui
      emit(state.copyWith(
        selectedKasur: event.kasur,
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

    on<FilterProducts>((event, emit) {
      emit(state.copyWith(filteredProducts: event.filteredProducts));
    });

    on<ApplyFilters>((event, emit) {
      final filteredProducts = state.products.where((p) {
        final matchesArea =
            event.selectedArea == null || p.area == event.selectedArea;
        final matchesChannel =
            event.selectedChannel == null || p.channel == event.selectedChannel;
        final matchesBrand =
            event.selectedBrand == null || p.brand == event.selectedBrand;
        final matchesKasur =
            event.selectedKasur == null || p.kasur == event.selectedKasur;
        final matchesDivan =
            event.selectedDivan == null || p.divan == event.selectedDivan;
        final matchesHeadboard = event.selectedHeadboard == null ||
            p.headboard == event.selectedHeadboard;
        final matchesSorong =
            event.selectedSorong == null || p.sorong == event.selectedSorong;
        final matchesSize =
            event.selectedSize == null || p.ukuran == event.selectedSize;

        // ✅ Tambahkan filter untuk hanya menampilkan produk dengan set jika set aktif
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

      emit(state.copyWith(filteredProducts: filteredProducts));
    });
  }
}
