import '../../../product/domain/entities/product_entity.dart';

class CartEntity {
  final String cartLineId; // stable identifier per cart line
  final ProductEntity product;
  final int quantity;
  final double netPrice;
  final List<double> discountPercentages;
  final int? installmentMonths;
  final double? installmentPerMonth;
  final bool isSelected;
  final Map<String, bool>? bonusTakeAway; // Map bonus name to take away status
  // Optional user-selected fabric/item number per component
  // Keys: 'kasur', 'divan', 'headboard', 'sorong'
  final Map<String, Map<String, String>>? selectedItemNumbers;
  final Map<String, List<Map<String, String>>>? selectedItemNumbersPerUnit;

  CartEntity copyWith({
    String? cartLineId,
    ProductEntity? product,
    int? quantity,
    double? netPrice,
    List<double>? discountPercentages,
    int? installmentMonths,
    double? installmentPerMonth,
    bool? isSelected,
    Map<String, bool>? bonusTakeAway,
    Map<String, Map<String, String>>? selectedItemNumbers,
    Map<String, List<Map<String, String>>>? selectedItemNumbersPerUnit,
  }) {
    return CartEntity(
      cartLineId: cartLineId ?? this.cartLineId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      netPrice: netPrice ?? this.netPrice,
      discountPercentages: discountPercentages ?? this.discountPercentages,
      installmentMonths: installmentMonths ?? this.installmentMonths,
      installmentPerMonth: installmentPerMonth ?? this.installmentPerMonth,
      isSelected: isSelected ?? this.isSelected,
      bonusTakeAway: bonusTakeAway ?? this.bonusTakeAway,
      selectedItemNumbers: selectedItemNumbers ?? this.selectedItemNumbers,
      selectedItemNumbersPerUnit:
          selectedItemNumbersPerUnit ?? this.selectedItemNumbersPerUnit,
    );
  }

  CartEntity({
    required this.cartLineId,
    required this.product,
    required this.quantity,
    required this.netPrice,
    required this.discountPercentages,
    this.installmentMonths,
    this.installmentPerMonth,
    this.isSelected = true,
    this.bonusTakeAway,
    this.selectedItemNumbers,
    this.selectedItemNumbersPerUnit,
  });

  List<Object?> get props => [
        cartLineId,
        product,
        quantity,
        netPrice,
        discountPercentages,
        installmentMonths,
        installmentPerMonth,
        isSelected,
        bonusTakeAway,
        selectedItemNumbers,
        selectedItemNumbersPerUnit,
      ];

  /// Get bonus items with their max quantities calculated for this cart item
  List<({BonusItem bonus, int maxQuantity})> getBonusWithMax() {
    return product.bonus.map((bonus) {
      return (
        bonus: bonus,
        maxQuantity: bonus.calculateMaxQuantity(quantity),
      );
    }).toList();
  }

  /// Calculate total price for this cart item
  double get totalPrice => netPrice * quantity;

  Map<String, dynamic> toJson() {
    return {
      'cartLineId': cartLineId,
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
      'selectedItemNumbers': selectedItemNumbers,
      'selectedItemNumbersPerUnit': selectedItemNumbersPerUnit,
    };
  }
}
