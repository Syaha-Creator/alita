// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrderHistory _$OrderHistoryFromJson(Map<String, dynamic> json) {
  return _OrderHistory.fromJson(json);
}

/// @nodoc
mixin _$OrderHistory {
  int get id => throw _privateConstructorUsedError;
  String get noSp => throw _privateConstructorUsedError;
  String get orderDate => throw _privateConstructorUsedError;
  String get requestDate => throw _privateConstructorUsedError;
  String get note => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get shipToName => throw _privateConstructorUsedError;
  String get addressShipTo => throw _privateConstructorUsedError;
  String? get noPo => throw _privateConstructorUsedError;
  bool get isTakeAway => throw _privateConstructorUsedError;
  String get workPlaceName => throw _privateConstructorUsedError;
  String get companyName => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get totalAmount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get postage => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get creator => throw _privateConstructorUsedError;
  String get creatorName => throw _privateConstructorUsedError;
  String get salesCode => throw _privateConstructorUsedError;
  String get salesName => throw _privateConstructorUsedError;
  List<OrderDetail> get details => throw _privateConstructorUsedError;
  List<OrderPayment> get payments => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderHistory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderHistoryCopyWith<OrderHistory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderHistoryCopyWith<$Res> {
  factory $OrderHistoryCopyWith(
          OrderHistory value, $Res Function(OrderHistory) then) =
      _$OrderHistoryCopyWithImpl<$Res, OrderHistory>;
  @useResult
  $Res call(
      {int id,
      String noSp,
      String orderDate,
      String requestDate,
      String note,
      String customerName,
      String phone,
      String address,
      String email,
      String shipToName,
      String addressShipTo,
      String? noPo,
      bool isTakeAway,
      String workPlaceName,
      String companyName,
      @JsonKey(fromJson: _parseDouble) double totalAmount,
      @JsonKey(fromJson: _parseDouble) double postage,
      String status,
      String creator,
      String creatorName,
      String salesCode,
      String salesName,
      List<OrderDetail> details,
      List<OrderPayment> payments,
      DateTime? createdAt});
}

/// @nodoc
class _$OrderHistoryCopyWithImpl<$Res, $Val extends OrderHistory>
    implements $OrderHistoryCopyWith<$Res> {
  _$OrderHistoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noSp = null,
    Object? orderDate = null,
    Object? requestDate = null,
    Object? note = null,
    Object? customerName = null,
    Object? phone = null,
    Object? address = null,
    Object? email = null,
    Object? shipToName = null,
    Object? addressShipTo = null,
    Object? noPo = freezed,
    Object? isTakeAway = null,
    Object? workPlaceName = null,
    Object? companyName = null,
    Object? totalAmount = null,
    Object? postage = null,
    Object? status = null,
    Object? creator = null,
    Object? creatorName = null,
    Object? salesCode = null,
    Object? salesName = null,
    Object? details = null,
    Object? payments = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      noSp: null == noSp
          ? _value.noSp
          : noSp // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      requestDate: null == requestDate
          ? _value.requestDate
          : requestDate // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      shipToName: null == shipToName
          ? _value.shipToName
          : shipToName // ignore: cast_nullable_to_non_nullable
              as String,
      addressShipTo: null == addressShipTo
          ? _value.addressShipTo
          : addressShipTo // ignore: cast_nullable_to_non_nullable
              as String,
      noPo: freezed == noPo
          ? _value.noPo
          : noPo // ignore: cast_nullable_to_non_nullable
              as String?,
      isTakeAway: null == isTakeAway
          ? _value.isTakeAway
          : isTakeAway // ignore: cast_nullable_to_non_nullable
              as bool,
      workPlaceName: null == workPlaceName
          ? _value.workPlaceName
          : workPlaceName // ignore: cast_nullable_to_non_nullable
              as String,
      companyName: null == companyName
          ? _value.companyName
          : companyName // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      postage: null == postage
          ? _value.postage
          : postage // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      creator: null == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: null == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String,
      salesCode: null == salesCode
          ? _value.salesCode
          : salesCode // ignore: cast_nullable_to_non_nullable
              as String,
      salesName: null == salesName
          ? _value.salesName
          : salesName // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as List<OrderDetail>,
      payments: null == payments
          ? _value.payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<OrderPayment>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderHistoryImplCopyWith<$Res>
    implements $OrderHistoryCopyWith<$Res> {
  factory _$$OrderHistoryImplCopyWith(
          _$OrderHistoryImpl value, $Res Function(_$OrderHistoryImpl) then) =
      __$$OrderHistoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String noSp,
      String orderDate,
      String requestDate,
      String note,
      String customerName,
      String phone,
      String address,
      String email,
      String shipToName,
      String addressShipTo,
      String? noPo,
      bool isTakeAway,
      String workPlaceName,
      String companyName,
      @JsonKey(fromJson: _parseDouble) double totalAmount,
      @JsonKey(fromJson: _parseDouble) double postage,
      String status,
      String creator,
      String creatorName,
      String salesCode,
      String salesName,
      List<OrderDetail> details,
      List<OrderPayment> payments,
      DateTime? createdAt});
}

