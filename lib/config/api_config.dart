class ApiConfig {
  // Base URL - Use staging for all endpoints
  static const String baseUrl = "https://alitav2.massindo.com/";
  static const String baseUrlLocal = "https://staging.alitav2.massindo.com/";
  static const String baseUrlNgrok = "https://177a3f35ae9c.ngrok-free.app/";

  // OAuth Credentials for staging (Gunakan dengan hati-hati, sebaiknya simpan di environment atau secure storage)
  static const String clientId = "eOfwGXXW4e3ysrxJkweoPP0aAAdB6BEC4BfXMxnMYVs";
  static const String clientSecret =
      "8DVadPpyMluM1P5vo3g-DsqX9DT_EtB-XlLVCFfjEVo";

  // Client credentials untuk staging endpoint
  static const String stagingClientId =
      "eOfwGXXW4e3ysrxJkweoPP0aAAdB6BEC4BfXMxnMYVs";
  static const String stagingClientSecret =
      "8DVadPpyMluM1P5vo3g-DsqX9DT_EtB-XlLVCFfjEVo";

  // API Endpoints - All using staging
  static const String oauthToken = "${baseUrl}oauth/token";
  static const String contactWorkExperiences =
      "${baseUrl}api/contact_work_experiences";
  static const String rawdataPriceLists = "${baseUrl}api/rawdata_price_lists";
  static const String rawdataPriceLists1 = "${baseUrl}api/filtered_pl";
  static const String rawdataPriceLists2 = "${baseUrlNgrok}api/filtered_pl";

  // Method untuk mendapatkan URL dengan parameter dinamis
  static String getLoginUrl(String email, String password) {
    return "$oauthToken?grant_type=password&email=$email&password=$password"
        "&client_id=$clientId&client_secret=$clientSecret";
  }

  static String getAreaAndDivisionUrl(String token, int userId) {
    return "$contactWorkExperiences?access_token=$token&user_id=$userId"
        "&client_id=$clientId&client_secret=$clientSecret";
  }

  static String getDropdownDataUrl(String token) {
    return "$rawdataPriceLists?access_token=$token"
        "&client_id=$stagingClientId&client_secret=$stagingClientSecret";
  }

  // New method for filtered product fetch
  static String getFilteredProductsUrl({
    required String token,
    required String area,
    required String channel,
    required String brand,
  }) {
    final encodedArea = Uri.encodeComponent(area);
    final encodedChannel = Uri.encodeComponent(channel);
    final encodedBrand = Uri.encodeComponent(brand);
    String url =
        "$rawdataPriceLists1?area=$encodedArea&channel=$encodedChannel&brand=$encodedBrand&access_token=$token"
        "&client_id=$stagingClientId&client_secret=$stagingClientSecret";
    return url;
  }
}
