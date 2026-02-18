class AppConstants {
  static const String appName = "Alita Pricelist";
  static const String version = "1.7.22";
}

class StorageKeys {
  StorageKeys._();

  // Kunci untuk Sesi & Autentikasi
  static const String isLoggedIn = "is_logged_in";
  static const String loginTimestamp = "login_timestamp";
  static const String authToken = "auth_token";
  static const String refreshToken = "refresh_token";
  static const String currentUserId = "current_user_id";
  static const String currentUserAreaId = "current_user_area_id";
  static const String currentUserAddressNumber = "current_user_address_number";
  static const String rememberedEmail = "remembered_email";

  // Kunci untuk Keranjang Belanja
  static const String cartKeyBase = "cart_items_for_user_";
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String home = '/home';
  static const String product = '/product';
  static const String productDetail = 'product-detail';
  static const String productIndirect = '/product-indirect';
  static const String productIndirectDetail = 'indirect-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String approval = '/approval';
  static const String approvalMonitoring = '/approval-monitoring';
  static const String orderLetterDocument = '/order-letter-document';
}

class AppStrings {
  AppStrings._();

  static const String noKasur = "Tanpa Kasur";
  static const String noDivan = "Tanpa Divan";
  static const String noHeadboard = "Tanpa Headboard";
  static const String noSorong = "Tanpa Sorong";

  static const String setToggleLabel = "Gunakan Set";
  static const String showProductButton = "Tampilkan Produk";
  static const String noProductFound = "Tidak ada produk yang cocok.";
}

/// Area Codes untuk parameter API Indirect SAJA
/// TIDAK digunakan di Direct page
/// Mapping area code ke proper-cased area name
class AreaCodes {
  AreaCodes._();

  // Mapping 4-digit code ke proper-cased area name
  // Khusus untuk fitur Indirect Product
  static const Map<String, String> codeToNameMap = {
    '1101': 'Jabodetabek',
    '1102': 'Bandung',
    '1103': 'Medan',
    '1104': 'Pekanbaru',
    '1105': 'Semarang',
    '1106': 'Lampung',
    '1107': 'Padang',
    '1108': 'Palembang',
  };

  /// Get area code dari area name
  /// Returns null jika area tidak ditemukan
  static String? getAreaCode(String? areaName) {
    if (areaName == null || areaName.isEmpty) return null;
    try {
      return codeToNameMap.entries
          .firstWhere(
            (entry) => entry.value.toLowerCase() == areaName.toLowerCase(),
          )
          .key;
    } catch (e) {
      return null;
    }
  }

  /// Get area name dari area code (proper casing)
  /// Returns null jika code tidak ditemukan
  static String? getAreaName(String? areaCode) {
    if (areaCode == null || areaCode.isEmpty) return null;
    return codeToNameMap[areaCode];
  }

  /// Check apakah area memiliki code yang valid
  static bool hasValidCode(String? areaName) {
    return getAreaCode(areaName) != null;
  }

  /// Get list of area names yang memiliki valid code (proper casing)
  static List<String> get validAreaNames => codeToNameMap.values.toList();
}

/// Brand Codes untuk parameter API Indirect (catcode_27)
/// Mapping brand name ke 2-character code
class BrandCodes {
  BrandCodes._();

  // Mapping brand prefix (lowercase) ke catcode
  // Menggunakan prefix untuk handle variasi seperti:
  // - "Spring Air - European Collection"
  // - "Spring Air - American Classic"
  static const Map<String, String> brandCodeMap = {
    'comforta': 'CF',
    'spring air': 'SA',
    'therapedic': 'TH',
    'isleep': 'IS',
    'i-sleep': 'IS',
    'superfit': 'SF',
    'super fit': 'SF',
    'sleep center': 'SC',
    'sleepcenter': 'SC',
    'sleep spa': 'SS',
    'sleepspa': 'SS',
  };

  /// Get brand code dari brand name
  /// Menggunakan contains check untuk handle variasi brand name
  /// Contoh: "Spring Air - European Collection" -> "SA"
  static String? getBrandCode(String? brandName) {
    if (brandName == null || brandName.isEmpty) return null;

    final lowerBrand = brandName.toLowerCase();

    // Cek exact match dulu
    if (brandCodeMap.containsKey(lowerBrand)) {
      return brandCodeMap[lowerBrand];
    }

    // Cek dengan contains untuk handle variasi
    // Prioritaskan key yang lebih panjang untuk menghindari false positive
    final sortedKeys = brandCodeMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lowerBrand.contains(key)) {
        return brandCodeMap[key];
      }
    }

    return null;
  }

  /// Check apakah brand memiliki code yang valid
  static bool hasValidCode(String? brandName) {
    return getBrandCode(brandName) != null;
  }
}

/// API Config untuk Indirect Store (Toko)
class IndirectApiConfig {
  IndirectApiConfig._();

  static const String baseUrl = 'http://103.165.210.58:8000';

  /// Endpoint untuk fetch stores berdasarkan sales_code (address_number user)
  static const String storeEndpoint =
      '/address_number/address_number_by_sales_code';

  // Headers
  static const String apiKey = 'h9e9q4QmpJHpXD6qmO40DF5iMOqDEe';
  static const String clientKey = 'I6wmzpHYcI27XVAQyOy5kaRpBFejfP';

  /// Get full URL untuk fetch stores by sales_code
  /// sales_code adalah address_number user dari login
  static String getStoreUrl({required String salesCode}) {
    return '$baseUrl$storeEndpoint?sales_code=$salesCode';
  }

  /// Get headers untuk API request
  static Map<String, String> get headers => {
        'x-api-key': apiKey,
        'x-client-key': clientKey,
      };
}

class AppPadding {
  AppPadding._();

  static const double p2 = 2.0;
  static const double p3 = 3.0;
  static const double p4 = 4.0;
  static const double p5 = 5.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;
  static const double p40 = 40.0;
  static const double p100 = 100.0;
}
