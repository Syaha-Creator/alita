class ProductEntity {
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

  ProductEntity({
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
  });

  factory ProductEntity.fromJson(Map<String, dynamic> json) {
    return ProductEntity(
      id: json["id"],
      area: json["area"] ?? "",
      channel: json["channel"] ?? "",
      brand: json["brand"] ?? "",
      kasur: json["kasur"] ?? "",
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
      bonus: [
        if (json["bonus_1"] != null)
          BonusItem(
              name: json["bonus_1"] ?? "", quantity: json["qty_bonus1"] ?? 0),
        if (json["bonus_2"] != null)
          BonusItem(
              name: json["bonus_2"] ?? "", quantity: json["qty_bonus2"] ?? 0),
        if (json["bonus_3"] != null)
          BonusItem(
              name: json["bonus_3"] ?? "", quantity: json["qty_bonus3"] ?? 0),
        if (json["bonus_4"] != null)
          BonusItem(
              name: json["bonus_4"] ?? "", quantity: json["qty_bonus4"] ?? 0),
        if (json["bonus_5"] != null)
          BonusItem(
              name: json["bonus_5"] ?? "", quantity: json["qty_bonus5"] ?? 0),
      ],
      discounts: [
        (json["disc1"] ?? 0).toDouble(),
        (json["disc2"] ?? 0).toDouble(),
        (json["disc3"] ?? 0).toDouble(),
        (json["disc4"] ?? 0).toDouble(),
        (json["disc5"] ?? 0).toDouble(),
      ],
      isSet: json["set"] ?? false,
    );
  }
}

class BonusItem {
  final String name;
  final int quantity;

  BonusItem({required this.name, required this.quantity});
}
