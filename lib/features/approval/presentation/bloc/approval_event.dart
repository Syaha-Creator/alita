import 'package:equatable/equatable.dart';
import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';

abstract class ApprovalEvent extends Equatable {
  const ApprovalEvent();

  @override
  List<Object?> get props => [];
}

class CreateApproval extends ApprovalEvent {
  final OrderLetterModel orderLetter;
  final List<OrderLetterDetailModel> details;
  final List<double> discounts;

  const CreateApproval({
    required this.orderLetter,
    required this.details,
    required this.discounts,
  });

  @override
  List<Object?> get props => [orderLetter, details, discounts];
}

class GetApprovals extends ApprovalEvent {
  final String? creator;

  const GetApprovals({this.creator});

  @override
  List<Object?> get props => [creator];
}

class ClearApprovalState extends ApprovalEvent {}