/// @nodoc
class __$$OrderHistoryImplCopyWithImpl<$Res>
    extends _$OrderHistoryCopyWithImpl<$Res, _$OrderHistoryImpl>
    implements _$$OrderHistoryImplCopyWith<$Res> {
  __$$OrderHistoryImplCopyWithImpl(
      _$OrderHistoryImpl _value, $Res Function(_$OrderHistoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderHistory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noSp = null,
    Object? orderDate = null,
    Object? requestDate = null,
    Object? note = null,
    Object? customerName = null,
    Object? phone = null,
    Object? address = null,
    Object? email = null,
    Object? shipToName = null,
    Object? addressShipTo = null,
    Object? noPo = freezed,
    Object? isTakeAway = null,
    Object? workPlaceName = null,
    Object? companyName = null,
    Object? totalAmount = null,
    Object? postage = null,
    Object? status = null,
    Object? creator = null,
    Object? creatorName = null,
    Object? salesCode = null,
    Object? salesName = null,
    Object? details = null,
    Object? payments = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$OrderHistoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      noSp: null == noSp
          ? _value.noSp
          : noSp // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      requestDate: null == requestDate
          ? _value.requestDate
          : requestDate // ignore: cast_nullable_to_non_nullable
              as String,
      note: null == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      shipToName: null == shipToName
          ? _value.shipToName
          : shipToName // ignore: cast_nullable_to_non_nullable
              as String,
      addressShipTo: null == addressShipTo
          ? _value.addressShipTo
          : addressShipTo // ignore: cast_nullable_to_non_nullable
              as String,
      noPo: freezed == noPo
          ? _value.noPo
          : noPo // ignore: cast_nullable_to_non_nullable
              as String?,
      isTakeAway: null == isTakeAway
          ? _value.isTakeAway
          : isTakeAway // ignore: cast_nullable_to_non_nullable
              as bool,
      workPlaceName: null == workPlaceName
          ? _value.workPlaceName
          : workPlaceName // ignore: cast_nullable_to_non_nullable
              as String,
      companyName: null == companyName
          ? _value.companyName
          : companyName // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      postage: null == postage
          ? _value.postage
          : postage // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      creator: null == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as String,
      creatorName: null == creatorName
          ? _value.creatorName
          : creatorName // ignore: cast_nullable_to_non_nullable
              as String,
      salesCode: null == salesCode
          ? _value.salesCode
          : salesCode // ignore: cast_nullable_to_non_nullable
              as String,
      salesName: null == salesName
          ? _value.salesName
          : salesName // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value._details
          : details // ignore: cast_nullable_to_non_nullable
              as List<OrderDetail>,
      payments: null == payments
          ? _value._payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<OrderPayment>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderHistoryImpl implements _OrderHistory {
  const _$OrderHistoryImpl(
      {required this.id,
      required this.noSp,
      required this.orderDate,
      required this.requestDate,
      required this.note,
      required this.customerName,
      required this.phone,
      required this.address,
      required this.email,
      this.shipToName = '',
      this.addressShipTo = '',
      this.noPo,
      required this.isTakeAway,
      required this.workPlaceName,
      required this.companyName,
      @JsonKey(fromJson: _parseDouble) required this.totalAmount,
      @JsonKey(fromJson: _parseDouble) this.postage = 0,
      required this.status,
      this.creator = '',
      this.creatorName = '',
      this.salesCode = '',
      this.salesName = '',
      final List<OrderDetail> details = const <OrderDetail>[],
      final List<OrderPayment> payments = const <OrderPayment>[],
      this.createdAt})
      : _details = details,
        _payments = payments;

  factory _$OrderHistoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderHistoryImplFromJson(json);

  @override
  final int id;
  @override
  final String noSp;
  @override
  final String orderDate;
  @override
  final String requestDate;
  @override
  final String note;
  @override
  final String customerName;
  @override
  final String phone;
  @override
  final String address;
  @override
  final String email;
  @override
  @JsonKey()
  final String shipToName;
  @override
  @JsonKey()
  final String addressShipTo;
  @override
  final String? noPo;
  @override
  final bool isTakeAway;
  @override
  final String workPlaceName;
  @override
  final String companyName;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double totalAmount;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double postage;
  @override
  final String status;
  @override
  @JsonKey()
  final String creator;
  @override
  @JsonKey()
  final String creatorName;
  @override
  @JsonKey()
  final String salesCode;
  @override
  @JsonKey()
  final String salesName;
  final List<OrderDetail> _details;
  @override
  @JsonKey()
  List<OrderDetail> get details {
    if (_details is EqualUnmodifiableListView) return _details;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_details);
  }

  final List<OrderPayment> _payments;
  @override
  @JsonKey()
  List<OrderPayment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'OrderHistory(id: $id, noSp: $noSp, orderDate: $orderDate, requestDate: $requestDate, note: $note, customerName: $customerName, phone: $phone, address: $address, email: $email, shipToName: $shipToName, addressShipTo: $addressShipTo, noPo: $noPo, isTakeAway: $isTakeAway, workPlaceName: $workPlaceName, companyName: $companyName, totalAmount: $totalAmount, postage: $postage, status: $status, creator: $creator, creatorName: $creatorName, salesCode: $salesCode, salesName: $salesName, details: $details, payments: $payments, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderHistoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.noSp, noSp) || other.noSp == noSp) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
            (identical(other.requestDate, requestDate) ||
                other.requestDate == requestDate) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.shipToName, shipToName) ||
                other.shipToName == shipToName) &&
            (identical(other.addressShipTo, addressShipTo) ||
                other.addressShipTo == addressShipTo) &&
            (identical(other.noPo, noPo) || other.noPo == noPo) &&
            (identical(other.isTakeAway, isTakeAway) ||
                other.isTakeAway == isTakeAway) &&
            (identical(other.workPlaceName, workPlaceName) ||
                other.workPlaceName == workPlaceName) &&
            (identical(other.companyName, companyName) ||
                other.companyName == companyName) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.postage, postage) || other.postage == postage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.creatorName, creatorName) ||
                other.creatorName == creatorName) &&
            (identical(other.salesCode, salesCode) ||
                other.salesCode == salesCode) &&
            (identical(other.salesName, salesName) ||
                other.salesName == salesName) &&
            const DeepCollectionEquality().equals(other._details, _details) &&
            const DeepCollectionEquality().equals(other._payments, _payments) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        noSp,
        orderDate,
        requestDate,
        note,
        customerName,
        phone,
        address,
        email,
        shipToName,
        addressShipTo,
        noPo,
        isTakeAway,
        workPlaceName,
        companyName,
        totalAmount,
        postage,
        status,
        creator,
        creatorName,
        salesCode,
        salesName,
        const DeepCollectionEquality().hash(_details),
        const DeepCollectionEquality().hash(_payments),
        createdAt
      ]);

  /// Create a copy of OrderHistory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderHistoryImplCopyWith<_$OrderHistoryImpl> get copyWith =>
      __$$OrderHistoryImplCopyWithImpl<_$OrderHistoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderHistoryImplToJson(
      this,
    );
  }
}

