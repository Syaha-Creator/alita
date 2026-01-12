/// Helper class untuk matching area name dari berbagai sumber
///
/// Logic ini dipindahkan dari ProductBloc untuk meningkatkan maintainability
/// dan testability.
class ProductAreaMatcher {
  /// Mapping region names ke PL area names
  static const Map<String, String> _regionToPlArea = {
    // Jabodetabek variants
    'jabodetabek': 'Jabodetabek',
    'dki jakarta': 'Jabodetabek',
    'jakarta': 'Jabodetabek',
    'bogor': 'Jabodetabek',
    'depok': 'Jabodetabek',
    'tangerang': 'Jabodetabek',
    'bekasi': 'Jabodetabek',
    // Jawa
    'bandung': 'Bandung',
    'jawa barat': 'Bandung',
    'surabaya': 'Surabaya',
    'jawa timur': 'Surabaya',
    'semarang': 'Semarang',
    'jawa tengah': 'Semarang',
    'yogyakarta': 'Yogyakarta',
    'diy': 'Yogyakarta',
    'solo': 'Solo',
    'surakarta': 'Solo',
    'malang': 'Malang',
    'denpasar': 'Denpasar',
    'bali': 'Denpasar',
    // Sumatera - berbagai variasi spelling
    'medan': 'Medan',
    'sumatera utara': 'Medan',
    'sumatra utara': 'Medan',
    'palembang': 'Palembang',
    'sumatera selatan': 'Palembang',
    'sumatra selatan': 'Palembang',
    'pekanbaru': 'Pekanbaru',
    'riau': 'Pekanbaru',
    'padang': 'Padang',
    'sumatera barat': 'Padang',
    'sumatra barat': 'Padang',
    'lampung': 'Lampung',
    'bandar lampung': 'Lampung',
  };

  /// Legacy ID mapping (untuk backward compatibility)
  static const Map<int, List<String>> _areaMapping = {
    0: ["Nasional"],
    1: ["Jabodetabek"],
    2: ["Bandung"],
    9: ["Medan"],
    10: ["Palembang"],
    11: ["Pekanbaru"],
    12: ["Padang"],
    13: ["Lampung"],
    20: ["Palembang"],
  };

  /// Match area name dari user area name (dari CWE) ke PL area name
  ///
  /// [userAreaName] - Area name dari CWE (bisa berbagai format)
  /// [availableAreas] - List area yang tersedia di PL
  ///
  /// Returns matched area name atau null jika tidak ditemukan
  static String? matchAreaByName(
    String? userAreaName,
    List<String> availableAreas,
  ) {
    if (userAreaName == null || userAreaName.isEmpty) return null;

    final normalizedName = userAreaName.toLowerCase().trim();

    // Exact match first
    final exactMatch = _regionToPlArea[normalizedName];
    if (exactMatch != null && availableAreas.contains(exactMatch)) {
      return exactMatch;
    }

    // Partial match
    for (final entry in _regionToPlArea.entries) {
      if (normalizedName.contains(entry.key) ||
          entry.key.contains(normalizedName)) {
        if (availableAreas.contains(entry.value)) {
          return entry.value;
        }
      }
    }

    // Direct match with available areas
    for (final area in availableAreas) {
      if (area.toLowerCase() == normalizedName) {
        return area;
      }
    }

    return null;
  }

  /// Get area name dari area ID
  ///
  /// [areaId] - ID area
  /// [availableAreas] - List area yang tersedia di PL
  ///
  /// Returns matched area name atau null jika tidak ditemukan
  static String? getAreaNameFromId(
    int areaId,
    List<String> availableAreas,
  ) {
    // Method 1: Cek dari areaMapping by ID
    final possibleNames = _areaMapping[areaId];
    if (possibleNames != null) {
      for (final name in possibleNames) {
        if (availableAreas.contains(name)) {
          return name;
        }
      }
    }

    // Method 2: Gunakan regionToPlArea mapping (lebih flexible)
    // Ini akan catch case seperti "SUMATRA SELATAN" → "Palembang"
    for (final entry in _regionToPlArea.entries) {
      // Cek apakah ada area yang match dengan key (region name)
      for (final availableArea in availableAreas) {
        final plAreaName = entry.value;
        if (availableArea == plAreaName &&
            availableAreas.contains(plAreaName)) {
          if (possibleNames?.any((n) => n.toLowerCase() == entry.key) ??
              false) {
            return plAreaName;
          }
        }
      }
    }

    // Method 3: Fallback ke "Nasional" jika tersedia
    if (availableAreas.contains("Nasional")) {
      return "Nasional";
    }

    // Last resort: return area pertama yang tersedia
    if (availableAreas.isNotEmpty) {
      return availableAreas.first;
    }

    return null;
  }
}
