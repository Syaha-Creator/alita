import '../../../product/domain/entities/product_entity.dart';

class CartEntity {
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final double editPopupDiscount;
  final int? installmentMonths;
  final double? installmentPerMonth;

  const CartEntity({
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    required this.editPopupDiscount,
    this.installmentMonths,
    this.installmentPerMonth,
  });

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
