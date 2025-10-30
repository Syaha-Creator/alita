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

class UpdateBonusTakeAway extends CartEvent {
  final int productId;
  final double netPrice;
  final Map<String, bool> bonusTakeAway;

  const UpdateBonusTakeAway({
    required this.productId,
    required this.netPrice,
    required this.bonusTakeAway,
  });

  @override
  List<Object?> get props => [productId, netPrice, bonusTakeAway];
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

/// Update user-selected item number/fabric choice for a component
class UpdateCartSelectedItemNumber extends CartEvent {
  final int productId;
  final double netPrice;
  final String itemType; // 'kasur' | 'divan' | 'headboard' | 'sorong'
  final String itemNumber;
  final String? jenisKain;
  final String? warnaKain;
  final int? unitIndex; // optional: select for specific unit (0..quantity-1)

  const UpdateCartSelectedItemNumber({
    required this.productId,
    required this.netPrice,
    required this.itemType,
    required this.itemNumber,
    this.jenisKain,
    this.warnaKain,
    this.unitIndex,
  });

  @override
  List<Object?> get props => [
        productId,
        netPrice,
        itemType,
        itemNumber,
        jenisKain,
        warnaKain,
        unitIndex
      ];
}

class UpdateCartPrice extends CartEvent {
  final int productId;
  final double oldNetPrice;
  final double newNetPrice;

  const UpdateCartPrice({
    required this.productId,
    required this.oldNetPrice,
    required this.newNetPrice,
  });

  @override
  List<Object?> get props => [productId, oldNetPrice, newNetPrice];
}

class UpdateCartDiscounts extends CartEvent {
  final int productId;
  final double oldNetPrice;
  final List<double> discountPercentages;
  final double newNetPrice;

  const UpdateCartDiscounts({
    required this.productId,
    required this.oldNetPrice,
    required this.discountPercentages,
    required this.newNetPrice,
  });

  @override
  List<Object?> get props =>
      [productId, oldNetPrice, discountPercentages, newNetPrice];
}
