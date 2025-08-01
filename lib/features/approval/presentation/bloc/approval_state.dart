import 'package:equatable/equatable.dart';
import '../../domain/entities/approval_entity.dart';

abstract class ApprovalState extends Equatable {
  const ApprovalState();

  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class ApprovalLoaded extends ApprovalState {
  final List<ApprovalEntity> approvals;
  final String? filterStatus;

  const ApprovalLoaded({
    required this.approvals,
    this.filterStatus,
  });

  @override
  List<Object?> get props => [approvals, filterStatus];

  ApprovalLoaded copyWith({
    List<ApprovalEntity>? approvals,
    String? filterStatus,
  }) {
    return ApprovalLoaded(
      approvals: approvals ?? this.approvals,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

class ApprovalDetailLoaded extends ApprovalState {
  final ApprovalEntity approval;

  const ApprovalDetailLoaded(this.approval);

  @override
  List<Object> get props => [approval];
}

class ApprovalError extends ApprovalState {
  final String message;

  const ApprovalError(this.message);

  @override
  List<Object> get props => [message];
}

class ApprovalActionLoading extends ApprovalState {
  final int orderLetterId;

  const ApprovalActionLoading(this.orderLetterId);

  @override
  List<Object> get props => [orderLetterId];
}

class ApprovalActionSuccess extends ApprovalState {
  final String message;
  final int orderLetterId;

  const ApprovalActionSuccess({
    required this.message,
    required this.orderLetterId,
  });

  @override
  List<Object> get props => [message, orderLetterId];
}

class ApprovalActionError extends ApprovalState {
  final String message;
  final int orderLetterId;

  const ApprovalActionError({
    required this.message,
    required this.orderLetterId,
  });

  @override
  List<Object> get props => [message, orderLetterId];
}

class ApprovalEmpty extends ApprovalState {
  final String message;

  const ApprovalEmpty(this.message);

  @override
  List<Object> get props => [message];
}
