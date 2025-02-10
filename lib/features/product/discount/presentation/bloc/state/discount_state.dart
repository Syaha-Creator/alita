part of '../discount_bloc.dart';

sealed class DiscountState extends Equatable {
  const DiscountState();

  @override
  List<Object> get props => [];
}

final class DiscountInitial extends DiscountState {}