abstract class _OrderHistory implements OrderHistory {
  const factory _OrderHistory(
      {required final int id,
      required final String noSp,
      required final String orderDate,
      required final String requestDate,
      required final String note,
      required final String customerName,
      required final String phone,
      required final String address,
      required final String email,
      final String shipToName,
      final String addressShipTo,
      final String? noPo,
      required final bool isTakeAway,
      required final String workPlaceName,
      required final String companyName,
      @JsonKey(fromJson: _parseDouble) required final double totalAmount,
      @JsonKey(fromJson: _parseDouble) final double postage,
      required final String status,
      final String creator,
      final String creatorName,
      final String salesCode,
      final String salesName,
      final List<OrderDetail> details,
      final List<OrderPayment> payments,
      final DateTime? createdAt}) = _$OrderHistoryImpl;

  factory _OrderHistory.fromJson(Map<String, dynamic> json) =
      _$OrderHistoryImpl.fromJson;

  @override
  int get id;
  @override
  String get noSp;
  @override
  String get orderDate;
  @override
  String get requestDate;
  @override
  String get note;
  @override
  String get customerName;
  @override
  String get phone;
  @override
  String get address;
  @override
  String get email;
  @override
  String get shipToName;
  @override
  String get addressShipTo;
  @override
  String? get noPo;
  @override
  bool get isTakeAway;
  @override
  String get workPlaceName;
  @override
  String get companyName;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get totalAmount;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get postage;
  @override
  String get status;
  @override
  String get creator;
  @override
  String get creatorName;
  @override
  String get salesCode;
  @override
  String get salesName;
  @override
  List<OrderDetail> get details;
  @override
  List<OrderPayment> get payments;
  @override
  DateTime? get createdAt;

