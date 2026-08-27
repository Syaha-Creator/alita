import 'dart:convert';

/// One row from [geo.velrox.cloud](https://geo.velrox.cloud) wilayah API.
class RegionItem {
  const RegionItem({
    required this.kode,
    required this.nama,
    this.kodepos,
  });

  final String kode;
  final String nama;
  final String? kodepos;
}

/// Pure JSON helpers for Wilayah ID / geo.velrox.cloud responses.
class RegionApiParser {
  RegionApiParser._();

  static List<RegionItem> parseListBody(String body) {
    try {
      final decoded = json.decode(body);
      final list = _extractList(decoded);
      if (list == null) return const [];
      return list.map(_itemFromDynamic).whereType<RegionItem>().toList();
    } catch (_) {
      return const [];
    }
  }

  static String toCacheJson(List<RegionItem> items) {
    return json.encode([
      for (final item in items)
        {
          'kode': item.kode,
          'nama': item.nama,
          if (item.kodepos != null) 'kodepos': item.kodepos,
        },
    ]);
  }

  static List<dynamic>? _extractList(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is List) return data;
    }
    return null;
  }

  static RegionItem? _itemFromDynamic(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    // Prefer Kemendagri keys; accept legacy EMSIFA id/name if still cached.
    final kode = (map['kode'] ?? map['id'] ?? '').toString().trim();
    final nama = (map['nama'] ?? map['name'] ?? '').toString().trim();
    if (kode.isEmpty || nama.isEmpty) return null;
    final kodeposRaw = map['kodepos']?.toString().trim();
    final kodepos =
        (kodeposRaw == null || kodeposRaw.isEmpty) ? null : kodeposRaw;
    return RegionItem(kode: kode, nama: nama, kodepos: kodepos);
  }
}
