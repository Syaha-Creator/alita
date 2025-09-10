class ItemLookupModel {
  final int id;
  final String brand;
  final String tipe;
  final String tebal;
  final String ukuran;
  final String itemNum;
  final String itemDesc;
  final String jenisKain;
  final String? warnaKain;
  final String berat;
  final String kubikasi;
  final String createdAt;
  final String updatedAt;

  ItemLookupModel({
    required this.id,
    required this.brand,
    required this.tipe,
    required this.tebal,
    required this.ukuran,
    required this.itemNum,
    required this.itemDesc,
    required this.jenisKain,
    this.warnaKain,
    required this.berat,
    required this.kubikasi,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemLookupModel.fromJson(Map<String, dynamic> json) {
    return ItemLookupModel(
      id: json["id"]?.toInt() ?? 0,
      brand: json["brand"]?.toString() ?? "",
      tipe: json["tipe"]?.toString() ?? "",
      tebal: json["tebal"]?.toString() ?? "",
      ukuran: json["ukuran"]?.toString() ?? "",
      itemNum: json["item_num"]?.toString() ?? "",
      itemDesc: json["item_desc"]?.toString() ?? "",
      jenisKain: json["jenis_kain"]?.toString() ?? "",
      warnaKain: json["warna_kain"]?.toString(),
      berat: json["berat"]?.toString() ?? "",
      kubikasi: json["kubikasi"]?.toString() ?? "",
      createdAt: json["created_at"]?.toString() ?? "",
      updatedAt: json["updated_at"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "brand": brand,
      "tipe": tipe,
      "tebal": tebal,
      "ukuran": ukuran,
      "item_num": itemNum,
      "item_desc": itemDesc,
      "jenis_kain": jenisKain,
      "warna_kain": warnaKain,
      "berat": berat,
      "kubikasi": kubikasi,
      "created_at": createdAt,
      "updated_at": updatedAt,
    };
  }

  @override
  String toString() {
    return 'ItemLookupModel(id: $id, brand: $brand, tipe: $tipe, tebal: $tebal, ukuran: $ukuran, itemNum: $itemNum, itemDesc: $itemDesc, jenisKain: $jenisKain, warnaKain: $warnaKain, berat: $berat, kubikasi: $kubikasi, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemLookupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
