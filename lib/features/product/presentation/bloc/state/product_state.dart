import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

class ProductState extends Equatable {
  final List<ProductEntity> products;
  final List<String> availableAreas;
  final String? selectedArea;
  final List<String> availableChannels;
  final String? selectedChannel;
  final List<String> availableBrands;
  final String? selectedBrand;
  final List<String> availableKasurs;
  final String? selectedKasur;
  final List<String> availableDivans;
  final String? selectedDivan;
  final List<String> availableHeadboards;
  final String? selectedHeadboard;
  final List<String> availableSorongs;
  final String? selectedSorong;
  final List<String> availableSizes;
  final String? selectedSize;
  final List<ProductEntity> filteredProducts;

  const ProductState({
    this.products = const [],
    this.availableAreas = const [],
    this.selectedArea,
    this.availableChannels = const [],
    this.selectedChannel,
    this.availableBrands = const [],
    this.selectedBrand,
    this.availableKasurs = const [],
    this.selectedKasur,
    this.availableDivans = const [],
    this.selectedDivan,
    this.availableHeadboards = const [],
    this.selectedHeadboard,
    this.availableSorongs = const [],
    this.selectedSorong,
    this.availableSizes = const [],
    this.selectedSize,
    this.filteredProducts = const [],
  });
  ProductState copyWith({
    List<ProductEntity>? products,
    List<String>? availableAreas,
    String? selectedArea,
    List<String>? availableChannels,
    String? selectedChannel,
    List<String>? availableBrands,
    String? selectedBrand,
    List<String>? availableKasurs,
    String? selectedKasur,
    List<String>? availableDivans,
    String? selectedDivan,
    List<String>? availableHeadboards,
    String? selectedHeadboard,
    List<String>? availableSorongs,
    String? selectedSorong,
    List<String>? availableSizes,
    String? selectedSize,
    List<ProductEntity>? filteredProducts,
  }) {
    return ProductState(
      products: products ?? this.products,
      availableAreas: availableAreas ?? this.availableAreas,
      selectedArea: selectedArea ?? this.selectedArea,
      availableChannels: availableChannels ?? this.availableChannels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      availableBrands: availableBrands ?? this.availableBrands,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      availableKasurs: availableKasurs ?? this.availableKasurs,
      selectedKasur: selectedKasur ?? this.selectedKasur,
      availableDivans: availableDivans ?? this.availableDivans,
      selectedDivan: selectedDivan ?? this.selectedDivan,
      availableHeadboards: availableHeadboards ?? this.availableHeadboards,
      selectedHeadboard: selectedHeadboard ?? this.selectedHeadboard,
      availableSorongs: availableSorongs ?? this.availableSorongs,
      selectedSorong: selectedSorong ?? this.selectedSorong,
      availableSizes: availableSizes ?? this.availableSizes,
      selectedSize: selectedSize ?? this.selectedSize,
      filteredProducts: filteredProducts ?? this.filteredProducts,
    );
  }

  @override
  List<Object?> get props => [
        products,
        availableAreas,
        selectedArea,
        availableChannels,
        selectedChannel,
        availableBrands,
        selectedBrand,
        availableKasurs,
        selectedKasur,
        availableDivans,
        selectedDivan,
        availableHeadboards,
        selectedHeadboard,
        availableSorongs,
        selectedSorong,
        availableSizes,
        selectedSize,
        filteredProducts,
      ];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  const ProductLoaded(List<ProductEntity> products) : super(products: products);
}

class ProductFiltered extends ProductState {
  const ProductFiltered(List<ProductEntity> filteredProducts)
      : super(filteredProducts: filteredProducts);
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
