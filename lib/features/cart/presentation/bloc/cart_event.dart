import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_entity.dart';
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
  final String? cartLineId;

  const RemoveFromCart({
    required this.productId,
    required this.netPrice,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, netPrice, cartLineId];
}

class UpdateCartQuantity extends CartEvent {
  final int productId;
  final double netPrice;
  final int quantity;
  final String? cartLineId;

  const UpdateCartQuantity({
    required this.productId,
    required this.netPrice,
    required this.quantity,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, netPrice, quantity, cartLineId];
}

class ToggleCartItemSelection extends CartEvent {
  final int productId;
  final double netPrice;
  final String? cartLineId;

  const ToggleCartItemSelection({
    required this.productId,
    required this.netPrice,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, netPrice, cartLineId];
}

class ClearCart extends CartEvent {}

class UpdateBonusTakeAway extends CartEvent {
  final int productId;
  final double netPrice;
  final Map<String, bool> bonusTakeAway;
  final String? cartLineId;

  const UpdateBonusTakeAway({
    required this.productId,
    required this.netPrice,
    required this.bonusTakeAway,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, netPrice, bonusTakeAway, cartLineId];
}

class RemoveSelectedItems extends CartEvent {
  final List<CartEntity> itemsToRemove;

  const RemoveSelectedItems({
    required this.itemsToRemove,
  });

  @override
  List<Object?> get props => [itemsToRemove];
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

class ClearDraftsAfterCheckout extends CartEvent {}

class ReloadCartForUser extends CartEvent {}

class UpdateCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final int bonusIndex;
  final String bonusName;
  final int bonusQuantity;
  final String? cartLineId;

  const UpdateCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusIndex,
    required this.bonusName,
    required this.bonusQuantity,
    this.cartLineId,
  });

  @override
  List<Object?> get props =>
      [productId, netPrice, bonusIndex, bonusName, bonusQuantity, cartLineId];
}

class AddCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final String bonusName;
  final int bonusQuantity;
  final String? cartLineId;

  const AddCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusName,
    required this.bonusQuantity,
    this.cartLineId,
  });

  @override
  List<Object?> get props =>
      [productId, netPrice, bonusName, bonusQuantity, cartLineId];
}

class RemoveCartBonus extends CartEvent {
  final int productId;
  final double netPrice;
  final int bonusIndex;
  final String? cartLineId;

  const RemoveCartBonus({
    required this.productId,
    required this.netPrice,
    required this.bonusIndex,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, netPrice, bonusIndex, cartLineId];
}

class UpdateCartProductDetail extends CartEvent {
  final int productId;
  final double netPrice;
  final String detailType;
  final String detailValue;
  final String? cartLineId;

  const UpdateCartProductDetail({
    required this.productId,
    required this.netPrice,
    required this.detailType,
    required this.detailValue,
    this.cartLineId,
  });

  @override
  List<Object?> get props =>
      [productId, netPrice, detailType, detailValue, cartLineId];
}

/// Update user-selected item number/fabric choice for a component
class UpdateCartSelectedItemNumber extends CartEvent {
  final int productId;
  final double netPrice;
  final String itemType; // 'kasur' | 'divan' | 'headboard' | 'sorong'
  final String itemNumber;
  final String? jenisKain;
  final String? warnaKain;
  final int? unitIndex; // optional: select for specific unit (0..quantity-1)
  final String? cartLineId;

  const UpdateCartSelectedItemNumber({
    required this.productId,
    required this.netPrice,
    required this.itemType,
    required this.itemNumber,
    this.jenisKain,
    this.warnaKain,
    this.unitIndex,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [
        productId,
        netPrice,
        itemType,
        itemNumber,
        jenisKain,
        warnaKain,
        unitIndex,
        cartLineId
      ];
}

class UpdateCartPrice extends CartEvent {
  final int productId;
  final double oldNetPrice;
  final double newNetPrice;
  final String? cartLineId;

  const UpdateCartPrice({
    required this.productId,
    required this.oldNetPrice,
    required this.newNetPrice,
    this.cartLineId,
  });

  @override
  List<Object?> get props => [productId, oldNetPrice, newNetPrice, cartLineId];
}

class UpdateCartDiscounts extends CartEvent {
  final int productId;
  final double oldNetPrice;
  final List<double> discountPercentages;
  final double newNetPrice;
  final String? cartLineId;

  const UpdateCartDiscounts({
    required this.productId,
    required this.oldNetPrice,
    required this.discountPercentages,
    required this.newNetPrice,
    this.cartLineId,
  });

  @override
  List<Object?> get props =>
      [productId, oldNetPrice, discountPercentages, newNetPrice, cartLineId];
}
