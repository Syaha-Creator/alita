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
  static const String rememberedEmail = "remembered_email";

  // Kunci untuk Keranjang Belanja
  static const String cartKeyBase = "cart_items_for_user_";
}

class RoutePaths {
  RoutePaths._();

  static const String login = '/login';
  static const String product = '/product';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
}

class AppStrings {
  AppStrings._();

  static const String noKasur = "Tanpa Kasur";
  static const String noDivan = "Tanpa Divan";
  static const String noHeadboard = "Tanpa Headboard";
  static const String noSorong = "Tanpa Sorong";
}