  /// Create a copy of OrderHistory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderHistoryImplCopyWith<_$OrderHistoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderDetail _$OrderDetailFromJson(Map<String, dynamic> json) {
  return _OrderDetail.fromJson(json);
}

/// @nodoc
mixin _$OrderDetail {
  int get id => throw _privateConstructorUsedError;
  String get noSp => throw _privateConstructorUsedError;
  String get itemDescription => throw _privateConstructorUsedError;
  String get desc1 => throw _privateConstructorUsedError;
  String get itemType => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get customerPrice => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get netPrice => throw _privateConstructorUsedError;
  String get brand => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get extendedPrice => throw _privateConstructorUsedError;
  List<OrderDiscount> get discounts => throw _privateConstructorUsedError;

  /// Serializes this OrderDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderDetailCopyWith<OrderDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderDetailCopyWith<$Res> {
  factory $OrderDetailCopyWith(
          OrderDetail value, $Res Function(OrderDetail) then) =
      _$OrderDetailCopyWithImpl<$Res, OrderDetail>;
  @useResult
  $Res call(
      {int id,
      String noSp,
      String itemDescription,
      String desc1,
      String itemType,
      int qty,
      @JsonKey(fromJson: _parseDouble) double customerPrice,
      @JsonKey(fromJson: _parseDouble) double netPrice,
      String brand,
      @JsonKey(fromJson: _parseDouble) double unitPrice,
      @JsonKey(fromJson: _parseDouble) double extendedPrice,
      List<OrderDiscount> discounts});
}

/// @nodoc
class _$OrderDetailCopyWithImpl<$Res, $Val extends OrderDetail>
    implements $OrderDetailCopyWith<$Res> {
  _$OrderDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noSp = null,
    Object? itemDescription = null,
    Object? desc1 = null,
    Object? itemType = null,
    Object? qty = null,
    Object? customerPrice = null,
    Object? netPrice = null,
    Object? brand = null,
    Object? unitPrice = null,
    Object? extendedPrice = null,
    Object? discounts = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      noSp: null == noSp
          ? _value.noSp
          : noSp // ignore: cast_nullable_to_non_nullable
              as String,
      itemDescription: null == itemDescription
          ? _value.itemDescription
          : itemDescription // ignore: cast_nullable_to_non_nullable
              as String,
      desc1: null == desc1
          ? _value.desc1
          : desc1 // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      customerPrice: null == customerPrice
          ? _value.customerPrice
          : customerPrice // ignore: cast_nullable_to_non_nullable
              as double,
      netPrice: null == netPrice
          ? _value.netPrice
          : netPrice // ignore: cast_nullable_to_non_nullable
              as double,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      extendedPrice: null == extendedPrice
          ? _value.extendedPrice
          : extendedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      discounts: null == discounts
          ? _value.discounts
          : discounts // ignore: cast_nullable_to_non_nullable
              as List<OrderDiscount>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderDetailImplCopyWith<$Res>
    implements $OrderDetailCopyWith<$Res> {
  factory _$$OrderDetailImplCopyWith(
          _$OrderDetailImpl value, $Res Function(_$OrderDetailImpl) then) =
      __$$OrderDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String noSp,
      String itemDescription,
      String desc1,
      String itemType,
      int qty,
      @JsonKey(fromJson: _parseDouble) double customerPrice,
      @JsonKey(fromJson: _parseDouble) double netPrice,
      String brand,
      @JsonKey(fromJson: _parseDouble) double unitPrice,
      @JsonKey(fromJson: _parseDouble) double extendedPrice,
      List<OrderDiscount> discounts});
}

