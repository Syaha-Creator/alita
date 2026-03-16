// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CartBonusSnapshot _$CartBonusSnapshotFromJson(Map<String, dynamic> json) {
  return _CartBonusSnapshot.fromJson(json);
}

/// @nodoc
mixin _$CartBonusSnapshot {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt)
  int get qty => throw _privateConstructorUsedError;
  String get sku => throw _privateConstructorUsedError;

  /// Serializes this CartBonusSnapshot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartBonusSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartBonusSnapshotCopyWith<CartBonusSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartBonusSnapshotCopyWith<$Res> {
  factory $CartBonusSnapshotCopyWith(
          CartBonusSnapshot value, $Res Function(CartBonusSnapshot) then) =
      _$CartBonusSnapshotCopyWithImpl<$Res, CartBonusSnapshot>;
  @useResult
  $Res call({String name, @JsonKey(fromJson: _parseInt) int qty, String sku});
}

/// @nodoc
class _$CartBonusSnapshotCopyWithImpl<$Res, $Val extends CartBonusSnapshot>
    implements $CartBonusSnapshotCopyWith<$Res> {
  _$CartBonusSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartBonusSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? qty = null,
    Object? sku = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      sku: null == sku
          ? _value.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CartBonusSnapshotImplCopyWith<$Res>
    implements $CartBonusSnapshotCopyWith<$Res> {
  factory _$$CartBonusSnapshotImplCopyWith(_$CartBonusSnapshotImpl value,
          $Res Function(_$CartBonusSnapshotImpl) then) =
      __$$CartBonusSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, @JsonKey(fromJson: _parseInt) int qty, String sku});
}

/// @nodoc
class __$$CartBonusSnapshotImplCopyWithImpl<$Res>
    extends _$CartBonusSnapshotCopyWithImpl<$Res, _$CartBonusSnapshotImpl>
    implements _$$CartBonusSnapshotImplCopyWith<$Res> {
  __$$CartBonusSnapshotImplCopyWithImpl(_$CartBonusSnapshotImpl _value,
      $Res Function(_$CartBonusSnapshotImpl) _then)
      : super(_value, _then);

  /// Create a copy of CartBonusSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? qty = null,
    Object? sku = null,
  }) {
    return _then(_$CartBonusSnapshotImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      sku: null == sku
          ? _value.sku
          : sku // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CartBonusSnapshotImpl implements _CartBonusSnapshot {
  const _$CartBonusSnapshotImpl(
      {this.name = '',
      @JsonKey(fromJson: _parseInt) this.qty = 0,
      this.sku = ''});

  factory _$CartBonusSnapshotImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartBonusSnapshotImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey(fromJson: _parseInt)
  final int qty;
  @override
  @JsonKey()
  final String sku;

  @override
  String toString() {
    return 'CartBonusSnapshot(name: $name, qty: $qty, sku: $sku)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartBonusSnapshotImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.sku, sku) || other.sku == sku));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, qty, sku);

  /// Create a copy of CartBonusSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartBonusSnapshotImplCopyWith<_$CartBonusSnapshotImpl> get copyWith =>
      __$$CartBonusSnapshotImplCopyWithImpl<_$CartBonusSnapshotImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartBonusSnapshotImplToJson(
      this,
    );
  }
}

abstract class _CartBonusSnapshot implements CartBonusSnapshot {
  const factory _CartBonusSnapshot(
      {final String name,
      @JsonKey(fromJson: _parseInt) final int qty,
      final String sku}) = _$CartBonusSnapshotImpl;

  factory _CartBonusSnapshot.fromJson(Map<String, dynamic> json) =
      _$CartBonusSnapshotImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(fromJson: _parseInt)
  int get qty;
  @override
  String get sku;

  /// Create a copy of CartBonusSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartBonusSnapshotImplCopyWith<_$CartBonusSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CartItem _$CartItemFromJson(Map<String, dynamic> json) {
  return _CartItem.fromJson(json);
}

/// @nodoc
mixin _$CartItem {
  Product get product => throw _privateConstructorUsedError;
  Product? get masterProduct => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt)
  int get quantity => throw _privateConstructorUsedError;
  String get kasurSku => throw _privateConstructorUsedError;
  String get divanSku => throw _privateConstructorUsedError;
  String get sandaranSku => throw _privateConstructorUsedError;
  String get sorongSku => throw _privateConstructorUsedError;
  String get divanKain => throw _privateConstructorUsedError;
  String get divanWarna => throw _privateConstructorUsedError;
  String get sandaranKain => throw _privateConstructorUsedError;
  String get sandaranWarna => throw _privateConstructorUsedError;
  String get sorongKain => throw _privateConstructorUsedError;
  String get sorongWarna => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get originalEupKasur => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get originalEupDivan => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get originalEupHeadboard => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get originalEupSorong => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get discount1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get discount2 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get discount3 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get discount4 => throw _privateConstructorUsedError;
  List<CartBonusSnapshot> get bonusSnapshots =>
      throw _privateConstructorUsedError;

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CartItemCopyWith<CartItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartItemCopyWith<$Res> {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) then) =
      _$CartItemCopyWithImpl<$Res, CartItem>;
  @useResult
  $Res call(
      {Product product,
      Product? masterProduct,
      @JsonKey(fromJson: _parseInt) int quantity,
      String kasurSku,
      String divanSku,
      String sandaranSku,
      String sorongSku,
      String divanKain,
      String divanWarna,
      String sandaranKain,
      String sandaranWarna,
      String sorongKain,
      String sorongWarna,
      @JsonKey(fromJson: _parseDouble) double originalEupKasur,
      @JsonKey(fromJson: _parseDouble) double originalEupDivan,
      @JsonKey(fromJson: _parseDouble) double originalEupHeadboard,
      @JsonKey(fromJson: _parseDouble) double originalEupSorong,
      @JsonKey(fromJson: _parseDouble) double discount1,
      @JsonKey(fromJson: _parseDouble) double discount2,
      @JsonKey(fromJson: _parseDouble) double discount3,
      @JsonKey(fromJson: _parseDouble) double discount4,
      List<CartBonusSnapshot> bonusSnapshots});

  $ProductCopyWith<$Res> get product;
  $ProductCopyWith<$Res>? get masterProduct;
}

