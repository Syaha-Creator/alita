// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Product _$ProductFromJson(Map<String, dynamic> json) {
  return _Product.fromJson(json);
}

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get price => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  String get channel => throw _privateConstructorUsedError;
  String get brand => throw _privateConstructorUsedError;
  String get program =>
      throw _privateConstructorUsedError; // Specs for Sibling Grouping / Konfigurator Varian
  String get kasur => throw _privateConstructorUsedError;
  String get ukuran => throw _privateConstructorUsedError;
  String get divan => throw _privateConstructorUsedError;
  String get headboard => throw _privateConstructorUsedError;
  String get sorong => throw _privateConstructorUsedError;
  bool get isSet => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get pricelist => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get eupKasur => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get eupDivan => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get eupHeadboard => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get eupSorong =>
      throw _privateConstructorUsedError; // Pricelist per komponen (breakdown)
  @JsonKey(fromJson: _parseDouble)
  double get plKasur => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get plDivan => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get plHeadboard => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get plSorong => throw _privateConstructorUsedError; // Bonus (nullable)
  String? get bonus1 => throw _privateConstructorUsedError;
  int? get qtyBonus1 => throw _privateConstructorUsedError;
  String? get bonus2 => throw _privateConstructorUsedError;
  int? get qtyBonus2 => throw _privateConstructorUsedError;
  String? get bonus3 => throw _privateConstructorUsedError;
  int? get qtyBonus3 => throw _privateConstructorUsedError;
  String? get bonus4 => throw _privateConstructorUsedError;
  int? get qtyBonus4 => throw _privateConstructorUsedError;
  String? get bonus5 => throw _privateConstructorUsedError;
  int? get qtyBonus5 => throw _privateConstructorUsedError;
  String? get bonus6 => throw _privateConstructorUsedError;
  int? get qtyBonus6 => throw _privateConstructorUsedError;
  String? get bonus7 => throw _privateConstructorUsedError;
  int? get qtyBonus7 => throw _privateConstructorUsedError;
  String? get bonus8 => throw _privateConstructorUsedError;
  int? get qtyBonus8 =>
      throw _privateConstructorUsedError; // Pricelist bonus (nilai Rupiah per bonus, nullable)
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus2 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus3 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus4 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus5 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus6 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus7 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus8 =>
      throw _privateConstructorUsedError; // Batas harga bawah analyst: total jual tidak boleh melebihi nilai ini
  @JsonKey(fromJson: _parseDouble)
  double get bottomPriceAnalyst =>
      throw _privateConstructorUsedError; // Batas maksimal diskon (limit) per tingkat — dari database
  @JsonKey(fromJson: _parseDouble)
  double get disc1 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc2 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc3 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc4 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc5 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc6 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc7 => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get disc8 => throw _privateConstructorUsedError;

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(fromJson: _parseDouble) double price,
      String imageUrl,
      String category,
      String description,
      bool isAvailable,
      String channel,
      String brand,
      String program,
      String kasur,
      String ukuran,
      String divan,
      String headboard,
      String sorong,
      bool isSet,
      @JsonKey(fromJson: _parseDouble) double pricelist,
      @JsonKey(fromJson: _parseDouble) double eupKasur,
      @JsonKey(fromJson: _parseDouble) double eupDivan,
      @JsonKey(fromJson: _parseDouble) double eupHeadboard,
      @JsonKey(fromJson: _parseDouble) double eupSorong,
      @JsonKey(fromJson: _parseDouble) double plKasur,
      @JsonKey(fromJson: _parseDouble) double plDivan,
      @JsonKey(fromJson: _parseDouble) double plHeadboard,
      @JsonKey(fromJson: _parseDouble) double plSorong,
      String? bonus1,
      int? qtyBonus1,
      String? bonus2,
      int? qtyBonus2,
      String? bonus3,
      int? qtyBonus3,
      String? bonus4,
      int? qtyBonus4,
      String? bonus5,
      int? qtyBonus5,
      String? bonus6,
      int? qtyBonus6,
      String? bonus7,
      int? qtyBonus7,
      String? bonus8,
      int? qtyBonus8,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus1,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus2,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus3,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus4,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus5,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus6,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus7,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus8,
      @JsonKey(fromJson: _parseDouble) double bottomPriceAnalyst,
      @JsonKey(fromJson: _parseDouble) double disc1,
      @JsonKey(fromJson: _parseDouble) double disc2,
      @JsonKey(fromJson: _parseDouble) double disc3,
      @JsonKey(fromJson: _parseDouble) double disc4,
      @JsonKey(fromJson: _parseDouble) double disc5,
      @JsonKey(fromJson: _parseDouble) double disc6,
      @JsonKey(fromJson: _parseDouble) double disc7,
      @JsonKey(fromJson: _parseDouble) double disc8});
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = null,
    Object? category = null,
    Object? description = null,
    Object? isAvailable = null,
    Object? channel = null,
    Object? brand = null,
    Object? program = null,
    Object? kasur = null,
    Object? ukuran = null,
    Object? divan = null,
    Object? headboard = null,
    Object? sorong = null,
    Object? isSet = null,
    Object? pricelist = null,
    Object? eupKasur = null,
    Object? eupDivan = null,
    Object? eupHeadboard = null,
    Object? eupSorong = null,
    Object? plKasur = null,
    Object? plDivan = null,
    Object? plHeadboard = null,
    Object? plSorong = null,
    Object? bonus1 = freezed,
    Object? qtyBonus1 = freezed,
    Object? bonus2 = freezed,
    Object? qtyBonus2 = freezed,
    Object? bonus3 = freezed,
    Object? qtyBonus3 = freezed,
    Object? bonus4 = freezed,
    Object? qtyBonus4 = freezed,
    Object? bonus5 = freezed,
    Object? qtyBonus5 = freezed,
    Object? bonus6 = freezed,
    Object? qtyBonus6 = freezed,
    Object? bonus7 = freezed,
    Object? qtyBonus7 = freezed,
    Object? bonus8 = freezed,
    Object? qtyBonus8 = freezed,
    Object? plBonus1 = freezed,
    Object? plBonus2 = freezed,
    Object? plBonus3 = freezed,
    Object? plBonus4 = freezed,
    Object? plBonus5 = freezed,
    Object? plBonus6 = freezed,
    Object? plBonus7 = freezed,
    Object? plBonus8 = freezed,
    Object? bottomPriceAnalyst = null,
    Object? disc1 = null,
    Object? disc2 = null,
    Object? disc3 = null,
    Object? disc4 = null,
    Object? disc5 = null,
    Object? disc6 = null,
    Object? disc7 = null,
    Object? disc8 = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as String,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      program: null == program
          ? _value.program
          : program // ignore: cast_nullable_to_non_nullable
              as String,
      kasur: null == kasur
          ? _value.kasur
          : kasur // ignore: cast_nullable_to_non_nullable
              as String,
      ukuran: null == ukuran
          ? _value.ukuran
          : ukuran // ignore: cast_nullable_to_non_nullable
              as String,
      divan: null == divan
          ? _value.divan
          : divan // ignore: cast_nullable_to_non_nullable
              as String,
      headboard: null == headboard
          ? _value.headboard
          : headboard // ignore: cast_nullable_to_non_nullable
              as String,
      sorong: null == sorong
          ? _value.sorong
          : sorong // ignore: cast_nullable_to_non_nullable
              as String,
      isSet: null == isSet
          ? _value.isSet
          : isSet // ignore: cast_nullable_to_non_nullable
              as bool,
      pricelist: null == pricelist
          ? _value.pricelist
          : pricelist // ignore: cast_nullable_to_non_nullable
              as double,
      eupKasur: null == eupKasur
          ? _value.eupKasur
          : eupKasur // ignore: cast_nullable_to_non_nullable
              as double,
      eupDivan: null == eupDivan
          ? _value.eupDivan
          : eupDivan // ignore: cast_nullable_to_non_nullable
              as double,
      eupHeadboard: null == eupHeadboard
          ? _value.eupHeadboard
          : eupHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      eupSorong: null == eupSorong
          ? _value.eupSorong
          : eupSorong // ignore: cast_nullable_to_non_nullable
              as double,
      plKasur: null == plKasur
          ? _value.plKasur
          : plKasur // ignore: cast_nullable_to_non_nullable
              as double,
      plDivan: null == plDivan
          ? _value.plDivan
          : plDivan // ignore: cast_nullable_to_non_nullable
              as double,
      plHeadboard: null == plHeadboard
          ? _value.plHeadboard
          : plHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      plSorong: null == plSorong
          ? _value.plSorong
          : plSorong // ignore: cast_nullable_to_non_nullable
              as double,
      bonus1: freezed == bonus1
          ? _value.bonus1
          : bonus1 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus1: freezed == qtyBonus1
          ? _value.qtyBonus1
          : qtyBonus1 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus2: freezed == bonus2
          ? _value.bonus2
          : bonus2 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus2: freezed == qtyBonus2
          ? _value.qtyBonus2
          : qtyBonus2 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus3: freezed == bonus3
          ? _value.bonus3
          : bonus3 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus3: freezed == qtyBonus3
          ? _value.qtyBonus3
          : qtyBonus3 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus4: freezed == bonus4
          ? _value.bonus4
          : bonus4 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus4: freezed == qtyBonus4
          ? _value.qtyBonus4
          : qtyBonus4 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus5: freezed == bonus5
          ? _value.bonus5
          : bonus5 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus5: freezed == qtyBonus5
          ? _value.qtyBonus5
          : qtyBonus5 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus6: freezed == bonus6
          ? _value.bonus6
          : bonus6 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus6: freezed == qtyBonus6
          ? _value.qtyBonus6
          : qtyBonus6 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus7: freezed == bonus7
          ? _value.bonus7
          : bonus7 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus7: freezed == qtyBonus7
          ? _value.qtyBonus7
          : qtyBonus7 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus8: freezed == bonus8
          ? _value.bonus8
          : bonus8 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus8: freezed == qtyBonus8
          ? _value.qtyBonus8
          : qtyBonus8 // ignore: cast_nullable_to_non_nullable
              as int?,
      plBonus1: freezed == plBonus1
          ? _value.plBonus1
          : plBonus1 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus2: freezed == plBonus2
          ? _value.plBonus2
          : plBonus2 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus3: freezed == plBonus3
          ? _value.plBonus3
          : plBonus3 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus4: freezed == plBonus4
          ? _value.plBonus4
          : plBonus4 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus5: freezed == plBonus5
          ? _value.plBonus5
          : plBonus5 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus6: freezed == plBonus6
          ? _value.plBonus6
          : plBonus6 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus7: freezed == plBonus7
          ? _value.plBonus7
          : plBonus7 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus8: freezed == plBonus8
          ? _value.plBonus8
          : plBonus8 // ignore: cast_nullable_to_non_nullable
              as double?,
      bottomPriceAnalyst: null == bottomPriceAnalyst
          ? _value.bottomPriceAnalyst
          : bottomPriceAnalyst // ignore: cast_nullable_to_non_nullable
              as double,
      disc1: null == disc1
          ? _value.disc1
          : disc1 // ignore: cast_nullable_to_non_nullable
              as double,
      disc2: null == disc2
          ? _value.disc2
          : disc2 // ignore: cast_nullable_to_non_nullable
              as double,
      disc3: null == disc3
          ? _value.disc3
          : disc3 // ignore: cast_nullable_to_non_nullable
              as double,
      disc4: null == disc4
          ? _value.disc4
          : disc4 // ignore: cast_nullable_to_non_nullable
              as double,
      disc5: null == disc5
          ? _value.disc5
          : disc5 // ignore: cast_nullable_to_non_nullable
              as double,
      disc6: null == disc6
          ? _value.disc6
          : disc6 // ignore: cast_nullable_to_non_nullable
              as double,
      disc7: null == disc7
          ? _value.disc7
          : disc7 // ignore: cast_nullable_to_non_nullable
              as double,
      disc8: null == disc8
          ? _value.disc8
          : disc8 // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
          _$ProductImpl value, $Res Function(_$ProductImpl) then) =
      __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(fromJson: _parseDouble) double price,
      String imageUrl,
      String category,
      String description,
      bool isAvailable,
      String channel,
      String brand,
      String program,
      String kasur,
      String ukuran,
      String divan,
      String headboard,
      String sorong,
      bool isSet,
      @JsonKey(fromJson: _parseDouble) double pricelist,
      @JsonKey(fromJson: _parseDouble) double eupKasur,
      @JsonKey(fromJson: _parseDouble) double eupDivan,
      @JsonKey(fromJson: _parseDouble) double eupHeadboard,
      @JsonKey(fromJson: _parseDouble) double eupSorong,
      @JsonKey(fromJson: _parseDouble) double plKasur,
      @JsonKey(fromJson: _parseDouble) double plDivan,
      @JsonKey(fromJson: _parseDouble) double plHeadboard,
      @JsonKey(fromJson: _parseDouble) double plSorong,
      String? bonus1,
      int? qtyBonus1,
      String? bonus2,
      int? qtyBonus2,
      String? bonus3,
      int? qtyBonus3,
      String? bonus4,
      int? qtyBonus4,
      String? bonus5,
      int? qtyBonus5,
      String? bonus6,
      int? qtyBonus6,
      String? bonus7,
      int? qtyBonus7,
      String? bonus8,
      int? qtyBonus8,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus1,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus2,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus3,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus4,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus5,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus6,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus7,
      @JsonKey(fromJson: _parseDoubleNullable) double? plBonus8,
      @JsonKey(fromJson: _parseDouble) double bottomPriceAnalyst,
      @JsonKey(fromJson: _parseDouble) double disc1,
      @JsonKey(fromJson: _parseDouble) double disc2,
      @JsonKey(fromJson: _parseDouble) double disc3,
      @JsonKey(fromJson: _parseDouble) double disc4,
      @JsonKey(fromJson: _parseDouble) double disc5,
      @JsonKey(fromJson: _parseDouble) double disc6,
      @JsonKey(fromJson: _parseDouble) double disc7,
      @JsonKey(fromJson: _parseDouble) double disc8});
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
      _$ProductImpl _value, $Res Function(_$ProductImpl) _then)
      : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? price = null,
    Object? imageUrl = null,
    Object? category = null,
    Object? description = null,
    Object? isAvailable = null,
    Object? channel = null,
    Object? brand = null,
    Object? program = null,
    Object? kasur = null,
    Object? ukuran = null,
    Object? divan = null,
    Object? headboard = null,
    Object? sorong = null,
    Object? isSet = null,
    Object? pricelist = null,
    Object? eupKasur = null,
    Object? eupDivan = null,
    Object? eupHeadboard = null,
    Object? eupSorong = null,
    Object? plKasur = null,
    Object? plDivan = null,
    Object? plHeadboard = null,
    Object? plSorong = null,
    Object? bonus1 = freezed,
    Object? qtyBonus1 = freezed,
    Object? bonus2 = freezed,
    Object? qtyBonus2 = freezed,
    Object? bonus3 = freezed,
    Object? qtyBonus3 = freezed,
    Object? bonus4 = freezed,
    Object? qtyBonus4 = freezed,
    Object? bonus5 = freezed,
    Object? qtyBonus5 = freezed,
    Object? bonus6 = freezed,
    Object? qtyBonus6 = freezed,
    Object? bonus7 = freezed,
    Object? qtyBonus7 = freezed,
    Object? bonus8 = freezed,
    Object? qtyBonus8 = freezed,
    Object? plBonus1 = freezed,
    Object? plBonus2 = freezed,
    Object? plBonus3 = freezed,
    Object? plBonus4 = freezed,
    Object? plBonus5 = freezed,
    Object? plBonus6 = freezed,
    Object? plBonus7 = freezed,
    Object? plBonus8 = freezed,
    Object? bottomPriceAnalyst = null,
    Object? disc1 = null,
    Object? disc2 = null,
    Object? disc3 = null,
    Object? disc4 = null,
    Object? disc5 = null,
    Object? disc6 = null,
    Object? disc7 = null,
    Object? disc8 = null,
  }) {
    return _then(_$ProductImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      channel: null == channel
          ? _value.channel
          : channel // ignore: cast_nullable_to_non_nullable
              as String,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      program: null == program
          ? _value.program
          : program // ignore: cast_nullable_to_non_nullable
              as String,
      kasur: null == kasur
          ? _value.kasur
          : kasur // ignore: cast_nullable_to_non_nullable
              as String,
      ukuran: null == ukuran
          ? _value.ukuran
          : ukuran // ignore: cast_nullable_to_non_nullable
              as String,
      divan: null == divan
          ? _value.divan
          : divan // ignore: cast_nullable_to_non_nullable
              as String,
      headboard: null == headboard
          ? _value.headboard
          : headboard // ignore: cast_nullable_to_non_nullable
              as String,
      sorong: null == sorong
          ? _value.sorong
          : sorong // ignore: cast_nullable_to_non_nullable
              as String,
      isSet: null == isSet
          ? _value.isSet
          : isSet // ignore: cast_nullable_to_non_nullable
              as bool,
      pricelist: null == pricelist
          ? _value.pricelist
          : pricelist // ignore: cast_nullable_to_non_nullable
              as double,
      eupKasur: null == eupKasur
          ? _value.eupKasur
          : eupKasur // ignore: cast_nullable_to_non_nullable
              as double,
      eupDivan: null == eupDivan
          ? _value.eupDivan
          : eupDivan // ignore: cast_nullable_to_non_nullable
              as double,
      eupHeadboard: null == eupHeadboard
          ? _value.eupHeadboard
          : eupHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      eupSorong: null == eupSorong
          ? _value.eupSorong
          : eupSorong // ignore: cast_nullable_to_non_nullable
              as double,
      plKasur: null == plKasur
          ? _value.plKasur
          : plKasur // ignore: cast_nullable_to_non_nullable
              as double,
      plDivan: null == plDivan
          ? _value.plDivan
          : plDivan // ignore: cast_nullable_to_non_nullable
              as double,
      plHeadboard: null == plHeadboard
          ? _value.plHeadboard
          : plHeadboard // ignore: cast_nullable_to_non_nullable
              as double,
      plSorong: null == plSorong
          ? _value.plSorong
          : plSorong // ignore: cast_nullable_to_non_nullable
              as double,
      bonus1: freezed == bonus1
          ? _value.bonus1
          : bonus1 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus1: freezed == qtyBonus1
          ? _value.qtyBonus1
          : qtyBonus1 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus2: freezed == bonus2
          ? _value.bonus2
          : bonus2 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus2: freezed == qtyBonus2
          ? _value.qtyBonus2
          : qtyBonus2 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus3: freezed == bonus3
          ? _value.bonus3
          : bonus3 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus3: freezed == qtyBonus3
          ? _value.qtyBonus3
          : qtyBonus3 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus4: freezed == bonus4
          ? _value.bonus4
          : bonus4 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus4: freezed == qtyBonus4
          ? _value.qtyBonus4
          : qtyBonus4 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus5: freezed == bonus5
          ? _value.bonus5
          : bonus5 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus5: freezed == qtyBonus5
          ? _value.qtyBonus5
          : qtyBonus5 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus6: freezed == bonus6
          ? _value.bonus6
          : bonus6 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus6: freezed == qtyBonus6
          ? _value.qtyBonus6
          : qtyBonus6 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus7: freezed == bonus7
          ? _value.bonus7
          : bonus7 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus7: freezed == qtyBonus7
          ? _value.qtyBonus7
          : qtyBonus7 // ignore: cast_nullable_to_non_nullable
              as int?,
      bonus8: freezed == bonus8
          ? _value.bonus8
          : bonus8 // ignore: cast_nullable_to_non_nullable
              as String?,
      qtyBonus8: freezed == qtyBonus8
          ? _value.qtyBonus8
          : qtyBonus8 // ignore: cast_nullable_to_non_nullable
              as int?,
      plBonus1: freezed == plBonus1
          ? _value.plBonus1
          : plBonus1 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus2: freezed == plBonus2
          ? _value.plBonus2
          : plBonus2 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus3: freezed == plBonus3
          ? _value.plBonus3
          : plBonus3 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus4: freezed == plBonus4
          ? _value.plBonus4
          : plBonus4 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus5: freezed == plBonus5
          ? _value.plBonus5
          : plBonus5 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus6: freezed == plBonus6
          ? _value.plBonus6
          : plBonus6 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus7: freezed == plBonus7
          ? _value.plBonus7
          : plBonus7 // ignore: cast_nullable_to_non_nullable
              as double?,
      plBonus8: freezed == plBonus8
          ? _value.plBonus8
          : plBonus8 // ignore: cast_nullable_to_non_nullable
              as double?,
      bottomPriceAnalyst: null == bottomPriceAnalyst
          ? _value.bottomPriceAnalyst
          : bottomPriceAnalyst // ignore: cast_nullable_to_non_nullable
              as double,
      disc1: null == disc1
          ? _value.disc1
          : disc1 // ignore: cast_nullable_to_non_nullable
              as double,
      disc2: null == disc2
          ? _value.disc2
          : disc2 // ignore: cast_nullable_to_non_nullable
              as double,
      disc3: null == disc3
          ? _value.disc3
          : disc3 // ignore: cast_nullable_to_non_nullable
              as double,
      disc4: null == disc4
          ? _value.disc4
          : disc4 // ignore: cast_nullable_to_non_nullable
              as double,
      disc5: null == disc5
          ? _value.disc5
          : disc5 // ignore: cast_nullable_to_non_nullable
              as double,
      disc6: null == disc6
          ? _value.disc6
          : disc6 // ignore: cast_nullable_to_non_nullable
              as double,
      disc7: null == disc7
          ? _value.disc7
          : disc7 // ignore: cast_nullable_to_non_nullable
              as double,
      disc8: null == disc8
          ? _value.disc8
          : disc8 // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductImpl implements _Product {
  const _$ProductImpl(
      {required this.id,
      required this.name,
      @JsonKey(fromJson: _parseDouble) required this.price,
      required this.imageUrl,
      required this.category,
      this.description = '',
      this.isAvailable = true,
      this.channel = '',
      this.brand = '',
      this.program = '-',
      required this.kasur,
      required this.ukuran,
      required this.divan,
      required this.headboard,
      required this.sorong,
      required this.isSet,
      @JsonKey(fromJson: _parseDouble) required this.pricelist,
      @JsonKey(fromJson: _parseDouble) required this.eupKasur,
      @JsonKey(fromJson: _parseDouble) required this.eupDivan,
      @JsonKey(fromJson: _parseDouble) required this.eupHeadboard,
      @JsonKey(fromJson: _parseDouble) required this.eupSorong,
      @JsonKey(fromJson: _parseDouble) required this.plKasur,
      @JsonKey(fromJson: _parseDouble) required this.plDivan,
      @JsonKey(fromJson: _parseDouble) required this.plHeadboard,
      @JsonKey(fromJson: _parseDouble) required this.plSorong,
      this.bonus1,
      this.qtyBonus1,
      this.bonus2,
      this.qtyBonus2,
      this.bonus3,
      this.qtyBonus3,
      this.bonus4,
      this.qtyBonus4,
      this.bonus5,
      this.qtyBonus5,
      this.bonus6,
      this.qtyBonus6,
      this.bonus7,
      this.qtyBonus7,
      this.bonus8,
      this.qtyBonus8,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus1,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus2,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus3,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus4,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus5,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus6,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus7,
      @JsonKey(fromJson: _parseDoubleNullable) this.plBonus8,
      @JsonKey(fromJson: _parseDouble) this.bottomPriceAnalyst = 0,
      @JsonKey(fromJson: _parseDouble) this.disc1 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc2 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc3 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc4 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc5 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc6 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc7 = 0,
      @JsonKey(fromJson: _parseDouble) this.disc8 = 0});

  factory _$ProductImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double price;
  @override
  final String imageUrl;
  @override
  final String category;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey()
  final bool isAvailable;
  @override
  @JsonKey()
  final String channel;
  @override
  @JsonKey()
  final String brand;
  @override
  @JsonKey()
  final String program;
// Specs for Sibling Grouping / Konfigurator Varian
  @override
  final String kasur;
  @override
  final String ukuran;
  @override
  final String divan;
  @override
  final String headboard;
  @override
  final String sorong;
  @override
  final bool isSet;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double pricelist;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double eupKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double eupDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double eupHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double eupSorong;
// Pricelist per komponen (breakdown)
  @override
  @JsonKey(fromJson: _parseDouble)
  final double plKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double plDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double plHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double plSorong;
// Bonus (nullable)
  @override
  final String? bonus1;
  @override
  final int? qtyBonus1;
  @override
  final String? bonus2;
  @override
  final int? qtyBonus2;
  @override
  final String? bonus3;
  @override
  final int? qtyBonus3;
  @override
  final String? bonus4;
  @override
  final int? qtyBonus4;
  @override
  final String? bonus5;
  @override
  final int? qtyBonus5;
  @override
  final String? bonus6;
  @override
  final int? qtyBonus6;
  @override
  final String? bonus7;
  @override
  final int? qtyBonus7;
  @override
  final String? bonus8;
  @override
  final int? qtyBonus8;
// Pricelist bonus (nilai Rupiah per bonus, nullable)
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus1;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus2;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus3;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus4;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus5;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus6;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus7;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  final double? plBonus8;
// Batas harga bawah analyst: total jual tidak boleh melebihi nilai ini
  @override
  @JsonKey(fromJson: _parseDouble)
  final double bottomPriceAnalyst;
// Batas maksimal diskon (limit) per tingkat — dari database
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc1;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc2;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc3;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc4;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc5;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc6;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc7;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double disc8;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, imageUrl: $imageUrl, category: $category, description: $description, isAvailable: $isAvailable, channel: $channel, brand: $brand, program: $program, kasur: $kasur, ukuran: $ukuran, divan: $divan, headboard: $headboard, sorong: $sorong, isSet: $isSet, pricelist: $pricelist, eupKasur: $eupKasur, eupDivan: $eupDivan, eupHeadboard: $eupHeadboard, eupSorong: $eupSorong, plKasur: $plKasur, plDivan: $plDivan, plHeadboard: $plHeadboard, plSorong: $plSorong, bonus1: $bonus1, qtyBonus1: $qtyBonus1, bonus2: $bonus2, qtyBonus2: $qtyBonus2, bonus3: $bonus3, qtyBonus3: $qtyBonus3, bonus4: $bonus4, qtyBonus4: $qtyBonus4, bonus5: $bonus5, qtyBonus5: $qtyBonus5, bonus6: $bonus6, qtyBonus6: $qtyBonus6, bonus7: $bonus7, qtyBonus7: $qtyBonus7, bonus8: $bonus8, qtyBonus8: $qtyBonus8, plBonus1: $plBonus1, plBonus2: $plBonus2, plBonus3: $plBonus3, plBonus4: $plBonus4, plBonus5: $plBonus5, plBonus6: $plBonus6, plBonus7: $plBonus7, plBonus8: $plBonus8, bottomPriceAnalyst: $bottomPriceAnalyst, disc1: $disc1, disc2: $disc2, disc3: $disc3, disc4: $disc4, disc5: $disc5, disc6: $disc6, disc7: $disc7, disc8: $disc8)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.program, program) || other.program == program) &&
            (identical(other.kasur, kasur) || other.kasur == kasur) &&
            (identical(other.ukuran, ukuran) || other.ukuran == ukuran) &&
            (identical(other.divan, divan) || other.divan == divan) &&
            (identical(other.headboard, headboard) ||
                other.headboard == headboard) &&
            (identical(other.sorong, sorong) || other.sorong == sorong) &&
            (identical(other.isSet, isSet) || other.isSet == isSet) &&
            (identical(other.pricelist, pricelist) ||
                other.pricelist == pricelist) &&
            (identical(other.eupKasur, eupKasur) ||
                other.eupKasur == eupKasur) &&
            (identical(other.eupDivan, eupDivan) ||
                other.eupDivan == eupDivan) &&
            (identical(other.eupHeadboard, eupHeadboard) ||
                other.eupHeadboard == eupHeadboard) &&
            (identical(other.eupSorong, eupSorong) ||
                other.eupSorong == eupSorong) &&
            (identical(other.plKasur, plKasur) || other.plKasur == plKasur) &&
            (identical(other.plDivan, plDivan) || other.plDivan == plDivan) &&
            (identical(other.plHeadboard, plHeadboard) ||
                other.plHeadboard == plHeadboard) &&
            (identical(other.plSorong, plSorong) ||
                other.plSorong == plSorong) &&
            (identical(other.bonus1, bonus1) || other.bonus1 == bonus1) &&
            (identical(other.qtyBonus1, qtyBonus1) ||
                other.qtyBonus1 == qtyBonus1) &&
            (identical(other.bonus2, bonus2) || other.bonus2 == bonus2) &&
            (identical(other.qtyBonus2, qtyBonus2) ||
                other.qtyBonus2 == qtyBonus2) &&
            (identical(other.bonus3, bonus3) || other.bonus3 == bonus3) &&
            (identical(other.qtyBonus3, qtyBonus3) ||
                other.qtyBonus3 == qtyBonus3) &&
            (identical(other.bonus4, bonus4) || other.bonus4 == bonus4) &&
            (identical(other.qtyBonus4, qtyBonus4) ||
                other.qtyBonus4 == qtyBonus4) &&
            (identical(other.bonus5, bonus5) || other.bonus5 == bonus5) &&
            (identical(other.qtyBonus5, qtyBonus5) ||
                other.qtyBonus5 == qtyBonus5) &&
            (identical(other.bonus6, bonus6) || other.bonus6 == bonus6) &&
            (identical(other.qtyBonus6, qtyBonus6) ||
                other.qtyBonus6 == qtyBonus6) &&
            (identical(other.bonus7, bonus7) || other.bonus7 == bonus7) &&
            (identical(other.qtyBonus7, qtyBonus7) ||
                other.qtyBonus7 == qtyBonus7) &&
            (identical(other.bonus8, bonus8) || other.bonus8 == bonus8) &&
            (identical(other.qtyBonus8, qtyBonus8) ||
                other.qtyBonus8 == qtyBonus8) &&
            (identical(other.plBonus1, plBonus1) ||
                other.plBonus1 == plBonus1) &&
            (identical(other.plBonus2, plBonus2) ||
                other.plBonus2 == plBonus2) &&
            (identical(other.plBonus3, plBonus3) ||
                other.plBonus3 == plBonus3) &&
            (identical(other.plBonus4, plBonus4) ||
                other.plBonus4 == plBonus4) &&
            (identical(other.plBonus5, plBonus5) ||
                other.plBonus5 == plBonus5) &&
            (identical(other.plBonus6, plBonus6) ||
                other.plBonus6 == plBonus6) &&
            (identical(other.plBonus7, plBonus7) ||
                other.plBonus7 == plBonus7) &&
            (identical(other.plBonus8, plBonus8) ||
                other.plBonus8 == plBonus8) &&
            (identical(other.bottomPriceAnalyst, bottomPriceAnalyst) ||
                other.bottomPriceAnalyst == bottomPriceAnalyst) &&
            (identical(other.disc1, disc1) || other.disc1 == disc1) &&
            (identical(other.disc2, disc2) || other.disc2 == disc2) &&
            (identical(other.disc3, disc3) || other.disc3 == disc3) &&
            (identical(other.disc4, disc4) || other.disc4 == disc4) &&
            (identical(other.disc5, disc5) || other.disc5 == disc5) &&
            (identical(other.disc6, disc6) || other.disc6 == disc6) &&
            (identical(other.disc7, disc7) || other.disc7 == disc7) &&
            (identical(other.disc8, disc8) || other.disc8 == disc8));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        price,
        imageUrl,
        category,
        description,
        isAvailable,
        channel,
        brand,
        program,
        kasur,
        ukuran,
        divan,
        headboard,
        sorong,
        isSet,
        pricelist,
        eupKasur,
        eupDivan,
        eupHeadboard,
        eupSorong,
        plKasur,
        plDivan,
        plHeadboard,
        plSorong,
        bonus1,
        qtyBonus1,
        bonus2,
        qtyBonus2,
        bonus3,
        qtyBonus3,
        bonus4,
        qtyBonus4,
        bonus5,
        qtyBonus5,
        bonus6,
        qtyBonus6,
        bonus7,
        qtyBonus7,
        bonus8,
        qtyBonus8,
        plBonus1,
        plBonus2,
        plBonus3,
        plBonus4,
        plBonus5,
        plBonus6,
        plBonus7,
        plBonus8,
        bottomPriceAnalyst,
        disc1,
        disc2,
        disc3,
        disc4,
        disc5,
        disc6,
        disc7,
        disc8
      ]);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductImplToJson(
      this,
    );
  }
}

