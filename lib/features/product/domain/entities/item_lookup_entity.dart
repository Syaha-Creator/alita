class ItemLookupEntity {
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

  ItemLookupEntity({
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

  @override
  String toString() {
    return 'ItemLookupEntity(id: $id, brand: $brand, tipe: $tipe, tebal: $tebal, ukuran: $ukuran, itemNum: $itemNum, itemDesc: $itemDesc, jenisKain: $jenisKain, warnaKain: $warnaKain, berat: $berat, kubikasi: $kubikasi, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemLookupEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
