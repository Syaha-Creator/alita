import 'package:equatable/equatable.dart';
import '../../../../product/domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddToCart extends CartEvent {
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final double editPopupDiscount;
  final int? installmentMonths;
  final double? installmentPerMonth;

  const AddToCart({
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    required this.editPopupDiscount,
    this.installmentMonths,
    this.installmentPerMonth,
  });

  @override
  List<Object?> get props => [
        product,
        quantity,
        netPrice,
        discountPercentages,
        editPopupDiscount,
        installmentMonths,
        installmentPerMonth,
      ];
}

class RemoveFromCart extends CartEvent {
  final int productId;
  final double netPrice;

  const RemoveFromCart({
    required this.productId,
    required this.netPrice,
  });

  @override
  List<Object?> get props => [productId, netPrice];
}

class UpdateCartQuantity extends CartEvent {
  final int productId;
  final double netPrice;
  final int quantity;

  const UpdateCartQuantity({
    required this.productId,
    required this.netPrice,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, netPrice, quantity];
}

class ClearCart extends CartEvent {}

class Checkout extends CartEvent {
  final double totalPrice;
  final String promoCode;
  final String paymentMethod;
  final String shippingAddress;

  const Checkout({
    required this.totalPrice,
    required this.promoCode,
    required this.paymentMethod,
    required this.shippingAddress,
  });

  @override
  List<Object?> get props =>
      [totalPrice, promoCode, paymentMethod, shippingAddress];
}
