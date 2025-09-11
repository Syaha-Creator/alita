import 'package:equatable/equatable.dart';

import '../../domain/entities/product_entity.dart';
import '../../data/models/channel_model.dart';
import '../../data/models/brand_model.dart';

class ProductState extends Equatable {
  final bool isFilterApplied;
  final List<ProductEntity> products;
  final ProductEntity? selectProduct;
  final bool isSetActive;
  final List<String> availableAreas;
  final String? selectedArea;
  final List<String> availableChannels;
  final String? selectedChannel;
  final List<ChannelModel> availableChannelModels;
  final ChannelModel? selectedChannelModel;
  final List<String> availableBrands;
  final String? selectedBrand;
  final List<BrandModel> availableBrandModels;
  final BrandModel? selectedBrandModel;
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
  final List<String> availablePrograms;
  final String? selectedProgram;
  final List<ProductEntity> filteredProducts;
  final Map<int, int> installmentMonths;
  final Map<int, double> installmentPerMonth;
  final Map<int, double> roundedPrices;
  final Map<int, double> priceChangePercentages;
  final Map<int, List<double>> productDiscountsPercentage;
  final Map<int, List<double>> productDiscountsNominal;
  final Map<int, List<int?>> productLeaderIds;
  final Map<int, String> productNotes;
  final int? userAreaId;
  final bool areaNotAvailable;
  final bool isUserAreaSet;
  final bool isLoading;
  final String? userSelectedArea; // Area yang dipilih user secara manual
  final bool showWhatsAppDialog;
  final String? whatsAppBrand;
  final String? whatsAppArea;
  final String? whatsAppChannel;

  const ProductState({
    this.isFilterApplied = false,
    this.products = const [],
    this.selectProduct,
    this.isSetActive = false,
    this.availableAreas = const [],
    this.selectedArea,
    this.availableChannels = const [],
    this.selectedChannel,
    this.availableChannelModels = const [],
    this.selectedChannelModel,
    this.availableBrands = const [],
    this.selectedBrand,
    this.availableBrandModels = const [],
    this.selectedBrandModel,
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
    this.availablePrograms = const [],
    this.selectedProgram,
    this.filteredProducts = const [],
    this.installmentMonths = const {},
    this.installmentPerMonth = const {},
    this.priceChangePercentages = const {},
    this.roundedPrices = const {},
    this.productDiscountsPercentage = const {},
    this.productDiscountsNominal = const {},
    this.productLeaderIds = const {},
    this.productNotes = const {},
    this.userAreaId,
    this.areaNotAvailable = false,
    this.isUserAreaSet = false,
    this.isLoading = false,
    this.userSelectedArea,
    this.showWhatsAppDialog = false,
    this.whatsAppBrand,
    this.whatsAppArea,
    this.whatsAppChannel,
  });

  ProductState copyWith({
    bool? isFilterApplied,
    List<ProductEntity>? products,
    ProductEntity? selectProduct,
    bool? isSetActive,
    List<String>? availableAreas,
    String? selectedArea,
    List<String>? availableChannels,
    String? selectedChannel,
    List<ChannelModel>? availableChannelModels,
    ChannelModel? selectedChannelModel,
    List<String>? availableBrands,
    String? selectedBrand,
    List<BrandModel>? availableBrandModels,
    BrandModel? selectedBrandModel,
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
    List<String>? availablePrograms,
    String? selectedProgram,
    List<ProductEntity>? filteredProducts,
    Map<int, int>? installmentMonths,
    Map<int, double>? installmentPerMonth,
    Map<int, double>? priceChangePercentages,
    Map<int, double>? roundedPrices,
    Map<int, List<double>>? productDiscountsPercentage,
    Map<int, List<double>>? productDiscountsNominal,
    Map<int, List<int?>>? productLeaderIds,
    Map<int, String>? productNotes,
    int? userAreaId,
    bool? areaNotAvailable,
    bool? isUserAreaSet,
    bool? isLoading,
    String? userSelectedArea,
    bool? showWhatsAppDialog,
    String? whatsAppBrand,
    String? whatsAppArea,
    String? whatsAppChannel,
  }) {
    return ProductState(
      isFilterApplied: isFilterApplied ?? this.isFilterApplied,
      products: products ?? this.products,
      selectProduct: selectProduct ?? this.selectProduct,
      isSetActive: isSetActive ?? this.isSetActive,
      availableAreas: availableAreas ?? this.availableAreas,
      selectedArea: selectedArea ?? this.selectedArea,
      availableChannels: availableChannels ?? this.availableChannels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      availableChannelModels:
          availableChannelModels ?? this.availableChannelModels,
      selectedChannelModel: selectedChannelModel ?? this.selectedChannelModel,
      availableBrands: availableBrands ?? this.availableBrands,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      availableBrandModels: availableBrandModels ?? this.availableBrandModels,
      selectedBrandModel: selectedBrandModel ?? this.selectedBrandModel,
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
      availablePrograms: availablePrograms ?? this.availablePrograms,
      selectedProgram: selectedProgram ?? this.selectedProgram,
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
      productLeaderIds: productLeaderIds ?? this.productLeaderIds,
      productNotes: productNotes ?? this.productNotes,
      userAreaId: userAreaId ?? this.userAreaId,
      areaNotAvailable: areaNotAvailable ?? this.areaNotAvailable,
      isUserAreaSet: isUserAreaSet ?? this.isUserAreaSet,
      isLoading: isLoading ?? this.isLoading,
      userSelectedArea: userSelectedArea ?? this.userSelectedArea,
      showWhatsAppDialog: showWhatsAppDialog ?? this.showWhatsAppDialog,
      whatsAppBrand: whatsAppBrand ?? this.whatsAppBrand,
      whatsAppArea: whatsAppArea ?? this.whatsAppArea,
      whatsAppChannel: whatsAppChannel ?? this.whatsAppChannel,
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
        availableChannelModels,
        selectedChannelModel,
        availableBrands,
        selectedBrand,
        availableBrandModels,
        selectedBrandModel,
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
        availablePrograms,
        selectedProgram,
        filteredProducts,
        installmentMonths,
        installmentPerMonth,
        priceChangePercentages,
        roundedPrices,
        productDiscountsPercentage,
        productDiscountsNominal,
        productLeaderIds,
        productNotes,
        userAreaId,
        areaNotAvailable,
        isUserAreaSet,
        isLoading,
        userSelectedArea,
        showWhatsAppDialog,
        whatsAppBrand,
        whatsAppArea,
        whatsAppChannel,
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
