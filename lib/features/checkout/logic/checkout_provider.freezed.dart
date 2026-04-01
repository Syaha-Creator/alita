// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CheckoutState {
// Workplace / Store
  bool get isLoadingWorkPlace => throw _privateConstructorUsedError;
  int? get attendanceWorkPlaceId => throw _privateConstructorUsedError;
  String get attendanceWorkPlaceName => throw _privateConstructorUsedError;
  bool get useAttendanceStore => throw _privateConstructorUsedError;
  StoreModel? get selectedStore =>
      throw _privateConstructorUsedError; // Approvers
  List<Approver> get approvers => throw _privateConstructorUsedError;
  bool get isLoadingApprovers => throw _privateConstructorUsedError;
  String? get approversError => throw _privateConstructorUsedError;

  /// Judul kartu error (bukan lagi satu pesan generik untuk semua kasus).
  String? get approversErrorTitle => throw _privateConstructorUsedError;
  Approver? get selectedSpv => throw _privateConstructorUsedError;
  Approver? get selectedManager =>
      throw _privateConstructorUsedError; // Submission
  bool get isSubmitting => throw _privateConstructorUsedError;
  String? get submitError => throw _privateConstructorUsedError; // Retry
  int? get retryOrderId => throw _privateConstructorUsedError;
  String get retryNoSp => throw _privateConstructorUsedError;
  List<PendingDetail> get retryDetails =>
      throw _privateConstructorUsedError; // Result
  bool get submitSuccess => throw _privateConstructorUsedError;
  String? get successNoSp => throw _privateConstructorUsedError;

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckoutStateCopyWith<CheckoutState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckoutStateCopyWith<$Res> {
  factory $CheckoutStateCopyWith(
          CheckoutState value, $Res Function(CheckoutState) then) =
      _$CheckoutStateCopyWithImpl<$Res, CheckoutState>;
  @useResult
  $Res call(
      {bool isLoadingWorkPlace,
      int? attendanceWorkPlaceId,
      String attendanceWorkPlaceName,
      bool useAttendanceStore,
      StoreModel? selectedStore,
      List<Approver> approvers,
      bool isLoadingApprovers,
      String? approversError,
      String? approversErrorTitle,
      Approver? selectedSpv,
      Approver? selectedManager,
      bool isSubmitting,
      String? submitError,
      int? retryOrderId,
      String retryNoSp,
      List<PendingDetail> retryDetails,
      bool submitSuccess,
      String? successNoSp});

  $StoreModelCopyWith<$Res>? get selectedStore;
}

