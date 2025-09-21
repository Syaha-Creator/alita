import '../../../product/domain/entities/product_entity.dart';

class CartEntity {
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final int? installmentMonths;
  final double? installmentPerMonth;
  final bool isSelected;
  final Map<String, bool>? bonusTakeAway; // Map bonus name to take away status

  CartEntity copyWith({
    ProductEntity? product,
    int? quantity,
    double? netPrice,
    List<double>? discountPercentages,
    int? installmentMonths,
    double? installmentPerMonth,
    bool? isSelected,
    Map<String, bool>? bonusTakeAway,
  }) {
    return CartEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      netPrice: netPrice ?? this.netPrice,
      discountPercentages: discountPercentages ?? this.discountPercentages,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      installmentPerMonth: installmentPerMonth ?? this.installmentPerMonth,
      isSelected: isSelected ?? this.isSelected,
      bonusTakeAway: bonusTakeAway ?? this.bonusTakeAway,
    );
  }

  const CartEntity({
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    this.installmentMonths,
    this.installmentPerMonth,
    this.isSelected = true,
    this.bonusTakeAway,
  });

  List<Object?> get props => [
        product,
        quantity,
        netPrice,
        discountPercentages,
        installmentMonths,
        installmentPerMonth,
        isSelected,
        bonusTakeAway,
      ];

  Map<String, dynamic> toJson() {
    return {
      'product': {
        'id': product.id,
        'area': product.area,
        'channel': product.channel,
        'brand': product.brand,
        'kasur': product.kasur,
        'divan': product.divan,
        'headboard': product.headboard,
        'sorong': product.sorong,
        'ukuran': product.ukuran,
        'pricelist': product.pricelist,
        'program': product.program,
        'eupKasur': product.eupKasur,
        'eupDivan': product.eupDivan,
        'eupHeadboard': product.eupHeadboard,
        'endUserPrice': product.endUserPrice,
        'isSet': product.isSet,
        'bonus': product.bonus
            .map((b) => {'name': b.name, 'quantity': b.quantity})
            .toList(),
        'discounts': product.discounts,
        'plKasur': product.plKasur,
        'plDivan': product.plDivan,
        'plHeadboard': product.plHeadboard,
        'plSorong': product.plSorong,
        'eupSorong': product.eupSorong,
        'bottomPriceAnalyst': product.bottomPriceAnalyst,
        'disc1': product.disc1,
        'disc2': product.disc2,
        'disc3': product.disc3,
        'disc4': product.disc4,
        'disc5': product.disc5,
      },
      'quantity': quantity,
      'netPrice': netPrice,
      'discountPercentages': discountPercentages,
      'installmentMonths': installmentMonths,
      'installmentPerMonth': installmentPerMonth,
      'isSelected': isSelected,
      'bonusTakeAway': bonusTakeAway,
    };
  }
}
