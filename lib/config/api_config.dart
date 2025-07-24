class ApiConfig {
  // Base URLs
  // static const String baseUrl = "https://alitav2.massindo.com/";
  static const String baseUrl = "https://a3f7d0dbf05a.ngrok-free.app/";

  // Client credentials
  static const String clientId = "UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8";
  static const String clientSecret =
      "yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dVo";

  // Endpoints
  static const String signIn =
      "${baseUrl}api/sign_in?client_id=$clientId&client_secret=$clientSecret";
  static const String contactWorkExperiences =
      "${baseUrl}api/contact_work_experiences";
  static const String filteredProducts = "${baseUrl}api/filtered_pl";

  // Helper untuk login (POST ke signIn)
  static String getLoginUrl() {
    return signIn;
  }

  // Helper untuk fetch product (filtered products)
  static String getFilteredProductsUrl({
    required String token,
    required String area,
    required String channel,
    required String brand,
  }) {
    final encodedArea = Uri.encodeComponent(area);
    final encodedChannel = Uri.encodeComponent(channel);
    final encodedBrand = Uri.encodeComponent(brand);
    return "$filteredProducts?area=$encodedArea&channel=$encodedChannel&brand=$encodedBrand&access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk contact work experience
  static String getContactWorkExperienceUrl({
    required String token,
    required int userId,
  }) {
    return "$contactWorkExperiences?access_token=$token&client_id=$clientId&client_secret=$clientSecret&user_id=$userId";
  }
}
