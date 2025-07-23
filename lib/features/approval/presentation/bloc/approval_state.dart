import 'package:equatable/equatable.dart';
import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';

abstract class ApprovalState extends Equatable {
  const ApprovalState();

  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class ApprovalSuccess extends ApprovalState {
  final String message;
  final Map<String, dynamic>? result;

  const ApprovalSuccess({
    required this.message,
    this.result,
  });

  @override
  List<Object?> get props => [message, result];
}

class ApprovalError extends ApprovalState {
  final String message;

  const ApprovalError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ApprovalsLoaded extends ApprovalState {
  final List<OrderLetterModel> orderLetters;
  final List<OrderLetterDetailModel> orderLetterDetails;

  const ApprovalsLoaded({
    required this.orderLetters,
    required this.orderLetterDetails,
  });

  @override
  List<Object?> get props => [orderLetters, orderLetterDetails];
} 