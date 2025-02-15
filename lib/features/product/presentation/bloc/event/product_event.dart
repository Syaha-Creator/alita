import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {}

class ToggleSet extends ProductEvent {
  final bool isSetActive;
  const ToggleSet(this.isSetActive);

  @override
  List<Object?> get props => [isSetActive];
}

class UpdateSelectedArea extends ProductEvent {
  final String area;
  const UpdateSelectedArea(this.area);

  @override
  List<Object?> get props => [area];
}

class UpdateSelectedChannel extends ProductEvent {
  final String channel;
  const UpdateSelectedChannel(this.channel);

  @override
  List<Object?> get props => [channel];
}

class UpdateSelectedBrand extends ProductEvent {
  final String brand;
  const UpdateSelectedBrand(this.brand);

  @override
  List<Object?> get props => [brand];
}

class UpdateSelectedKasur extends ProductEvent {
  final String kasur;
  const UpdateSelectedKasur(this.kasur);

  @override
  List<Object?> get props => [kasur];
}

class UpdateSelectedDivan extends ProductEvent {
  final String divan;
  const UpdateSelectedDivan(this.divan);

  @override
  List<Object?> get props => [divan];
}

class UpdateSelectedHeadboard extends ProductEvent {
  final String headboard;
  const UpdateSelectedHeadboard(this.headboard);

  @override
  List<Object?> get props => [headboard];
}

class UpdateSelectedSorong extends ProductEvent {
  final String sorong;
  const UpdateSelectedSorong(this.sorong);

  @override
  List<Object?> get props => [sorong];
}

class UpdateSelectedUkuran extends ProductEvent {
  final String ukuran;
  const UpdateSelectedUkuran(this.ukuran);

  @override
  List<Object?> get props => [ukuran];
}

class SelectProduct extends ProductEvent {
  final ProductEntity product;

  const SelectProduct(this.product);
}

class SaveInstallment extends ProductEvent {
  final int productId;
  final int months;
  final double perMonth;

  const SaveInstallment(this.productId, this.months, this.perMonth);
}

class RemoveInstallment extends ProductEvent {
  final int productId;

  const RemoveInstallment(this.productId);

  @override
  List<Object> get props => [productId];
}

class UpdateRoundedPrice extends ProductEvent {
  final int productId;
  final double newPrice;
  final double percentageChange;

  const UpdateRoundedPrice(
      this.productId, this.newPrice, this.percentageChange);
}

class FilterProducts extends ProductEvent {
  final List<ProductEntity> filteredProducts;
  const FilterProducts(this.filteredProducts);

  @override
  List<Object?> get props => [filteredProducts];
}

class ApplyFilters extends ProductEvent {
  final String? selectedArea;
  final String? selectedChannel;
  final String? selectedBrand;
  final String? selectedKasur;
  final String? selectedDivan;
  final String? selectedHeadboard;
  final String? selectedSorong;
  final String? selectedSize;

  const ApplyFilters({
    this.selectedArea,
    this.selectedChannel,
    this.selectedBrand,
    this.selectedKasur,
    this.selectedDivan,
    this.selectedHeadboard,
    this.selectedSorong,
    this.selectedSize,
  });

  @override
  List<Object?> get props => [
        selectedArea,
        selectedChannel,
        selectedBrand,
        selectedKasur,
        selectedDivan,
        selectedHeadboard,
        selectedSorong,
        selectedSize,
      ];
}
