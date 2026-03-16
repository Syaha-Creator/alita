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
// Approvers
  List<Approver> get approvers => throw _privateConstructorUsedError;
  bool get isLoadingApprovers => throw _privateConstructorUsedError;
  String? get approversError => throw _privateConstructorUsedError;
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
      {List<Approver> approvers,
      bool isLoadingApprovers,
      String? approversError,
      Approver? selectedSpv,
      Approver? selectedManager,
      bool isSubmitting,
      String? submitError,
      int? retryOrderId,
      String retryNoSp,
      List<PendingDetail> retryDetails,
      bool submitSuccess,
      String? successNoSp});
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
    Object? approvers = null,
    Object? isLoadingApprovers = null,
    Object? approversError = freezed,
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
      {List<Approver> approvers,
      bool isLoadingApprovers,
      String? approversError,
      Approver? selectedSpv,
      Approver? selectedManager,
      bool isSubmitting,
      String? submitError,
      int? retryOrderId,
      String retryNoSp,
      List<PendingDetail> retryDetails,
      bool submitSuccess,
      String? successNoSp});
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
    Object? approvers = null,
    Object? isLoadingApprovers = null,
    Object? approversError = freezed,
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
      {final List<Approver> approvers = const [],
      this.isLoadingApprovers = true,
      this.approversError,
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
    return 'CheckoutState(approvers: $approvers, isLoadingApprovers: $isLoadingApprovers, approversError: $approversError, selectedSpv: $selectedSpv, selectedManager: $selectedManager, isSubmitting: $isSubmitting, submitError: $submitError, retryOrderId: $retryOrderId, retryNoSp: $retryNoSp, retryDetails: $retryDetails, submitSuccess: $submitSuccess, successNoSp: $successNoSp)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CheckoutState'))
      ..add(DiagnosticsProperty('approvers', approvers))
      ..add(DiagnosticsProperty('isLoadingApprovers', isLoadingApprovers))
      ..add(DiagnosticsProperty('approversError', approversError))
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
            const DeepCollectionEquality()
                .equals(other._approvers, _approvers) &&
            (identical(other.isLoadingApprovers, isLoadingApprovers) ||
                other.isLoadingApprovers == isLoadingApprovers) &&
            (identical(other.approversError, approversError) ||
                other.approversError == approversError) &&
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
      const DeepCollectionEquality().hash(_approvers),
      isLoadingApprovers,
      approversError,
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
      {final List<Approver> approvers,
      final bool isLoadingApprovers,
      final String? approversError,
      final Approver? selectedSpv,
      final Approver? selectedManager,
      final bool isSubmitting,
      final String? submitError,
      final int? retryOrderId,
      final String retryNoSp,
      final List<PendingDetail> retryDetails,
      final bool submitSuccess,
      final String? successNoSp}) = _$CheckoutStateImpl;

// Approvers
  @override
  List<Approver> get approvers;
  @override
  bool get isLoadingApprovers;
  @override
  String? get approversError;
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