abstract class _Product implements Product {
  const factory _Product(
      {required final String id,
      required final String name,
      @JsonKey(fromJson: _parseDouble) required final double price,
      required final String imageUrl,
      required final String category,
      final String description,
      final bool isAvailable,
      final String channel,
      final String brand,
      final String program,
      required final String kasur,
      required final String ukuran,
      required final String divan,
      required final String headboard,
      required final String sorong,
      required final bool isSet,
      @JsonKey(fromJson: _parseDouble) required final double pricelist,
      @JsonKey(fromJson: _parseDouble) required final double eupKasur,
      @JsonKey(fromJson: _parseDouble) required final double eupDivan,
      @JsonKey(fromJson: _parseDouble) required final double eupHeadboard,
      @JsonKey(fromJson: _parseDouble) required final double eupSorong,
      @JsonKey(fromJson: _parseDouble) required final double plKasur,
      @JsonKey(fromJson: _parseDouble) required final double plDivan,
      @JsonKey(fromJson: _parseDouble) required final double plHeadboard,
      @JsonKey(fromJson: _parseDouble) required final double plSorong,
      final String? bonus1,
      final int? qtyBonus1,
      final String? bonus2,
      final int? qtyBonus2,
      final String? bonus3,
      final int? qtyBonus3,
      final String? bonus4,
      final int? qtyBonus4,
      final String? bonus5,
      final int? qtyBonus5,
      final String? bonus6,
      final int? qtyBonus6,
      final String? bonus7,
      final int? qtyBonus7,
      final String? bonus8,
      final int? qtyBonus8,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus1,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus2,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus3,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus4,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus5,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus6,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus7,
      @JsonKey(fromJson: _parseDoubleNullable) final double? plBonus8,
      @JsonKey(fromJson: _parseDouble) final double bottomPriceAnalyst,
      @JsonKey(fromJson: _parseDouble) final double disc1,
      @JsonKey(fromJson: _parseDouble) final double disc2,
      @JsonKey(fromJson: _parseDouble) final double disc3,
      @JsonKey(fromJson: _parseDouble) final double disc4,
      @JsonKey(fromJson: _parseDouble) final double disc5,
      @JsonKey(fromJson: _parseDouble) final double disc6,
      @JsonKey(fromJson: _parseDouble) final double disc7,
      @JsonKey(fromJson: _parseDouble) final double disc8}) = _$ProductImpl;

