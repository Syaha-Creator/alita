import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {}

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
