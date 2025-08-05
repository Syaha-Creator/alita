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
      id: json["id"]?.toInt() ?? 0,
      area: json["area"]?.toString() ?? "",
      channel: json["channel"]?.toString() ?? "",
      brand: json["brand"]?.toString() ?? "",
      kasur: json["kasur"]?.toString() ?? "",
      set: json["set"] == true,
      divan: json["divan"]?.toString() ?? "",
      headboard: json["headboard"]?.toString() ?? "",
      sorong: json["sorong"]?.toString() ?? "",
      ukuran: json["ukuran"]?.toString() ?? "",
      pricelist: _parseDouble(json["pricelist"]),
      program: json["program"]?.toString() ?? "",
      eupKasur: _parseDouble(json["eup_kasur"]),
      eupDivan: _parseDouble(json["eup_divan"]),
      eupHeadboard: _parseDouble(json["eup_headboard"]),
      endUserPrice: _parseDouble(json["end_user_price"]),
      bonus1: json["bonus_1"]?.toString(),
      qtyBonus1: _parseInt(json["qty_bonus1"]),
      bonus2: json["bonus_2"]?.toString(),
      qtyBonus2: _parseInt(json["qty_bonus2"]),
      bonus3: json["bonus_3"]?.toString(),
      qtyBonus3: _parseInt(json["qty_bonus3"]),
      bonus4: json["bonus_4"]?.toString(),
      qtyBonus4: _parseInt(json["qty_bonus4"]),
      bonus5: json["bonus_5"]?.toString(),
      qtyBonus5: _parseInt(json["qty_bonus5"]),
      disc1: _parseDouble(json["disc1"]),
      disc2: _parseDouble(json["disc2"]),
      disc3: _parseDouble(json["disc3"]),
      disc4: _parseDouble(json["disc4"]),
      disc5: _parseDouble(json["disc5"]),
      plKasur: _parseDouble(json["pl_kasur"]),
      plDivan: _parseDouble(json["pl_divan"]),
      plHeadboard: _parseDouble(json["pl_headboard"]),
      plSorong: _parseDouble(json["pl_sorong"]),
      eupSorong: _parseDouble(json["eup_sorong"]),
      bottomPriceAnalyst: _parseDouble(json["bottom_price_analyst"]),
      itemNumber: json["item_number"]?.toString(),
      itemNumberKasur: json["item_number_kasur"]?.toString(),
      itemNumberDivan: json["item_number_divan"]?.toString(),
      itemNumberHeadboard: json["item_number_headboard"]?.toString(),
      itemNumberSorong: json["item_number_sorong"]?.toString(),
      itemNumberAccessories: json["item_number_accessories"]?.toString(),
      itemNumberBonus1: json["item_number_bonus1"]?.toString(),
      itemNumberBonus2: json["item_number_bonus2"]?.toString(),
      itemNumberBonus3: json["item_number_bonus3"]?.toString(),
      itemNumberBonus4: json["item_number_bonus4"]?.toString(),
      itemNumberBonus5: json["item_number_bonus5"]?.toString(),
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  // Helper method to safely parse integer values
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
