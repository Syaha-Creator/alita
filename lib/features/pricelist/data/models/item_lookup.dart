/// Model untuk hasil API pl_lookup_item_nums (SKU Pabrik berdasarkan warna/kain).
class ItemLookup {
  final String tipe;
  final String ukuran;
  final String itemNum;
  final String? jenisKain;
  final String? warnaKain;

  ItemLookup({
    required this.tipe,
    required this.ukuran,
    required this.itemNum,
    this.jenisKain,
    this.warnaKain,
  });

  factory ItemLookup.fromJson(Map<String, dynamic> json) {
    return ItemLookup(
      tipe: json['tipe']?.toString() ?? '',
      ukuran: json['ukuran']?.toString() ?? '',
      itemNum: json['item_num']?.toString() ?? '',
      jenisKain: json['jenis_kain']?.toString(),
      warnaKain: json['warna_kain']?.toString(),
    );
  }

  /// Helper untuk UI: label singkat warna/jenis kain.
  String get displayLabel {
    final warna = warnaKain ?? '';
    final kain = jenisKain ?? '';
    if (warna.isNotEmpty && warnaKain != 'null') {
      return '$warna (${jenisKain ?? "-"})';
    } else if (kain.isNotEmpty && jenisKain != 'null') {
      return 'Kain $kain';
    }
    return 'Standard';
  }
}
