import 'package:equatable/equatable.dart';

abstract class ApprovalEvent extends Equatable {
  const ApprovalEvent();

  @override
  List<Object?> get props => [];
}

class LoadApprovals extends ApprovalEvent {
  final String? creator;
  final bool forceRefresh;
  final String? dateFrom;
  final String? dateTo;

  const LoadApprovals({
    this.creator,
    this.forceRefresh = false,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [creator, forceRefresh, dateFrom, dateTo];
}

class LoadPendingApprovals extends ApprovalEvent {}

class LoadApprovedApprovals extends ApprovalEvent {}

class LoadRejectedApprovals extends ApprovalEvent {}

class LoadApprovalById extends ApprovalEvent {
  final int orderLetterId;

  const LoadApprovalById(this.orderLetterId);

  @override
  List<Object> get props => [orderLetterId];
}

class CreateApproval extends ApprovalEvent {
  final int orderLetterId;
  final String action; // approve/reject
  final String approverName;
  final String approverEmail;
  final String? comment;

  const CreateApproval({
    required this.orderLetterId,
    required this.action,
    required this.approverName,
    required this.approverEmail,
    this.comment,
  });

  @override
  List<Object?> get props =>
      [orderLetterId, action, approverName, approverEmail, comment];
}

class RefreshApprovals extends ApprovalEvent {
  final String? creator;
  final String? dateFrom;
  final String? dateTo;

  const RefreshApprovals({this.creator, this.dateFrom, this.dateTo});

  @override
  List<Object?> get props => [creator, dateFrom, dateTo];
}

class FilterApprovals extends ApprovalEvent {
  final String status; // All, Pending, Approved, Rejected

  const FilterApprovals(this.status);

  @override
  List<Object> get props => [status];
}

class UpdateSingleApproval extends ApprovalEvent {
  final int orderLetterId;

  const UpdateSingleApproval(this.orderLetterId);

  @override
  List<Object> get props => [orderLetterId];
}

class LoadNewApprovalsIncremental extends ApprovalEvent {
  const LoadNewApprovalsIncremental();
}

class UpdateApprovalStatusesOnly extends ApprovalEvent {
  const UpdateApprovalStatusesOnly();
}