/// @nodoc
class __$$OrderDetailImplCopyWithImpl<$Res>
    extends _$OrderDetailCopyWithImpl<$Res, _$OrderDetailImpl>
    implements _$$OrderDetailImplCopyWith<$Res> {
  __$$OrderDetailImplCopyWithImpl(
      _$OrderDetailImpl _value, $Res Function(_$OrderDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? noSp = null,
    Object? itemDescription = null,
    Object? desc1 = null,
    Object? itemType = null,
    Object? qty = null,
    Object? customerPrice = null,
    Object? netPrice = null,
    Object? brand = null,
    Object? unitPrice = null,
    Object? extendedPrice = null,
    Object? discounts = null,
  }) {
    return _then(_$OrderDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      noSp: null == noSp
          ? _value.noSp
          : noSp // ignore: cast_nullable_to_non_nullable
              as String,
      itemDescription: null == itemDescription
          ? _value.itemDescription
          : itemDescription // ignore: cast_nullable_to_non_nullable
              as String,
      desc1: null == desc1
          ? _value.desc1
          : desc1 // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as int,
      customerPrice: null == customerPrice
          ? _value.customerPrice
          : customerPrice // ignore: cast_nullable_to_non_nullable
              as double,
      netPrice: null == netPrice
          ? _value.netPrice
          : netPrice // ignore: cast_nullable_to_non_nullable
              as double,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      extendedPrice: null == extendedPrice
          ? _value.extendedPrice
          : extendedPrice // ignore: cast_nullable_to_non_nullable
              as double,
      discounts: null == discounts
          ? _value._discounts
          : discounts // ignore: cast_nullable_to_non_nullable
              as List<OrderDiscount>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderDetailImpl implements _OrderDetail {
  const _$OrderDetailImpl(
      {required this.id,
      this.noSp = '-',
      required this.itemDescription,
      required this.desc1,
      required this.itemType,
      required this.qty,
      @JsonKey(fromJson: _parseDouble) required this.customerPrice,
      @JsonKey(fromJson: _parseDouble) required this.netPrice,
      required this.brand,
      @JsonKey(fromJson: _parseDouble) required this.unitPrice,
      @JsonKey(fromJson: _parseDouble) this.extendedPrice = 0,
      final List<OrderDiscount> discounts = const <OrderDiscount>[]})
      : _discounts = discounts;

  factory _$OrderDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderDetailImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey()
  final String noSp;
  @override
  final String itemDescription;
  @override
  final String desc1;
  @override
  final String itemType;
  @override
  final int qty;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double customerPrice;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double netPrice;
  @override
  final String brand;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double unitPrice;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double extendedPrice;
  final List<OrderDiscount> _discounts;
  @override
  @JsonKey()
  List<OrderDiscount> get discounts {
    if (_discounts is EqualUnmodifiableListView) return _discounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_discounts);
  }

  @override
  String toString() {
    return 'OrderDetail(id: $id, noSp: $noSp, itemDescription: $itemDescription, desc1: $desc1, itemType: $itemType, qty: $qty, customerPrice: $customerPrice, netPrice: $netPrice, brand: $brand, unitPrice: $unitPrice, extendedPrice: $extendedPrice, discounts: $discounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.noSp, noSp) || other.noSp == noSp) &&
            (identical(other.itemDescription, itemDescription) ||
                other.itemDescription == itemDescription) &&
            (identical(other.desc1, desc1) || other.desc1 == desc1) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.customerPrice, customerPrice) ||
                other.customerPrice == customerPrice) &&
            (identical(other.netPrice, netPrice) ||
                other.netPrice == netPrice) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.extendedPrice, extendedPrice) ||
                other.extendedPrice == extendedPrice) &&
            const DeepCollectionEquality()
                .equals(other._discounts, _discounts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      noSp,
      itemDescription,
      desc1,
      itemType,
      qty,
      customerPrice,
      netPrice,
      brand,
      unitPrice,
      extendedPrice,
      const DeepCollectionEquality().hash(_discounts));

  /// Create a copy of OrderDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderDetailImplCopyWith<_$OrderDetailImpl> get copyWith =>
      __$$OrderDetailImplCopyWithImpl<_$OrderDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderDetailImplToJson(
      this,
    );
  }
}

