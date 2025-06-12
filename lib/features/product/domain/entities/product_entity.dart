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
      ];
}

class BonusItem extends Equatable {
  final String name;
  final int quantity;
  const BonusItem({required this.name, required this.quantity});
  @override
  List<Object?> get props => [name, quantity];
}
