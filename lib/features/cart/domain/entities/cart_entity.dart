import '../../../product/domain/entities/product_entity.dart';

class CartEntity {
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final double editPopupDiscount;
  final int? installmentMonths;
  final double? installmentPerMonth;
  final bool isSelected;

  CartEntity copyWith({
    ProductEntity? product,
    int? quantity,
    double? netPrice,
    List<double>? discountPercentages,
    double? editPopupDiscount,
    int? installmentMonths,
    double? installmentPerMonth,
    bool? isSelected,
  }) {
    return CartEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      netPrice: netPrice ?? this.netPrice,
      discountPercentages: discountPercentages ?? this.discountPercentages,
      editPopupDiscount: editPopupDiscount ?? this.editPopupDiscount,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      installmentPerMonth: installmentPerMonth ?? this.installmentPerMonth,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  const CartEntity({
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    required this.editPopupDiscount,
    this.installmentMonths,
    this.installmentPerMonth,
    this.isSelected = true,
  });

  List<Object?> get props => [
        product,
        quantity,
        netPrice,
        discountPercentages,
        editPopupDiscount,
        installmentMonths,
        installmentPerMonth,
        isSelected,
      ];
}