abstract class _OrderDetail implements OrderDetail {
  const factory _OrderDetail(
      {required final int id,
      final String noSp,
      required final String itemDescription,
      required final String desc1,
      required final String itemType,
      required final int qty,
      @JsonKey(fromJson: _parseDouble) required final double customerPrice,
      @JsonKey(fromJson: _parseDouble) required final double netPrice,
      required final String brand,
      @JsonKey(fromJson: _parseDouble) required final double unitPrice,
      @JsonKey(fromJson: _parseDouble) final double extendedPrice,
      final List<OrderDiscount> discounts}) = _$OrderDetailImpl;

  factory _OrderDetail.fromJson(Map<String, dynamic> json) =
      _$OrderDetailImpl.fromJson;

  @override
  int get id;
  @override
  String get noSp;
  @override
  String get itemDescription;
  @override
  String get desc1;
  @override
  String get itemType;
  @override
  int get qty;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get customerPrice;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get netPrice;
  @override
  String get brand;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get unitPrice;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get extendedPrice;
  @override
  List<OrderDiscount> get discounts;

  /// Create a copy of OrderDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderDetailImplCopyWith<_$OrderDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderDiscount _$OrderDiscountFromJson(Map<String, dynamic> json) {
  return _OrderDiscount.fromJson(json);
}

/// @nodoc
mixin _$OrderDiscount {
  int get id => throw _privateConstructorUsedError;
  String get discountVal => throw _privateConstructorUsedError;
  String get approverName => throw _privateConstructorUsedError;
  String get approverLevel => throw _privateConstructorUsedError;
  String get approvedStatus => throw _privateConstructorUsedError;
  String? get approvedAt => throw _privateConstructorUsedError;

  /// Serializes this OrderDiscount to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderDiscount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderDiscountCopyWith<OrderDiscount> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderDiscountCopyWith<$Res> {
  factory $OrderDiscountCopyWith(
          OrderDiscount value, $Res Function(OrderDiscount) then) =
      _$OrderDiscountCopyWithImpl<$Res, OrderDiscount>;
  @useResult
  $Res call(
      {int id,
      String discountVal,
      String approverName,
      String approverLevel,
      String approvedStatus,
      String? approvedAt});
}

/// @nodoc
class _$OrderDiscountCopyWithImpl<$Res, $Val extends OrderDiscount>
    implements $OrderDiscountCopyWith<$Res> {
  _$OrderDiscountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderDiscount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? discountVal = null,
    Object? approverName = null,
    Object? approverLevel = null,
    Object? approvedStatus = null,
    Object? approvedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      discountVal: null == discountVal
          ? _value.discountVal
          : discountVal // ignore: cast_nullable_to_non_nullable
              as String,
      approverName: null == approverName
          ? _value.approverName
          : approverName // ignore: cast_nullable_to_non_nullable
              as String,
      approverLevel: null == approverLevel
          ? _value.approverLevel
          : approverLevel // ignore: cast_nullable_to_non_nullable
              as String,
      approvedStatus: null == approvedStatus
          ? _value.approvedStatus
          : approvedStatus // ignore: cast_nullable_to_non_nullable
              as String,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderDiscountImplCopyWith<$Res>
    implements $OrderDiscountCopyWith<$Res> {
  factory _$$OrderDiscountImplCopyWith(
          _$OrderDiscountImpl value, $Res Function(_$OrderDiscountImpl) then) =
      __$$OrderDiscountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String discountVal,
      String approverName,
      String approverLevel,
      String approvedStatus,
      String? approvedAt});
}

