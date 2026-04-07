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

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

List<double> _parseDoubleList(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value.map((e) => _parseDouble(e)).toList();
}

bool _parseBoolDefaultFalse(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().toLowerCase();
  return s == 'true' || s == '1';
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

  /// True jika baris ini dari mode indirect (toko assign + diskon toko API).
  bool get isIndirectSale =>
      indirectStoreAddressNumber != null && indirectStoreAddressNumber! > 0;

  /// Voucher FOC 100% hanya untuk indirect; di direct flag disembunyikan & diabaikan.
  bool get isFocVoucherActive => isIndirectSale && isFocVoucher;

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
    /// Indirect: `address_number` toko (kunci merge baris + diskon).
    @JsonKey(fromJson: _parseIntNullable) int? indirectStoreAddressNumber,
    @Default('') String indirectStoreAlphaName,
    @Default('') String indirectStoreAddress,
    @Default('') String indirectStorePhone,
    @JsonKey(fromJson: _parseDoubleList)
    @Default(<double>[])
    List<double> indirectStoreDiscounts,
    @Default('') String indirectStoreDiscountDisplay,
    /// Voucher FOC 100%: total baris di keranjang = 0; order letter memakai
    /// harga customer = pricelist & net = 0 + baris diskon bertanda FOC.
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isFocVoucher,
  }) = _CartItem;

  double get totalPrice =>
      isFocVoucherActive ? 0.0 : quantity * product.price;

  /// Human-friendly name for display in cart / checkout.
  ///
  /// If the product has no kasur ("Tanpa Kasur"), shows the first
  /// present component name (divan / headboard / sorong) + size.
  String get displayName {
    final p = product;
    if (_isPresent(p.kasur)) return p.name;

    String withSize(String base) {
      if (p.ukuran.isEmpty) return base;
      if (base.toLowerCase().contains(p.ukuran.toLowerCase())) return base;
      return '$base ${p.ukuran}';
    }

    if (_isPresent(p.divan)) return withSize(p.divan);
    if (_isPresent(p.headboard)) return withSize(p.headboard);
    if (_isPresent(p.sorong)) return withSize(p.sorong);
    return p.name;
  }

  static bool _isPresent(String field) {
    final v = field.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('tanpa');
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
