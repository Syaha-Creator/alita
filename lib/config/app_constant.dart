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