/// @nodoc
class __$$OrderDiscountImplCopyWithImpl<$Res>
    extends _$OrderDiscountCopyWithImpl<$Res, _$OrderDiscountImpl>
    implements _$$OrderDiscountImplCopyWith<$Res> {
  __$$OrderDiscountImplCopyWithImpl(
      _$OrderDiscountImpl _value, $Res Function(_$OrderDiscountImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderDiscount
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? discountVal = null,
    Object? approverName = null,
    Object? approverLevel = null,
    Object? approvedStatus = null,
    Object? approvedAt = freezed,
  }) {
    return _then(_$OrderDiscountImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      discountVal: null == discountVal
          ? _value.discountVal
          : discountVal // ignore: cast_nullable_to_non_nullable
              as String,
      approverName: null == approverName
          ? _value.approverName
          : approverName // ignore: cast_nullable_to_non_nullable
              as String,
      approverLevel: null == approverLevel
          ? _value.approverLevel
          : approverLevel // ignore: cast_nullable_to_non_nullable
              as String,
      approvedStatus: null == approvedStatus
          ? _value.approvedStatus
          : approvedStatus // ignore: cast_nullable_to_non_nullable
              as String,
      approvedAt: freezed == approvedAt
          ? _value.approvedAt
          : approvedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderDiscountImpl implements _OrderDiscount {
  const _$OrderDiscountImpl(
      {required this.id,
      required this.discountVal,
      required this.approverName,
      required this.approverLevel,
      required this.approvedStatus,
      this.approvedAt});

  factory _$OrderDiscountImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderDiscountImplFromJson(json);

  @override
  final int id;
  @override
  final String discountVal;
  @override
  final String approverName;
  @override
  final String approverLevel;
  @override
  final String approvedStatus;
  @override
  final String? approvedAt;

  @override
  String toString() {
    return 'OrderDiscount(id: $id, discountVal: $discountVal, approverName: $approverName, approverLevel: $approverLevel, approvedStatus: $approvedStatus, approvedAt: $approvedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderDiscountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.discountVal, discountVal) ||
                other.discountVal == discountVal) &&
            (identical(other.approverName, approverName) ||
                other.approverName == approverName) &&
            (identical(other.approverLevel, approverLevel) ||
                other.approverLevel == approverLevel) &&
            (identical(other.approvedStatus, approvedStatus) ||
                other.approvedStatus == approvedStatus) &&
            (identical(other.approvedAt, approvedAt) ||
                other.approvedAt == approvedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, discountVal, approverName,
      approverLevel, approvedStatus, approvedAt);

  /// Create a copy of OrderDiscount
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderDiscountImplCopyWith<_$OrderDiscountImpl> get copyWith =>
      __$$OrderDiscountImplCopyWithImpl<_$OrderDiscountImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderDiscountImplToJson(
      this,
    );
  }
}

abstract class _OrderDiscount implements OrderDiscount {
  const factory _OrderDiscount(
      {required final int id,
      required final String discountVal,
      required final String approverName,
      required final String approverLevel,
      required final String approvedStatus,
      final String? approvedAt}) = _$OrderDiscountImpl;

  factory _OrderDiscount.fromJson(Map<String, dynamic> json) =
      _$OrderDiscountImpl.fromJson;

  @override
  int get id;
  @override
  String get discountVal;
  @override
  String get approverName;
  @override
  String get approverLevel;
  @override
  String get approvedStatus;
  @override
  String? get approvedAt;

  /// Create a copy of OrderDiscount
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderDiscountImplCopyWith<_$OrderDiscountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderPayment _$OrderPaymentFromJson(Map<String, dynamic> json) {
  return _OrderPayment.fromJson(json);
}

/// @nodoc
mixin _$OrderPayment {
  String get method => throw _privateConstructorUsedError;
  String get bank => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseDouble)
  double get amount => throw _privateConstructorUsedError;
  String get image => throw _privateConstructorUsedError;
  String get paymentDate => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;

  /// Serializes this OrderPayment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderPaymentCopyWith<OrderPayment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderPaymentCopyWith<$Res> {
  factory $OrderPaymentCopyWith(
          OrderPayment value, $Res Function(OrderPayment) then) =
      _$OrderPaymentCopyWithImpl<$Res, OrderPayment>;
  @useResult
  $Res call(
      {String method,
      String bank,
      @JsonKey(fromJson: _parseDouble) double amount,
      String image,
      String paymentDate,
      String createdAt});
}

/// @nodoc
class _$OrderPaymentCopyWithImpl<$Res, $Val extends OrderPayment>
    implements $OrderPaymentCopyWith<$Res> {
  _$OrderPaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? bank = null,
    Object? amount = null,
    Object? image = null,
    Object? paymentDate = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      bank: null == bank
          ? _value.bank
          : bank // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      paymentDate: null == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderPaymentImplCopyWith<$Res>
    implements $OrderPaymentCopyWith<$Res> {
  factory _$$OrderPaymentImplCopyWith(
          _$OrderPaymentImpl value, $Res Function(_$OrderPaymentImpl) then) =
      __$$OrderPaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String method,
      String bank,
      @JsonKey(fromJson: _parseDouble) double amount,
      String image,
      String paymentDate,
      String createdAt});
}

/// @nodoc
class __$$OrderPaymentImplCopyWithImpl<$Res>
    extends _$OrderPaymentCopyWithImpl<$Res, _$OrderPaymentImpl>
    implements _$$OrderPaymentImplCopyWith<$Res> {
  __$$OrderPaymentImplCopyWithImpl(
      _$OrderPaymentImpl _value, $Res Function(_$OrderPaymentImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderPayment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? method = null,
    Object? bank = null,
    Object? amount = null,
    Object? image = null,
    Object? paymentDate = null,
    Object? createdAt = null,
  }) {
    return _then(_$OrderPaymentImpl(
      method: null == method
          ? _value.method
          : method // ignore: cast_nullable_to_non_nullable
              as String,
      bank: null == bank
          ? _value.bank
          : bank // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      image: null == image
          ? _value.image
          : image // ignore: cast_nullable_to_non_nullable
              as String,
      paymentDate: null == paymentDate
          ? _value.paymentDate
          : paymentDate // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderPaymentImpl implements _OrderPayment {
  const _$OrderPaymentImpl(
      {required this.method,
      required this.bank,
      @JsonKey(fromJson: _parseDouble) required this.amount,
      required this.image,
      this.paymentDate = '',
      this.createdAt = ''});

  factory _$OrderPaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderPaymentImplFromJson(json);

  @override
  final String method;
  @override
  final String bank;
  @override
  @JsonKey(fromJson: _parseDouble)
  final double amount;
  @override
  final String image;
  @override
  @JsonKey()
  final String paymentDate;
  @override
  @JsonKey()
  final String createdAt;

  @override
  String toString() {
    return 'OrderPayment(method: $method, bank: $bank, amount: $amount, image: $image, paymentDate: $paymentDate, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderPaymentImpl &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.image, image) || other.image == image) &&
            (identical(other.paymentDate, paymentDate) ||
                other.paymentDate == paymentDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, method, bank, amount, image, paymentDate, createdAt);

  /// Create a copy of OrderPayment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderPaymentImplCopyWith<_$OrderPaymentImpl> get copyWith =>
      __$$OrderPaymentImplCopyWithImpl<_$OrderPaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderPaymentImplToJson(
      this,
    );
  }
}

abstract class _OrderPayment implements OrderPayment {
  const factory _OrderPayment(
      {required final String method,
      required final String bank,
      @JsonKey(fromJson: _parseDouble) required final double amount,
      required final String image,
      final String paymentDate,
      final String createdAt}) = _$OrderPaymentImpl;

  factory _OrderPayment.fromJson(Map<String, dynamic> json) =
      _$OrderPaymentImpl.fromJson;

  @override
  String get method;
  @override
  String get bank;
  @override
  @JsonKey(fromJson: _parseDouble)
  double get amount;
  @override
  String get image;
  @override
  String get paymentDate;
  @override
  String get createdAt;

  /// Create a copy of OrderPayment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderPaymentImplCopyWith<_$OrderPaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
