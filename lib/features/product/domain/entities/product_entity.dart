import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String area;
  final String channel;
  final String brand;
  final String kasur;
  final String divan;
  final String headboard;
  final String sorong;
  final String ukuran;
  final double pricelist;
  final String program;
  final double eupKasur;
  final double eupDivan;
  final double eupHeadboard;
  final double endUserPrice;
  final List<BonusItem> bonus;
  final List<double> discounts;
  final bool isSet;
  final double plKasur;
  final double plDivan;
  final double plHeadboard;
  final double plSorong;
  final double eupSorong;
  final double bottomPriceAnalyst;
  final double disc1;
  final double disc2;
  final double disc3;
  final double disc4;
  final double disc5;
  final String? itemNumber;
  final String? itemNumberKasur;
  final String? itemNumberDivan;
  final String? itemNumberHeadboard;
  final String? itemNumberSorong;
  final String? itemNumberAccessories;
  final String? itemNumberBonus1;
  final String? itemNumberBonus2;
  final String? itemNumberBonus3;
  final String? itemNumberBonus4;
  final String? itemNumberBonus5;

  const ProductEntity({
    required this.id,
    required this.area,
    required this.channel,
    required this.brand,
    required this.kasur,
    required this.divan,
    required this.headboard,
    required this.sorong,
    required this.ukuran,
    required this.pricelist,
    required this.program,
    required this.eupKasur,
    required this.eupDivan,
    required this.eupHeadboard,
    required this.endUserPrice,
    required this.bonus,
    required this.discounts,
    required this.isSet,
    required this.plKasur,
    required this.plDivan,
    required this.plHeadboard,
    required this.plSorong,
    required this.eupSorong,
    required this.bottomPriceAnalyst,
    required this.disc1,
    required this.disc2,
    required this.disc3,
    required this.disc4,
    required this.disc5,
    this.itemNumber,
    this.itemNumberKasur,
    this.itemNumberDivan,
    this.itemNumberHeadboard,
    this.itemNumberSorong,
    this.itemNumberAccessories,
    this.itemNumberBonus1,
    this.itemNumberBonus2,
    this.itemNumberBonus3,
    this.itemNumberBonus4,
    this.itemNumberBonus5,
  });

  @override
  List<Object?> get props => [
        id,
        area,
        channel,
        brand,
        kasur,
        divan,
        headboard,
        sorong,
        ukuran,
        pricelist,
        program,
        eupKasur,
        eupDivan,
        eupHeadboard,
        endUserPrice,
        bonus,
        discounts,
        isSet,
        plKasur,
        plDivan,
        plHeadboard,
        plSorong,
        eupSorong,
        bottomPriceAnalyst,
        disc1,
        disc2,
        disc3,
        disc4,
        disc5,
        itemNumber,
        itemNumberKasur,
        itemNumberDivan,
        itemNumberHeadboard,
        itemNumberSorong,
        itemNumberAccessories,
        itemNumberBonus1,
        itemNumberBonus2,
        itemNumberBonus3,
        itemNumberBonus4,
        itemNumberBonus5,
      ];
}

class BonusItem extends Equatable {
  final String name;
  final int quantity;
  final int originalQuantity;
  final bool? takeAway;
  const BonusItem(
      {required this.name,
      required this.quantity,
      this.originalQuantity = 0,
      this.takeAway});
  @override
  List<Object?> get props => [name, quantity, originalQuantity, takeAway];

  /// Get maximum allowed quantity (2x original quantity)
  int get maxQuantity => originalQuantity > 0 ? originalQuantity * 2 : quantity;
}