/// @nodoc
class _$CartItemCopyWithImpl<$Res, $Val extends CartItem>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? product = null,
    Object? masterProduct = freezed,
    Object? quantity = null,
    Object? kasurSku = null,
    Object? divanSku = null,
    Object? sandaranSku = null,
    Object? sorongSku = null,
    Object? divanKain = null,
    Object? divanWarna = null,
    Object? sandaranKain = null,
    Object? sandaranWarna = null,
    Object? sorongKain = null,
    Object? sorongWarna = null,
    Object? originalEupKasur = null,
    Object? originalEupDivan = null,
    Object? originalEupHeadboard = null,
    Object? originalEupSorong = null,
    Object? discount1 = null,
    Object? discount2 = null,
    Object? discount3 = null,
    Object? discount4 = null,
    Object? bonusSnapshots = null,
  }) {
    return _then(_value.copyWith(
      product: null == product
          ? _value.product
          : product // ignore: cast_nullable_to_non_nullable
              as Product,
      masterProduct: freezed == masterProduct
          ? _value.masterProduct
          : masterProduct // ignore: cast_nullable_to_non_nullable
              as Product?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      kasurSku: null == kasurSku
          ? _value.kasurSku
          : kasurSku // ignore: cast_nullable_to_non_nullable
              as String,
      divanSku: null == divanSku
          ? _value.divanSku
          : divanSku // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranSku: null == sandaranSku
          ? _value.sandaranSku
          : sandaranSku // ignore: cast_nullable_to_non_nullable
              as String,
      sorongSku: null == sorongSku
          ? _value.sorongSku
          : sorongSku // ignore: cast_nullable_to_non_nullable
              as String,
      divanKain: null == divanKain
          ? _value.divanKain
          : divanKain // ignore: cast_nullable_to_non_nullable
              as String,
      divanWarna: null == divanWarna
          ? _value.divanWarna
          : divanWarna // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranKain: null == sandaranKain
          ? _value.sandaranKain
          : sandaranKain // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranWarna: null == sandaranWarna
          ? _value.sandaranWarna
          : sandaranWarna // ignore: cast_nullable_to_non_nullable
              as String,
      sorongKain: null == sorongKain
          ? _value.sorongKain
          : sorongKain // ignore: cast_nullable_to_non_nullable
              as String,
      sorongWarna: null == sorongWarna
          ? _value.sorongWarna
          : sorongWarna // ignore: cast_nullable_to_non_nullable
              as String,
      originalEupKasur: null == originalEupKasur
          ? _value.originalEupKasur
          : originalEupKasur // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupDivan: null == originalEupDivan
          ? _value.originalEupDivan
          : originalEupDivan // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupHeadboard: null == originalEupHeadboard
          ? _value.originalEupHeadboard
          : originalEupHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupSorong: null == originalEupSorong
          ? _value.originalEupSorong
          : originalEupSorong // ignore: cast_nullable_to_non_nullable
              as double,
      discount1: null == discount1
          ? _value.discount1
          : discount1 // ignore: cast_nullable_to_non_nullable
              as double,
      discount2: null == discount2
          ? _value.discount2
          : discount2 // ignore: cast_nullable_to_non_nullable
              as double,
      discount3: null == discount3
          ? _value.discount3
          : discount3 // ignore: cast_nullable_to_non_nullable
              as double,
      discount4: null == discount4
          ? _value.discount4
          : discount4 // ignore: cast_nullable_to_non_nullable
              as double,
      bonusSnapshots: null == bonusSnapshots
          ? _value.bonusSnapshots
          : bonusSnapshots // ignore: cast_nullable_to_non_nullable
              as List<CartBonusSnapshot>,
    ) as $Val);
  }

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductCopyWith<$Res> get product {
    return $ProductCopyWith<$Res>(_value.product, (value) {
      return _then(_value.copyWith(product: value) as $Val);
    });
  }

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProductCopyWith<$Res>? get masterProduct {
    if (_value.masterProduct == null) {
      return null;
    }

    return $ProductCopyWith<$Res>(_value.masterProduct!, (value) {
      return _then(_value.copyWith(masterProduct: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CartItemImplCopyWith<$Res>
    implements $CartItemCopyWith<$Res> {
  factory _$$CartItemImplCopyWith(
          _$CartItemImpl value, $Res Function(_$CartItemImpl) then) =
      __$$CartItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Product product,
      Product? masterProduct,
      @JsonKey(fromJson: _parseInt) int quantity,
      String kasurSku,
      String divanSku,
      String sandaranSku,
      String sorongSku,
      String divanKain,
      String divanWarna,
      String sandaranKain,
      String sandaranWarna,
      String sorongKain,
      String sorongWarna,
      @JsonKey(fromJson: _parseDouble) double originalEupKasur,
      @JsonKey(fromJson: _parseDouble) double originalEupDivan,
      @JsonKey(fromJson: _parseDouble) double originalEupHeadboard,
      @JsonKey(fromJson: _parseDouble) double originalEupSorong,
      @JsonKey(fromJson: _parseDouble) double discount1,
      @JsonKey(fromJson: _parseDouble) double discount2,
      @JsonKey(fromJson: _parseDouble) double discount3,
      @JsonKey(fromJson: _parseDouble) double discount4,
      List<CartBonusSnapshot> bonusSnapshots});

  @override
  $ProductCopyWith<$Res> get product;
  @override
  $ProductCopyWith<$Res>? get masterProduct;
}

/// @nodoc
class __$$CartItemImplCopyWithImpl<$Res>
    extends _$CartItemCopyWithImpl<$Res, _$CartItemImpl>
    implements _$$CartItemImplCopyWith<$Res> {
  __$$CartItemImplCopyWithImpl(
      _$CartItemImpl _value, $Res Function(_$CartItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? product = null,
    Object? masterProduct = freezed,
    Object? quantity = null,
    Object? kasurSku = null,
    Object? divanSku = null,
    Object? sandaranSku = null,
    Object? sorongSku = null,
    Object? divanKain = null,
    Object? divanWarna = null,
    Object? sandaranKain = null,
    Object? sandaranWarna = null,
    Object? sorongKain = null,
    Object? sorongWarna = null,
    Object? originalEupKasur = null,
    Object? originalEupDivan = null,
    Object? originalEupHeadboard = null,
    Object? originalEupSorong = null,
    Object? discount1 = null,
    Object? discount2 = null,
    Object? discount3 = null,
    Object? discount4 = null,
    Object? bonusSnapshots = null,
  }) {
    return _then(_$CartItemImpl(
      product: null == product
          ? _value.product
          : product // ignore: cast_nullable_to_non_nullable
              as Product,
      masterProduct: freezed == masterProduct
          ? _value.masterProduct
          : masterProduct // ignore: cast_nullable_to_non_nullable
              as Product?,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      kasurSku: null == kasurSku
          ? _value.kasurSku
          : kasurSku // ignore: cast_nullable_to_non_nullable
              as String,
      divanSku: null == divanSku
          ? _value.divanSku
          : divanSku // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranSku: null == sandaranSku
          ? _value.sandaranSku
          : sandaranSku // ignore: cast_nullable_to_non_nullable
              as String,
      sorongSku: null == sorongSku
          ? _value.sorongSku
          : sorongSku // ignore: cast_nullable_to_non_nullable
              as String,
      divanKain: null == divanKain
          ? _value.divanKain
          : divanKain // ignore: cast_nullable_to_non_nullable
              as String,
      divanWarna: null == divanWarna
          ? _value.divanWarna
          : divanWarna // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranKain: null == sandaranKain
          ? _value.sandaranKain
          : sandaranKain // ignore: cast_nullable_to_non_nullable
              as String,
      sandaranWarna: null == sandaranWarna
          ? _value.sandaranWarna
          : sandaranWarna // ignore: cast_nullable_to_non_nullable
              as String,
      sorongKain: null == sorongKain
          ? _value.sorongKain
          : sorongKain // ignore: cast_nullable_to_non_nullable
              as String,
      sorongWarna: null == sorongWarna
          ? _value.sorongWarna
          : sorongWarna // ignore: cast_nullable_to_non_nullable
              as String,
      originalEupKasur: null == originalEupKasur
          ? _value.originalEupKasur
          : originalEupKasur // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupDivan: null == originalEupDivan
          ? _value.originalEupDivan
          : originalEupDivan // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupHeadboard: null == originalEupHeadboard
          ? _value.originalEupHeadboard
          : originalEupHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      originalEupSorong: null == originalEupSorong
          ? _value.originalEupSorong
          : originalEupSorong // ignore: cast_nullable_to_non_nullable
              as double,
      discount1: null == discount1
          ? _value.discount1
          : discount1 // ignore: cast_nullable_to_non_nullable
              as double,
      discount2: null == discount2
          ? _value.discount2
          : discount2 // ignore: cast_nullable_to_non_nullable
              as double,
      discount3: null == discount3
          ? _value.discount3
          : discount3 // ignore: cast_nullable_to_non_nullable
              as double,
      discount4: null == discount4
          ? _value.discount4
          : discount4 // ignore: cast_nullable_to_non_nullable
              as double,
      bonusSnapshots: null == bonusSnapshots
          ? _value._bonusSnapshots
          : bonusSnapshots // ignore: cast_nullable_to_non_nullable
              as List<CartBonusSnapshot>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CartItemImpl extends _CartItem {
  const _$CartItemImpl(
      {required this.product,
      this.masterProduct,
      @JsonKey(fromJson: _parseInt) this.quantity = 1,
      this.kasurSku = '',
      this.divanSku = '',
      this.sandaranSku = '',
      this.sorongSku = '',
      this.divanKain = '',
      this.divanWarna = '',
      this.sandaranKain = '',
      this.sandaranWarna = '',
      this.sorongKain = '',
      this.sorongWarna = '',
      @JsonKey(fromJson: _parseDouble) this.originalEupKasur = 0.0,
      @JsonKey(fromJson: _parseDouble) this.originalEupDivan = 0.0,
      @JsonKey(fromJson: _parseDouble) this.originalEupHeadboard = 0.0,
      @JsonKey(fromJson: _parseDouble) this.originalEupSorong = 0.0,
      @JsonKey(fromJson: _parseDouble) this.discount1 = 0.0,
      @JsonKey(fromJson: _parseDouble) this.discount2 = 0.0,
      @JsonKey(fromJson: _parseDouble) this.discount3 = 0.0,
      @JsonKey(fromJson: _parseDouble) this.discount4 = 0.0,
      final List<CartBonusSnapshot> bonusSnapshots =
          const <CartBonusSnapshot>[]})
      : _bonusSnapshots = bonusSnapshots,
        super._();

  factory _$CartItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$CartItemImplFromJson(json);

  @override
  final Product product;
  @override
  final Product? masterProduct;
  @override
  @JsonKey(fromJson: _parseInt)
  final int quantity;
  @override
  @JsonKey()
  final String kasurSku;
  @override
  @JsonKey()
  final String divanSku;
  @override
  @JsonKey()
  final String sandaranSku;
  @override
  @JsonKey()
  final String sorongSku;
  @override
  @JsonKey()
  final String divanKain;
  @override
  @JsonKey()
  final String divanWarna;
  @override
  @JsonKey()
  final String sandaranKain;
  @override
  @JsonKey()
  final String sandaranWarna;
  @override
  @JsonKey()
  final String sorongKain;
  @override
  @JsonKey()
  final String sorongWarna;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double originalEupKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double originalEupDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double originalEupHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double originalEupSorong;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double discount1;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double discount2;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double discount3;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double discount4;
  final List<CartBonusSnapshot> _bonusSnapshots;
  @override
  @JsonKey()
  List<CartBonusSnapshot> get bonusSnapshots {
    if (_bonusSnapshots is EqualUnmodifiableListView) return _bonusSnapshots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bonusSnapshots);
  }

  @override
  String toString() {
    return 'CartItem(product: $product, masterProduct: $masterProduct, quantity: $quantity, kasurSku: $kasurSku, divanSku: $divanSku, sandaranSku: $sandaranSku, sorongSku: $sorongSku, divanKain: $divanKain, divanWarna: $divanWarna, sandaranKain: $sandaranKain, sandaranWarna: $sandaranWarna, sorongKain: $sorongKain, sorongWarna: $sorongWarna, originalEupKasur: $originalEupKasur, originalEupDivan: $originalEupDivan, originalEupHeadboard: $originalEupHeadboard, originalEupSorong: $originalEupSorong, discount1: $discount1, discount2: $discount2, discount3: $discount3, discount4: $discount4, bonusSnapshots: $bonusSnapshots)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CartItemImpl &&
            (identical(other.product, product) || other.product == product) &&
            (identical(other.masterProduct, masterProduct) ||
                other.masterProduct == masterProduct) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.kasurSku, kasurSku) ||
                other.kasurSku == kasurSku) &&
            (identical(other.divanSku, divanSku) ||
                other.divanSku == divanSku) &&
            (identical(other.sandaranSku, sandaranSku) ||
                other.sandaranSku == sandaranSku) &&
            (identical(other.sorongSku, sorongSku) ||
                other.sorongSku == sorongSku) &&
            (identical(other.divanKain, divanKain) ||
                other.divanKain == divanKain) &&
            (identical(other.divanWarna, divanWarna) ||
                other.divanWarna == divanWarna) &&
            (identical(other.sandaranKain, sandaranKain) ||
                other.sandaranKain == sandaranKain) &&
            (identical(other.sandaranWarna, sandaranWarna) ||
                other.sandaranWarna == sandaranWarna) &&
            (identical(other.sorongKain, sorongKain) ||
                other.sorongKain == sorongKain) &&
            (identical(other.sorongWarna, sorongWarna) ||
                other.sorongWarna == sorongWarna) &&
            (identical(other.originalEupKasur, originalEupKasur) ||
                other.originalEupKasur == originalEupKasur) &&
            (identical(other.originalEupDivan, originalEupDivan) ||
                other.originalEupDivan == originalEupDivan) &&
            (identical(other.originalEupHeadboard, originalEupHeadboard) ||
                other.originalEupHeadboard == originalEupHeadboard) &&
            (identical(other.originalEupSorong, originalEupSorong) ||
                other.originalEupSorong == originalEupSorong) &&
            (identical(other.discount1, discount1) ||
                other.discount1 == discount1) &&
            (identical(other.discount2, discount2) ||
                other.discount2 == discount2) &&
            (identical(other.discount3, discount3) ||
                other.discount3 == discount3) &&
            (identical(other.discount4, discount4) ||
                other.discount4 == discount4) &&
            const DeepCollectionEquality()
                .equals(other._bonusSnapshots, _bonusSnapshots));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        product,
        masterProduct,
        quantity,
        kasurSku,
        divanSku,
        sandaranSku,
        sorongSku,
        divanKain,
        divanWarna,
        sandaranKain,
        sandaranWarna,
        sorongKain,
        sorongWarna,
        originalEupKasur,
        originalEupDivan,
        originalEupHeadboard,
        originalEupSorong,
        discount1,
        discount2,
        discount3,
        discount4,
        const DeepCollectionEquality().hash(_bonusSnapshots)
      ]);

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      __$$CartItemImplCopyWithImpl<_$CartItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CartItemImplToJson(
      this,
    );
  }
}

abstract class _CartItem extends CartItem {
  const factory _CartItem(
      {required final Product product,
      final Product? masterProduct,
      @JsonKey(fromJson: _parseInt) final int quantity,
      final String kasurSku,
      final String divanSku,
      final String sandaranSku,
      final String sorongSku,
      final String divanKain,
      final String divanWarna,
      final String sandaranKain,
      final String sandaranWarna,
      final String sorongKain,
      final String sorongWarna,
      @JsonKey(fromJson: _parseDouble) final double originalEupKasur,
      @JsonKey(fromJson: _parseDouble) final double originalEupDivan,
      @JsonKey(fromJson: _parseDouble) final double originalEupHeadboard,
      @JsonKey(fromJson: _parseDouble) final double originalEupSorong,
      @JsonKey(fromJson: _parseDouble) final double discount1,
      @JsonKey(fromJson: _parseDouble) final double discount2,
      @JsonKey(fromJson: _parseDouble) final double discount3,
      @JsonKey(fromJson: _parseDouble) final double discount4,
      final List<CartBonusSnapshot> bonusSnapshots}) = _$CartItemImpl;
  const _CartItem._() : super._();

  factory _CartItem.fromJson(Map<String, dynamic> json) =
      _$CartItemImpl.fromJson;

  @override
  Product get product;
  @override
  Product? get masterProduct;
  @override
  @JsonKey(fromJson: _parseInt)
  int get quantity;
  @override
  String get kasurSku;
  @override
  String get divanSku;
  @override
  String get sandaranSku;
  @override
  String get sorongSku;
  @override
  String get divanKain;
  @override
  String get divanWarna;
  @override
  String get sandaranKain;
  @override
  String get sandaranWarna;
  @override
  String get sorongKain;
  @override
  String get sorongWarna;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get originalEupKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get originalEupDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get originalEupHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get originalEupSorong;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get discount1;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get discount2;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get discount3;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get discount4;
  @override
  List<CartBonusSnapshot> get bonusSnapshots;

  /// Create a copy of CartItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CartItemImplCopyWith<_$CartItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
