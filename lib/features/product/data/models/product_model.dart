import '../../domain/entities/product_entity.dart';

class ProductModel {
  final int id;
  final String area;
  final String channel;
  final String brand;
  final String kasur;
  final bool set;
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
  final String? bonus1;
  final int? qtyBonus1;
  final String? bonus2;
  final int? qtyBonus2;
  final String? bonus3;
  final int? qtyBonus3;
  final String? bonus4;
  final int? qtyBonus4;
  final String? bonus5;
  final int? qtyBonus5;
  final double disc1;
  final double disc2;
  final double disc3;
  final double disc4;
  final double disc5;
  final double plKasur;
  final double plDivan;
  final double plHeadboard;
  final double plSorong;
  final double eupSorong;
  final double bottomPriceAnalyst;
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

  ProductModel({
    required this.id,
    required this.area,
    required this.channel,
    required this.brand,
    required this.kasur,
    required this.set,
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
    this.bonus1,
    this.qtyBonus1,
    this.bonus2,
    this.qtyBonus2,
    this.bonus3,
    this.qtyBonus3,
    this.bonus4,
    this.qtyBonus4,
    this.bonus5,
    this.qtyBonus5,
    required this.disc1,
    required this.disc2,
    required this.disc3,
    required this.disc4,
    required this.disc5,
    required this.plKasur,
    required this.plDivan,
    required this.plHeadboard,
    required this.plSorong,
    required this.eupSorong,
    required this.bottomPriceAnalyst,
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json["id"] ?? 0,
      area: json["area"] ?? "",
      channel: json["channel"] ?? "",
      brand: json["brand"] ?? "",
      kasur: json["kasur"] ?? "",
      set: json["set"] ?? false,
      divan: json["divan"] ?? "",
      headboard: json["headboard"] ?? "",
      sorong: json["sorong"] ?? "",
      ukuran: json["ukuran"] ?? "",
      pricelist: (json["pricelist"] ?? 0).toDouble(),
      program: json["program"] ?? "",
      eupKasur: (json["eup_kasur"] ?? 0).toDouble(),
      eupDivan: (json["eup_divan"] ?? 0).toDouble(),
      eupHeadboard: (json["eup_headboard"] ?? 0).toDouble(),
      endUserPrice: (json["end_user_price"] ?? 0).toDouble(),
      bonus1: json["bonus_1"],
      qtyBonus1: json["qty_bonus1"],
      bonus2: json["bonus_2"],
      qtyBonus2: json["qty_bonus2"],
      bonus3: json["bonus_3"],
      qtyBonus3: json["qty_bonus3"],
      bonus4: json["bonus_4"],
      qtyBonus4: json["qty_bonus4"],
      bonus5: json["bonus_5"],
      qtyBonus5: json["qty_bonus5"],
      disc1: (json["disc1"] ?? 0).toDouble(),
      disc2: (json["disc2"] ?? 0).toDouble(),
      disc3: (json["disc3"] ?? 0).toDouble(),
      disc4: (json["disc4"] ?? 0).toDouble(),
      disc5: (json["disc5"] ?? 0).toDouble(),
      plKasur: (json["pl_kasur"] ?? 0).toDouble(),
      plDivan: (json["pl_divan"] ?? 0).toDouble(),
      plHeadboard: (json["pl_headboard"] ?? 0).toDouble(),
      plSorong: (json["pl_sorong"] ?? 0).toDouble(),
      eupSorong: (json["eup_sorong"] ?? 0).toDouble(),
      bottomPriceAnalyst: (json["bottom_price_analyst"] ?? 0).toDouble(),
      itemNumber: json["item_number"],
      itemNumberKasur: json["item_number_kasur"],
      itemNumberDivan: json["item_number_divan"],
      itemNumberHeadboard: json["item_number_headboard"],
      itemNumberSorong: json["item_number_sorong"],
      itemNumberAccessories: json["item_number_accessories"],
      itemNumberBonus1: json["item_number_bonus1"],
      itemNumberBonus2: json["item_number_bonus2"],
      itemNumberBonus3: json["item_number_bonus3"],
      itemNumberBonus4: json["item_number_bonus4"],
      itemNumberBonus5: json["item_number_bonus5"],
    );
  }

  ProductEntity toEntity() {
    final List<BonusItem> bonusList = [];
    if ((bonus1 ?? '').isNotEmpty && (qtyBonus1 ?? 0) > 0) {
      bonusList.add(BonusItem(name: bonus1!, quantity: qtyBonus1 ?? 0));
    }
    if ((bonus2 ?? '').isNotEmpty && (qtyBonus2 ?? 0) > 0) {
      bonusList.add(BonusItem(name: bonus2!, quantity: qtyBonus2 ?? 0));
    }
    if ((bonus3 ?? '').isNotEmpty && (qtyBonus3 ?? 0) > 0) {
      bonusList.add(BonusItem(name: bonus3!, quantity: qtyBonus3 ?? 0));
    }
    if ((bonus4 ?? '').isNotEmpty && (qtyBonus4 ?? 0) > 0) {
      bonusList.add(BonusItem(name: bonus4!, quantity: qtyBonus4 ?? 0));
    }
    if ((bonus5 ?? '').isNotEmpty && (qtyBonus5 ?? 0) > 0) {
      bonusList.add(BonusItem(name: bonus5!, quantity: qtyBonus5 ?? 0));
    }
    return ProductEntity(
      id: id,
      area: area,
      channel: channel,
      brand: brand,
      kasur: kasur,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      ukuran: ukuran,
      pricelist: pricelist,
      program: program,
      eupKasur: eupKasur,
      eupDivan: eupDivan,
      eupHeadboard: eupHeadboard,
      endUserPrice: endUserPrice,
      bonus: bonusList,
      discounts: [], // mapping sesuai kebutuhan
      isSet: set,
      plKasur: plKasur,
      plDivan: plDivan,
      plHeadboard: plHeadboard,
      plSorong: plSorong,
      eupSorong: eupSorong,
      bottomPriceAnalyst: bottomPriceAnalyst,
      disc1: disc1,
      disc2: disc2,
      disc3: disc3,
      disc4: disc4,
      disc5: disc5,
      itemNumber: itemNumber,
      itemNumberKasur: itemNumberKasur,
      itemNumberDivan: itemNumberDivan,
      itemNumberHeadboard: itemNumberHeadboard,
      itemNumberSorong: itemNumberSorong,
      itemNumberAccessories: itemNumberAccessories,
      itemNumberBonus1: itemNumberBonus1,
      itemNumberBonus2: itemNumberBonus2,
      itemNumberBonus3: itemNumberBonus3,
      itemNumberBonus4: itemNumberBonus4,
      itemNumberBonus5: itemNumberBonus5,
    );
  }
}
