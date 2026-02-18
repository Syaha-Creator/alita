/// Model untuk data toko dari API Indirect
///
/// Response API:
/// {
///   "address_number": 20000041,
///   "parent_number": 30488583,
///   "long_address_number": "003-C0001",
///   "tax_number": "03.163.760.6.024.000",
///   "alpha_name": "PT.CHANDRA KARYA PRAMUKA (CF)",
///   "address": "JL PRAMUKA RAYA...",
///   "branch": "1101",
///   "search_type": "DO",
///   "catcode_27": "CF"
/// }
class StoreModel {
  final int addressNumber;
  final int? parentNumber;
  final String? longAddressNumber;
  final String? taxNumber;
  final String alphaName;
  final String address;
  final String? branch;
  final String? searchType;
  final String? catcode27; // Brand code langsung dari API

  StoreModel({
    required this.addressNumber,
    this.parentNumber,
    this.longAddressNumber,
    this.taxNumber,
    required this.alphaName,
    required this.address,
    this.branch,
    this.searchType,
    this.catcode27,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      addressNumber: json['address_number'] ?? 0,
      parentNumber: json['parent_number'],
      longAddressNumber: json['long_address_number']?.toString(),
      taxNumber: json['tax_number']?.toString(),
      alphaName: json['alpha_name'] ?? '',
      address: json['address'] ?? '',
      branch: json['branch']?.toString(),
      searchType: json['search_type']?.toString(),
      catcode27: json['catcode_27']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_number': addressNumber,
      'parent_number': parentNumber,
      'long_address_number': longAddressNumber,
      'tax_number': taxNumber,
      'alpha_name': alphaName,
      'address': address,
      'branch': branch,
      'search_type': searchType,
      'catcode_27': catcode27,
    };
  }

  /// Display name untuk dropdown (nama toko)
  String get displayName => alphaName;

  /// Get brand code dari catcode_27
  /// Contoh: "CF" -> Comforta, "SA" -> Spring Air, "TH" -> Therapedic
  String? get brandCode => catcode27;

  /// Get brand name berdasarkan brand code di alpha_name
  /// CF -> Comforta, SA -> Spring Air, TH -> Therapedic, dll
  /// Untuk SA, return null karena perlu pilih sub-brand
  String? get brandName {
    final code = brandCode;
    if (code == null) return null;

    // SA perlu pilih sub-brand, jadi return null
    if (code == 'SA') return null;

    // Reverse mapping dari BrandCodes
    const codeToName = {
      'CF': 'Comforta',
      'SA': 'Spring Air',
      'TH': 'Therapedic',
      'IS': 'iSleep',
      'SS': 'Sleep Spa',
      'SF': 'Superfit',
    };

    return codeToName[code];
  }

  /// Check apakah brand memerlukan pemilihan sub-brand
  /// SA (Spring Air) punya 2 sub-brand: European Collection & American Classic
  bool get needsSubBrandSelection => brandCode == 'SA';

  /// Get daftar sub-brand jika ada
  /// SA -> [Spring Air - European Collection, Spring Air - American Classic]
  List<String> get availableSubBrands {
    if (brandCode == 'SA') {
      return [
        'Spring Air - European Collection',
        'Spring Air - American Classic',
      ];
    }
    return [];
  }

  /// Check apakah brand harus menggunakan area Nasional
  /// SA (Spring Air) dan TH (Therapedic) menggunakan Nasional
  bool get usesNationalArea {
    final code = brandCode;
    return code == 'SA' || code == 'TH';
  }

  /// Get effective area untuk brand ini
  /// SA & TH -> Nasional, lainnya -> dari branch
  String? getEffectiveArea(String? Function(String?) areaNameFromBranch) {
    if (usesNationalArea) {
      return 'Nasional';
    }
    return areaNameFromBranch(branch);
  }

  /// Get store discounts (berjenjang/cascading)
  /// Hardcoded untuk testing - nanti bisa diambil dari API
  List<double> get storeDiscounts {
    // Mapping berdasarkan nama toko (case insensitive, partial match)
    final name = alphaName.toUpperCase();

    if (name.contains('CHANDRA KARYA PRAMUKA')) {
      return [40, 10, 5, 5, 7.5]; // Chandra Karya Pramuka
    } else if (name.contains('JULI NOVITA')) {
      return [40, 10, 5, 5, 7, 2.5]; // Juli Novita
    } else if (name.contains('HANDAL MITRA SEJATI')) {
      return [40, 10, 5, 5, 2.5]; // Juli Novita
    } else if (name.contains('CHANDRA KARYA')) {
      return [40, 10, 5, 5, 7.5]; // Chandra Karya (other branches)
    }

    // Default: no discount
    return [];
  }

  /// Get discount string untuk display (e.g., "40 + 10 + 5 + 5 + 7,5")
  String get discountDisplayString {
    if (storeDiscounts.isEmpty) return '-';

    return storeDiscounts.map((d) {
      // Format: gunakan koma untuk desimal (Indonesia)
      if (d == d.truncateToDouble()) {
        return d.toInt().toString();
      } else {
        return d.toString().replaceAll('.', ',');
      }
    }).join(' + ');
  }

  /// Calculate price after applying cascading discounts
  /// Diskon berjenjang: setiap diskon diterapkan ke hasil sebelumnya
  double calculateDiscountedPrice(double pricelist) {
    if (storeDiscounts.isEmpty) return pricelist;

    double result = pricelist;
    for (final discount in storeDiscounts) {
      result = result * (1 - discount / 100);
    }
    return result;
  }

  /// Get total effective discount percentage (untuk informasi)
  double get totalEffectiveDiscount {
    if (storeDiscounts.isEmpty) return 0;

    double multiplier = 1;
    for (final discount in storeDiscounts) {
      multiplier *= (1 - discount / 100);
    }
    return (1 - multiplier) * 100;
  }

  /// toString returns displayName untuk digunakan di CustomDropdown
  @override
  String toString() => alphaName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoreModel && other.addressNumber == addressNumber;
  }

  @override
  int get hashCode => addressNumber.hashCode;
}
