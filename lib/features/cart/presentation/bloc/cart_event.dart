import 'package:equatable/equatable.dart';
import '../../../product/domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final int? installmentMonths;
  final double? installmentPerMonth;

  const AddToCart({
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    this.installmentMonths,
    this.installmentPerMonth,
  });

  @override
  List<Object?> get props => [
        product,
        quantity,
        netPrice,
        discountPercentages,
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

class ToggleCartItemSelection extends CartEvent {
  final int productId;
  final double netPrice;

  const ToggleCartItemSelection({
    required this.productId,
    required this.netPrice,
  });

  @override
  List<Object?> get props => [productId, netPrice];
}

class ClearCart extends CartEvent {}

class MarkItemAsCheckedOut extends CartEvent {
  final int productId;
  final double netPrice;

  const MarkItemAsCheckedOut({
    required this.productId,
    required this.netPrice,
  });

  @override
  List<Object?> get props => [productId, netPrice];
}

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

class ReloadCartForUser extends CartEvent {}

class UpdateCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final int bonusIndex;
  final String bonusName;
  final int bonusQuantity;

  const UpdateCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusIndex,
    required this.bonusName,
    required this.bonusQuantity,
  });

  @override
  List<Object?> get props =>
      [productId, netPrice, bonusIndex, bonusName, bonusQuantity];
}

class AddCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final String bonusName;
  final int bonusQuantity;

  const AddCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusName,
    required this.bonusQuantity,
  });

  @override
  List<Object?> get props => [productId, netPrice, bonusName, bonusQuantity];
}

class RemoveCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final int bonusIndex;

  const RemoveCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusIndex,
  });

  @override
  List<Object?> get props => [productId, netPrice, bonusIndex];
}

class UpdateCartProductDetail extends CartEvent {
  final int productId;
  final double netPrice;
  final String detailType;
  final String detailValue;

  const UpdateCartProductDetail({
    required this.productId,
    required this.netPrice,
    required this.detailType,
    required this.detailValue,
  });

  @override
  List<Object?> get props => [productId, netPrice, detailType, detailValue];
}
