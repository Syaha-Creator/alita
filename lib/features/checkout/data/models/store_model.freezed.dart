// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StoreModel _$StoreModelFromJson(Map<String, dynamic> json) {
  return _StoreModel.fromJson(json);
}

/// @nodoc
mixin _$StoreModel {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;

  /// Provinsi dari API `/all_stores` (mis. "Daerah Khusus Ibukota Jakarta").
  String get state => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get area => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;

  /// Serializes this StoreModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StoreModelCopyWith<StoreModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreModelCopyWith<$Res> {
  factory $StoreModelCopyWith(
          StoreModel value, $Res Function(StoreModel) then) =
      _$StoreModelCopyWithImpl<$Res, StoreModel>;
  @useResult
  $Res call(
      {int id,
      String name,
      String category,
      String address,
      String state,
      String city,
      String area,
      String phone,
      String image});
}

/// @nodoc
class _$StoreModelCopyWithImpl<$Res, $Val extends StoreModel>
    implements $StoreModelCopyWith<$Res> {
  _$StoreModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? address = null,
    Object? state = null,
    Object? city = null,
    Object? area = null,
    Object? phone = null,
    Object? image = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StoreModelImplCopyWith<$Res>
    implements $StoreModelCopyWith<$Res> {
  factory _$$StoreModelImplCopyWith(
          _$StoreModelImpl value, $Res Function(_$StoreModelImpl) then) =
      __$$StoreModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      String category,
      String address,
      String state,
      String city,
      String area,
      String phone,
      String image});
}

/// @nodoc
class __$$StoreModelImplCopyWithImpl<$Res>
    extends _$StoreModelCopyWithImpl<$Res, _$StoreModelImpl>
    implements _$$StoreModelImplCopyWith<$Res> {
  __$$StoreModelImplCopyWithImpl(
      _$StoreModelImpl _value, $Res Function(_$StoreModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? address = null,
    Object? state = null,
    Object? city = null,
    Object? area = null,
    Object? phone = null,
    Object? image = null,
  }) {
    return _then(_$StoreModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StoreModelImpl implements _StoreModel {
  const _$StoreModelImpl(
      {required this.id,
      this.name = '',
      this.category = '',
      this.address = '',
      this.state = '',
      this.city = '',
      this.area = '',
      this.phone = '',
      this.image = ''});

  factory _$StoreModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey()
  final String address;

  /// Provinsi dari API `/all_stores` (mis. "Daerah Khusus Ibukota Jakarta").
  @override
  @JsonKey()
  final String state;
  @override
  @JsonKey()
  final String city;
  @override
  @JsonKey()
  final String area;
  @override
  @JsonKey()
  final String phone;
  @override
  @JsonKey()
  final String image;

  @override
  String toString() {
    return 'StoreModel(id: $id, name: $name, category: $category, address: $address, state: $state, city: $city, area: $area, phone: $phone, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.area, area) || other.area == area) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.image, image) || other.image == image));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, category, address,
      state, city, area, phone, image);

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      __$$StoreModelImplCopyWithImpl<_$StoreModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreModelImplToJson(
      this,
    );
  }
}

abstract class _StoreModel implements StoreModel {
  const factory _StoreModel(
      {required final int id,
      final String name,
      final String category,
      final String address,
      final String state,
      final String city,
      final String area,
      final String phone,
      final String image}) = _$StoreModelImpl;

  factory _StoreModel.fromJson(Map<String, dynamic> json) =
      _$StoreModelImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get category;
  @override
  String get address;

  /// Provinsi dari API `/all_stores` (mis. "Daerah Khusus Ibukota Jakarta").
  @override
  String get state;
  @override
  String get city;
  @override
  String get area;
  @override
  String get phone;
  @override
  String get image;

  /// Create a copy of StoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StoreModelImplCopyWith<_$StoreModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
