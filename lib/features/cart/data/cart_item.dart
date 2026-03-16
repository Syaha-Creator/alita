import 'package:freezed_annotation/freezed_annotation.dart';

import '../../pricelist/data/models/product.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

@freezed
class CartBonusSnapshot with _$CartBonusSnapshot {
  const factory CartBonusSnapshot({
    @Default('') String name,
    @JsonKey(fromJson: _parseInt) @Default(0) int qty,
    @Default('') String sku,
  }) = _CartBonusSnapshot;

  factory CartBonusSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CartBonusSnapshotFromJson(json);
}

@freezed
class CartItem with _$CartItem {
  const CartItem._();

  const factory CartItem({
    required Product product,
    Product? masterProduct,
    @JsonKey(fromJson: _parseInt) @Default(1) int quantity,
    @Default('') String kasurSku,
    @Default('') String divanSku,
    @Default('') String sandaranSku,
    @Default('') String sorongSku,
    @Default('') String divanKain,
    @Default('') String divanWarna,
    @Default('') String sandaranKain,
    @Default('') String sandaranWarna,
    @Default('') String sorongKain,
    @Default('') String sorongWarna,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupKasur,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupDivan,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupHeadboard,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupSorong,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount1,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount2,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount3,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount4,
    @Default(<CartBonusSnapshot>[]) List<CartBonusSnapshot> bonusSnapshots,
  }) = _CartItem;

  double get totalPrice => quantity * product.price;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
