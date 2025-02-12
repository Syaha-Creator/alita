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
      qtyBonus1: json["qty_bonus1"] ?? 0,
      bonus2: json["bonus_2"],
      qtyBonus2: json["qty_bonus2"] ?? 0,
      bonus3: json["bonus_3"],
      qtyBonus3: json["qty_bonus3"] ?? 0,
      bonus4: json["bonus_4"],
      qtyBonus4: json["qty_bonus4"] ?? 0,
      bonus5: json["bonus_5"],
      qtyBonus5: json["qty_bonus5"] ?? 0,
      disc1: (json["disc1"] ?? 0).toDouble(),
      disc2: (json["disc2"] ?? 0).toDouble(),
      disc3: (json["disc3"] ?? 0).toDouble(),
      disc4: (json["disc4"] ?? 0).toDouble(),
      disc5: (json["disc5"] ?? 0).toDouble(),
    );
  }

  // ✅ Perbaikan metode dariJsonList
  static List<ProductModel> fromJsonList(Map<String, dynamic> jsonMap) {
    if (jsonMap["result"] is List) {
      return (jsonMap["result"] as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }
}
