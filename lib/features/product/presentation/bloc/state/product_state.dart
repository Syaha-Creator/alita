import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

class ProductState extends Equatable {
  final List<ProductEntity> products;
  final ProductEntity? selectProduct;
  final bool isSetActive;
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
  final Map<int, int> installmentMonths;
  final Map<int, double> installmentPerMonth;
  final Map<int, double> roundedPrices;
  final Map<int, double> priceChangePercentages;
  final Map<int, List<double>> productDiscountsPercentage;
  final Map<int, List<double>> productDiscountsNominal;

  const ProductState({
    this.products = const [],
    this.selectProduct,
    this.isSetActive = false,
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
    this.installmentMonths = const {},
    this.installmentPerMonth = const {},
    this.priceChangePercentages = const {},
    this.roundedPrices = const {},
    this.productDiscountsPercentage = const {},
    this.productDiscountsNominal = const {},
  });
  ProductState copyWith({
    List<ProductEntity>? products,
    ProductEntity? selectProduct,
    bool? isSetActive,
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
    Map<int, int>? installmentMonths,
    Map<int, double>? installmentPerMonth,
    Map<int, double>? priceChangePercentages,
    Map<int, double>? roundedPrices,
    Map<int, List<double>>? productDiscountsPercentage,
    Map<int, List<double>>? productDiscountsNominal,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectProduct: selectProduct ?? this.selectProduct,
      isSetActive: isSetActive ?? this.isSetActive,
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
      installmentMonths: installmentMonths ?? this.installmentMonths,
      installmentPerMonth: installmentPerMonth ?? this.installmentPerMonth,
      priceChangePercentages:
          priceChangePercentages ?? this.priceChangePercentages,
      roundedPrices: roundedPrices ?? this.roundedPrices,
      productDiscountsPercentage:
          productDiscountsPercentage ?? this.productDiscountsPercentage,
      productDiscountsNominal:
          productDiscountsNominal ?? this.productDiscountsNominal,
    );
  }

  @override
  List<Object?> get props => [
        products,
        selectProduct,
        isSetActive,
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
        installmentMonths,
        installmentPerMonth,
        priceChangePercentages,
        roundedPrices,
        productDiscountsPercentage,
        productDiscountsNominal
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
