double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

/// Model untuk aksesoris dari API pl_accessories (pengganti bonus).
class Accessory {
  final String tipe;
  final String itemNum;
  final String ukuran;
  final double pricelist;

  Accessory({
    required this.tipe,
    required this.itemNum,
    required this.ukuran,
    required this.pricelist,
  });

  factory Accessory.fromJson(Map<String, dynamic> json) {
    return Accessory(
      tipe: json['tipe']?.toString() ?? '',
      itemNum: json['item_num']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '',
      pricelist: _parseDouble(json['pricelist']),
    );
  }
}