/// @nodoc
class _$CheckoutStateCopyWithImpl<$Res, $Val extends CheckoutState>
    implements $CheckoutStateCopyWith<$Res> {
  _$CheckoutStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingWorkPlace = null,
    Object? attendanceWorkPlaceId = freezed,
    Object? attendanceWorkPlaceName = null,
    Object? useAttendanceStore = null,
    Object? selectedStore = freezed,
    Object? approvers = null,
    Object? isLoadingApprovers = null,
    Object? approversError = freezed,
    Object? approversErrorTitle = freezed,
    Object? selectedSpv = freezed,
    Object? selectedManager = freezed,
    Object? isSubmitting = null,
    Object? submitError = freezed,
    Object? retryOrderId = freezed,
    Object? retryNoSp = null,
    Object? retryDetails = null,
    Object? submitSuccess = null,
    Object? successNoSp = freezed,
  }) {
    return _then(_value.copyWith(
      isLoadingWorkPlace: null == isLoadingWorkPlace
          ? _value.isLoadingWorkPlace
          : isLoadingWorkPlace // ignore: cast_nullable_to_non_nullable
              as bool,
      attendanceWorkPlaceId: freezed == attendanceWorkPlaceId
          ? _value.attendanceWorkPlaceId
          : attendanceWorkPlaceId // ignore: cast_nullable_to_non_nullable
              as int?,
      attendanceWorkPlaceName: null == attendanceWorkPlaceName
          ? _value.attendanceWorkPlaceName
          : attendanceWorkPlaceName // ignore: cast_nullable_to_non_nullable
              as String,
      useAttendanceStore: null == useAttendanceStore
          ? _value.useAttendanceStore
          : useAttendanceStore // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedStore: freezed == selectedStore
          ? _value.selectedStore
          : selectedStore // ignore: cast_nullable_to_non_nullable
              as StoreModel?,
      approvers: null == approvers
          ? _value.approvers
          : approvers // ignore: cast_nullable_to_non_nullable
              as List<Approver>,
      isLoadingApprovers: null == isLoadingApprovers
          ? _value.isLoadingApprovers
          : isLoadingApprovers // ignore: cast_nullable_to_non_nullable
              as bool,
      approversError: freezed == approversError
          ? _value.approversError
          : approversError // ignore: cast_nullable_to_non_nullable
              as String?,
      approversErrorTitle: freezed == approversErrorTitle
          ? _value.approversErrorTitle
          : approversErrorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedSpv: freezed == selectedSpv
          ? _value.selectedSpv
          : selectedSpv // ignore: cast_nullable_to_non_nullable
              as Approver?,
      selectedManager: freezed == selectedManager
          ? _value.selectedManager
          : selectedManager // ignore: cast_nullable_to_non_nullable
              as Approver?,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      submitError: freezed == submitError
          ? _value.submitError
          : submitError // ignore: cast_nullable_to_non_nullable
              as String?,
      retryOrderId: freezed == retryOrderId
          ? _value.retryOrderId
          : retryOrderId // ignore: cast_nullable_to_non_nullable
              as int?,
      retryNoSp: null == retryNoSp
          ? _value.retryNoSp
          : retryNoSp // ignore: cast_nullable_to_non_nullable
              as String,
      retryDetails: null == retryDetails
          ? _value.retryDetails
          : retryDetails // ignore: cast_nullable_to_non_nullable
              as List<PendingDetail>,
      submitSuccess: null == submitSuccess
          ? _value.submitSuccess
          : submitSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      successNoSp: freezed == successNoSp
          ? _value.successNoSp
          : successNoSp // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StoreModelCopyWith<$Res>? get selectedStore {
    if (_value.selectedStore == null) {
      return null;
    }

    return $StoreModelCopyWith<$Res>(_value.selectedStore!, (value) {
      return _then(_value.copyWith(selectedStore: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CheckoutStateImplCopyWith<$Res>
    implements $CheckoutStateCopyWith<$Res> {
  factory _$$CheckoutStateImplCopyWith(
          _$CheckoutStateImpl value, $Res Function(_$CheckoutStateImpl) then) =
      __$$CheckoutStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoadingWorkPlace,
      int? attendanceWorkPlaceId,
      String attendanceWorkPlaceName,
      bool useAttendanceStore,
      StoreModel? selectedStore,
      List<Approver> approvers,
      bool isLoadingApprovers,
      String? approversError,
      String? approversErrorTitle,
      Approver? selectedSpv,
      Approver? selectedManager,
      bool isSubmitting,
      String? submitError,
      int? retryOrderId,
      String retryNoSp,
      List<PendingDetail> retryDetails,
      bool submitSuccess,
      String? successNoSp});

  @override
  $StoreModelCopyWith<$Res>? get selectedStore;
}

/// @nodoc
class __$$CheckoutStateImplCopyWithImpl<$Res>
    extends _$CheckoutStateCopyWithImpl<$Res, _$CheckoutStateImpl>
    implements _$$CheckoutStateImplCopyWith<$Res> {
  __$$CheckoutStateImplCopyWithImpl(
      _$CheckoutStateImpl _value, $Res Function(_$CheckoutStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoadingWorkPlace = null,
    Object? attendanceWorkPlaceId = freezed,
    Object? attendanceWorkPlaceName = null,
    Object? useAttendanceStore = null,
    Object? selectedStore = freezed,
    Object? approvers = null,
    Object? isLoadingApprovers = null,
    Object? approversError = freezed,
    Object? approversErrorTitle = freezed,
    Object? selectedSpv = freezed,
    Object? selectedManager = freezed,
    Object? isSubmitting = null,
    Object? submitError = freezed,
    Object? retryOrderId = freezed,
    Object? retryNoSp = null,
    Object? retryDetails = null,
    Object? submitSuccess = null,
    Object? successNoSp = freezed,
  }) {
    return _then(_$CheckoutStateImpl(
      isLoadingWorkPlace: null == isLoadingWorkPlace
          ? _value.isLoadingWorkPlace
          : isLoadingWorkPlace // ignore: cast_nullable_to_non_nullable
              as bool,
      attendanceWorkPlaceId: freezed == attendanceWorkPlaceId
          ? _value.attendanceWorkPlaceId
          : attendanceWorkPlaceId // ignore: cast_nullable_to_non_nullable
              as int?,
      attendanceWorkPlaceName: null == attendanceWorkPlaceName
          ? _value.attendanceWorkPlaceName
          : attendanceWorkPlaceName // ignore: cast_nullable_to_non_nullable
              as String,
      useAttendanceStore: null == useAttendanceStore
          ? _value.useAttendanceStore
          : useAttendanceStore // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedStore: freezed == selectedStore
          ? _value.selectedStore
          : selectedStore // ignore: cast_nullable_to_non_nullable
              as StoreModel?,
      approvers: null == approvers
          ? _value._approvers
          : approvers // ignore: cast_nullable_to_non_nullable
              as List<Approver>,
      isLoadingApprovers: null == isLoadingApprovers
          ? _value.isLoadingApprovers
          : isLoadingApprovers // ignore: cast_nullable_to_non_nullable
              as bool,
      approversError: freezed == approversError
          ? _value.approversError
          : approversError // ignore: cast_nullable_to_non_nullable
              as String?,
      approversErrorTitle: freezed == approversErrorTitle
          ? _value.approversErrorTitle
          : approversErrorTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedSpv: freezed == selectedSpv
          ? _value.selectedSpv
          : selectedSpv // ignore: cast_nullable_to_non_nullable
              as Approver?,
      selectedManager: freezed == selectedManager
          ? _value.selectedManager
          : selectedManager // ignore: cast_nullable_to_non_nullable
              as Approver?,
      isSubmitting: null == isSubmitting
          ? _value.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      submitError: freezed == submitError
          ? _value.submitError
          : submitError // ignore: cast_nullable_to_non_nullable
              as String?,
      retryOrderId: freezed == retryOrderId
          ? _value.retryOrderId
          : retryOrderId // ignore: cast_nullable_to_non_nullable
              as int?,
      retryNoSp: null == retryNoSp
          ? _value.retryNoSp
          : retryNoSp // ignore: cast_nullable_to_non_nullable
              as String,
      retryDetails: null == retryDetails
          ? _value._retryDetails
          : retryDetails // ignore: cast_nullable_to_non_nullable
              as List<PendingDetail>,
      submitSuccess: null == submitSuccess
          ? _value.submitSuccess
          : submitSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      successNoSp: freezed == successNoSp
          ? _value.successNoSp
          : successNoSp // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$CheckoutStateImpl
    with DiagnosticableTreeMixin
    implements _CheckoutState {
  const _$CheckoutStateImpl(
      {this.isLoadingWorkPlace = true,
      this.attendanceWorkPlaceId,
      this.attendanceWorkPlaceName = '',
      this.useAttendanceStore = true,
      this.selectedStore,
      final List<Approver> approvers = const [],
      this.isLoadingApprovers = true,
      this.approversError,
      this.approversErrorTitle,
      this.selectedSpv,
      this.selectedManager,
      this.isSubmitting = false,
      this.submitError,
      this.retryOrderId,
      this.retryNoSp = '',
      final List<PendingDetail> retryDetails = const [],
      this.submitSuccess = false,
      this.successNoSp})
      : _approvers = approvers,
        _retryDetails = retryDetails;

// Workplace / Store
  @override
  @JsonKey()
  final bool isLoadingWorkPlace;
  @override
  final int? attendanceWorkPlaceId;
  @override
  @JsonKey()
  final String attendanceWorkPlaceName;
  @override
  @JsonKey()
  final bool useAttendanceStore;
  @override
  final StoreModel? selectedStore;
// Approvers
  final List<Approver> _approvers;
// Approvers
  @override
  @JsonKey()
  List<Approver> get approvers {
    if (_approvers is EqualUnmodifiableListView) return _approvers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_approvers);
  }

  @override
  @JsonKey()
  final bool isLoadingApprovers;
  @override
  final String? approversError;

  /// Judul kartu error (bukan lagi satu pesan generik untuk semua kasus).
  @override
  final String? approversErrorTitle;
  @override
  final Approver? selectedSpv;
  @override
  final Approver? selectedManager;
// Submission
  @override
  @JsonKey()
  final bool isSubmitting;
  @override
  final String? submitError;
// Retry
  @override
  final int? retryOrderId;
  @override
  @JsonKey()
  final String retryNoSp;
  final List<PendingDetail> _retryDetails;
  @override
  @JsonKey()
  List<PendingDetail> get retryDetails {
    if (_retryDetails is EqualUnmodifiableListView) return _retryDetails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_retryDetails);
  }

// Result
  @override
  @JsonKey()
  final bool submitSuccess;
  @override
  final String? successNoSp;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CheckoutState(isLoadingWorkPlace: $isLoadingWorkPlace, attendanceWorkPlaceId: $attendanceWorkPlaceId, attendanceWorkPlaceName: $attendanceWorkPlaceName, useAttendanceStore: $useAttendanceStore, selectedStore: $selectedStore, approvers: $approvers, isLoadingApprovers: $isLoadingApprovers, approversError: $approversError, approversErrorTitle: $approversErrorTitle, selectedSpv: $selectedSpv, selectedManager: $selectedManager, isSubmitting: $isSubmitting, submitError: $submitError, retryOrderId: $retryOrderId, retryNoSp: $retryNoSp, retryDetails: $retryDetails, submitSuccess: $submitSuccess, successNoSp: $successNoSp)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckoutState'))
      ..add(DiagnosticsProperty('isLoadingWorkPlace', isLoadingWorkPlace))
      ..add(DiagnosticsProperty('attendanceWorkPlaceId', attendanceWorkPlaceId))
      ..add(DiagnosticsProperty(
          'attendanceWorkPlaceName', attendanceWorkPlaceName))
      ..add(DiagnosticsProperty('useAttendanceStore', useAttendanceStore))
      ..add(DiagnosticsProperty('selectedStore', selectedStore))
      ..add(DiagnosticsProperty('approvers', approvers))
      ..add(DiagnosticsProperty('isLoadingApprovers', isLoadingApprovers))
      ..add(DiagnosticsProperty('approversError', approversError))
      ..add(DiagnosticsProperty('approversErrorTitle', approversErrorTitle))
      ..add(DiagnosticsProperty('selectedSpv', selectedSpv))
      ..add(DiagnosticsProperty('selectedManager', selectedManager))
      ..add(DiagnosticsProperty('isSubmitting', isSubmitting))
      ..add(DiagnosticsProperty('submitError', submitError))
      ..add(DiagnosticsProperty('retryOrderId', retryOrderId))
      ..add(DiagnosticsProperty('retryNoSp', retryNoSp))
      ..add(DiagnosticsProperty('retryDetails', retryDetails))
      ..add(DiagnosticsProperty('submitSuccess', submitSuccess))
      ..add(DiagnosticsProperty('successNoSp', successNoSp));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckoutStateImpl &&
            (identical(other.isLoadingWorkPlace, isLoadingWorkPlace) ||
                other.isLoadingWorkPlace == isLoadingWorkPlace) &&
            (identical(other.attendanceWorkPlaceId, attendanceWorkPlaceId) ||
                other.attendanceWorkPlaceId == attendanceWorkPlaceId) &&
            (identical(
                    other.attendanceWorkPlaceName, attendanceWorkPlaceName) ||
                other.attendanceWorkPlaceName == attendanceWorkPlaceName) &&
            (identical(other.useAttendanceStore, useAttendanceStore) ||
                other.useAttendanceStore == useAttendanceStore) &&
            (identical(other.selectedStore, selectedStore) ||
                other.selectedStore == selectedStore) &&
            const DeepCollectionEquality()
                .equals(other._approvers, _approvers) &&
            (identical(other.isLoadingApprovers, isLoadingApprovers) ||
                other.isLoadingApprovers == isLoadingApprovers) &&
            (identical(other.approversError, approversError) ||
                other.approversError == approversError) &&
            (identical(other.approversErrorTitle, approversErrorTitle) ||
                other.approversErrorTitle == approversErrorTitle) &&
            (identical(other.selectedSpv, selectedSpv) ||
                other.selectedSpv == selectedSpv) &&
            (identical(other.selectedManager, selectedManager) ||
                other.selectedManager == selectedManager) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.submitError, submitError) ||
                other.submitError == submitError) &&
            (identical(other.retryOrderId, retryOrderId) ||
                other.retryOrderId == retryOrderId) &&
            (identical(other.retryNoSp, retryNoSp) ||
                other.retryNoSp == retryNoSp) &&
            const DeepCollectionEquality()
                .equals(other._retryDetails, _retryDetails) &&
            (identical(other.submitSuccess, submitSuccess) ||
                other.submitSuccess == submitSuccess) &&
            (identical(other.successNoSp, successNoSp) ||
                other.successNoSp == successNoSp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoadingWorkPlace,
      attendanceWorkPlaceId,
      attendanceWorkPlaceName,
      useAttendanceStore,
      selectedStore,
      const DeepCollectionEquality().hash(_approvers),
      isLoadingApprovers,
      approversError,
      approversErrorTitle,
      selectedSpv,
      selectedManager,
      isSubmitting,
      submitError,
      retryOrderId,
      retryNoSp,
      const DeepCollectionEquality().hash(_retryDetails),
      submitSuccess,
      successNoSp);

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckoutStateImplCopyWith<_$CheckoutStateImpl> get copyWith =>
      __$$CheckoutStateImplCopyWithImpl<_$CheckoutStateImpl>(this, _$identity);
}

abstract class _CheckoutState implements CheckoutState {
  const factory _CheckoutState(
      {final bool isLoadingWorkPlace,
      final int? attendanceWorkPlaceId,
      final String attendanceWorkPlaceName,
      final bool useAttendanceStore,
      final StoreModel? selectedStore,
      final List<Approver> approvers,
      final bool isLoadingApprovers,
      final String? approversError,
      final String? approversErrorTitle,
      final Approver? selectedSpv,
      final Approver? selectedManager,
      final bool isSubmitting,
      final String? submitError,
      final int? retryOrderId,
      final String retryNoSp,
      final List<PendingDetail> retryDetails,
      final bool submitSuccess,
      final String? successNoSp}) = _$CheckoutStateImpl;

// Workplace / Store
  @override
  bool get isLoadingWorkPlace;
  @override
  int? get attendanceWorkPlaceId;
  @override
  String get attendanceWorkPlaceName;
  @override
  bool get useAttendanceStore;
  @override
  StoreModel? get selectedStore; // Approvers
  @override
  List<Approver> get approvers;
  @override
  bool get isLoadingApprovers;
  @override
  String? get approversError;

  /// Judul kartu error (bukan lagi satu pesan generik untuk semua kasus).
  @override
  String? get approversErrorTitle;
  @override
  Approver? get selectedSpv;
  @override
  Approver? get selectedManager; // Submission
  @override
  bool get isSubmitting;
  @override
  String? get submitError; // Retry
  @override
  int? get retryOrderId;
  @override
  String get retryNoSp;
  @override
  List<PendingDetail> get retryDetails; // Result
  @override
  bool get submitSuccess;
  @override
  String? get successNoSp;

  /// Create a copy of CheckoutState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckoutStateImplCopyWith<_$CheckoutStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