  factory _Product.fromJson(Map<String, dynamic> json) = _$ProductImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get price;
  @override
  String get imageUrl;
  @override
  String get category;
  @override
  String get description;
  @override
  bool get isAvailable;
  @override
  String get channel;
  @override
  String get brand;
  @override
  String get program; // Specs for Sibling Grouping / Konfigurator Varian
  @override
  String get kasur;
  @override
  String get ukuran;
  @override
  String get divan;
  @override
  String get headboard;
  @override
  String get sorong;
  @override
  bool get isSet;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get pricelist;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get eupKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get eupDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get eupHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get eupSorong; // Pricelist per komponen (breakdown)
  @override
  @JsonKey(fromJson: _parseDouble)
  double get plKasur;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get plDivan;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get plHeadboard;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get plSorong; // Bonus (nullable)
  @override
  String? get bonus1;
  @override
  int? get qtyBonus1;
  @override
  String? get bonus2;
  @override
  int? get qtyBonus2;
  @override
  String? get bonus3;
  @override
  int? get qtyBonus3;
  @override
  String? get bonus4;
  @override
  int? get qtyBonus4;
  @override
  String? get bonus5;
  @override
  int? get qtyBonus5;
  @override
  String? get bonus6;
  @override
  int? get qtyBonus6;
  @override
  String? get bonus7;
  @override
  int? get qtyBonus7;
  @override
  String? get bonus8;
  @override
  int? get qtyBonus8; // Pricelist bonus (nilai Rupiah per bonus, nullable)
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus1;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus2;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus3;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus4;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus5;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus6;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double? get plBonus7;
  @override
  @JsonKey(fromJson: _parseDoubleNullable)
  double?
      get plBonus8; // Batas harga bawah analyst: total jual tidak boleh melebihi nilai ini
  @override
  @JsonKey(fromJson: _parseDouble)
  double
      get bottomPriceAnalyst; // Batas maksimal diskon (limit) per tingkat — dari database
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc1;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc2;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc3;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc4;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc5;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc6;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc7;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get disc8;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
