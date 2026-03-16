/// Utility for mapping user area (province/alias) to system area (dropdown values).
///
/// Dropdown pl_areas may use city/cabang names (e.g. "Palembang", "Jabodetabek")
/// while auth/profile may return province names (e.g. "Sumatra Selatan", "Sumsel").
/// This mapping resolves the mismatch so default area selection works.
class AreaUtils {
  AreaUtils._();

  /// Map dari provinsi/alias umum ke nama area yang ada di sistem (pl_areas).
  /// Key: lowercase; value: suggested system name (disesuaikan dengan API).
  static const Map<String, String> _areaMapping = {
    'sumsel': 'Palembang',
    'sumatera selatan': 'Palembang',
    'sumatra selatan': 'Palembang',
    'sumbar': 'Padang',
    'sumatera barat': 'Padang',
    'sumatra barat': 'Padang',
    'jabar': 'Bandung',
    'jawa barat': 'Bandung',
    'jatim': 'Surabaya',
    'jawa timur': 'Surabaya',
    'jateng': 'Semarang',
    'jawa tengah': 'Semarang',
    'bali': 'Denpasar',
    'ntb': 'Mataram',
    'nusa tenggara barat': 'Mataram',
    'ntt': 'Kupang',
    'nusa tenggara timur': 'Kupang',
    'lampung': 'Bandar Lampung',
    'jakarta': 'Jabodetabek',
    'banten': 'Jabodetabek',
    'jabodetabek': 'Jabodetabek',
    'bogor': 'Jabodetabek',
    'depok': 'Jabodetabek',
    'tangerang': 'Jabodetabek',
    'bekasi': 'Jabodetabek',
    'sumut': 'Medan',
    'sumatera utara': 'Medan',
    'sumatra utara': 'Medan',
    'riau': 'Pekanbaru',
    'kaltim': 'Samarinda',
    'kalimantan timur': 'Samarinda',
    'sulsel': 'Makassar',
    'sulawesi selatan': 'Makassar',
    'kalsel': 'Banjarmasin',
    'kalimantan selatan': 'Banjarmasin',
    'sulut': 'Manado',
    'sulawesi utara': 'Manado',
    'kalbar': 'Pontianak',
    'kalimantan barat': 'Pontianak',
    'sulteng': 'Palu',
    'sulawesi tengah': 'Palu',
    'sultra': 'Kendari',
    'sulawesi tenggara': 'Kendari',
    'maluku': 'Ambon',
    'maluku utara': 'Ternate',
    'papua': 'Nasional',
    'papua barat': 'Nasional',
    'gorontalo': 'Gorontalo',
    'kotamobagu': 'Kotamobagu',
  };

  /// Maps user area string (province/alias) to suggested system area name.
  /// Returns null if no mapping found.
  static String? mapUserAreaToSystemArea(String userArea) {
    if (userArea.trim().isEmpty) return null;
    final key = userArea.trim().toLowerCase();
    return _areaMapping[key];
  }

  /// Resolves default area for dropdown selection.
  ///
  /// Logic:
  /// 1. If [userArea] exactly matches (case-insensitive) an item in [availableAreas], return that item (preserves casing).
  /// 2. Otherwise map [userArea] via [mapUserAreaToSystemArea] and check if mapped value exists in [availableAreas].
  /// 3. Fuzzy: userArea contained in area name or vice versa.
  /// 4. Fallback: "Nasional" if in list, else "Jabodetabek" if in list, else first item.
  static String resolveDefaultArea(String userArea, List<String> availableAreas) {
    if (userArea.trim().isEmpty) {
      return _pickFallback(availableAreas);
    }

    final trimmed = userArea.trim();
    final available = availableAreas.where((s) => s.trim().isNotEmpty).toList();

    // a. Exact match (case-insensitive) — return actual list item to preserve casing
    for (final a in available) {
      if (a.toLowerCase() == trimmed.toLowerCase()) return a;
    }

    // b. Map via dictionary, then find in list
    final mapped = mapUserAreaToSystemArea(trimmed);
    if (mapped != null) {
      for (final a in available) {
        if (a.toLowerCase() == mapped.toLowerCase()) return a;
      }
    }

    // c. Fuzzy: check if userArea is contained in any area name (e.g. "Sumsel" in "Palembang Sumsel")
    final lowerUser = trimmed.toLowerCase();
    for (final a in available) {
      final lowerA = a.toLowerCase();
      if (lowerA.contains(lowerUser) || lowerUser.contains(lowerA)) return a;
    }

    // d. Fallback
    return _pickFallback(available);
  }

  static String _pickFallback(List<String> available) {
    if (available.isEmpty) return 'Nasional';

    final lower = available.map((a) => a.toLowerCase()).toList();
    if (lower.contains('nasional')) {
      return available[lower.indexOf('nasional')];
    }
    if (lower.contains('jabodetabek')) {
      return available[lower.indexOf('jabodetabek')];
    }
    return available.first;
  }
}
