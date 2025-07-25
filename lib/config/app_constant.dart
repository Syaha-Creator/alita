class AppConstants {
  static const String appName = "Alita Pricelist";
  static const String version = "1.0.0";
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
  static const String rememberedEmail = "remembered_email";

  // Kunci untuk Keranjang Belanja
  static const String cartKeyBase = "cart_items_for_user_";
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String product = '/product';
  static const String productDetail = 'detail';
  static const String cart = '/cart';
  static const String approval = '/approval';
  static const String checkout = '/checkout';
  static const String approvalMonitoring = '/approval-monitoring';
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

class AppPadding {
  AppPadding._();

  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
}

// Enums for dropdown options
enum AreaEnum {
  nasional("Nasional"),
  jabodetabek("Jabodetabek"),
  bandung("Bandung"),
  surabaya("Surabaya"),
  semarang("Semarang"),
  yogyakarta("Yogyakarta"),
  solo("Solo"),
  malang("Malang"),
  denpasar("Denpasar"),
  medan("Medan"),
  palembang("Palembang");

  const AreaEnum(this.value);
  final String value;

  static AreaEnum? fromString(String? value) {
    if (value == null) return null;
    return AreaEnum.values.firstWhere(
      (area) => area.value.toLowerCase() == value.toLowerCase(),
      orElse: () => AreaEnum.jabodetabek,
    );
  }

  static int? getId(AreaEnum area) {
    switch (area) {
      case AreaEnum.nasional:
        return 0;
      case AreaEnum.jabodetabek:
        return 1;
      case AreaEnum.bandung:
        return 2;
      case AreaEnum.surabaya:
        return 3;
      case AreaEnum.semarang:
        return 4;
      case AreaEnum.yogyakarta:
        return 5;
      case AreaEnum.solo:
        return 6;
      case AreaEnum.malang:
        return 7;
      case AreaEnum.denpasar:
        return 8;
      case AreaEnum.medan:
        return 9;
      case AreaEnum.palembang:
        return 10;
    }
  }
}

enum ChannelEnum {
  callCenter("Call Center"),
  indirect("Indirect"),
  retail("Retail"),
  accessories("Accessories"),
  massindofairdirect("Massindo Fair - Direct"),
  massindofairindirect("Massindo Fair - Indirect"),
  modernmarket("Modern Market");

  const ChannelEnum(this.value);
  final String value;

  static ChannelEnum? fromString(String? value) {
    if (value == null) return null;
    return ChannelEnum.values.firstWhere(
      (channel) => channel.value.toLowerCase() == value.toLowerCase(),
      orElse: () => ChannelEnum.callCenter,
    );
  }
}

enum BrandEnum {
  superfit("Superfit"),
  therapedic("Therapedic"),
  sleepspa("Sleep Spa"),
  springair("Spring Air"),
  comforta("Comforta"),
  isleep("iSleep");

  const BrandEnum(this.value);
  final String value;

  static BrandEnum? fromString(String? value) {
    if (value == null) return null;
    return BrandEnum.values.firstWhere(
      (brand) => brand.value.toLowerCase() == value.toLowerCase(),
      orElse: () => BrandEnum.superfit,
    );
  }
}

// Note: Kasur, Divan, Headboard, Sorong, and Size will be dynamic based on API data
// since they have many variations and are not fixed values
