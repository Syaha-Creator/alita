class ApiConfig {
  // Base URL
  static const String baseUrl = "https://alitav2.massindo.com/";

  // OAuth Credentials (Gunakan dengan hati-hati, sebaiknya simpan di environment atau secure storage)
  static const String clientId = "eOfwGXXW4e3ysrxJkweoPP0aAAdB6BEC4BfXMxnMYVs";
  static const String clientSecret =
      "8DVadPpyMluM1P5vo3g-DsqX9DT_EtB-XlLVCFfjEVo";

  // API Endpoints
  static const String oauthToken = "${baseUrl}oauth/token";
  static const String contactWorkExperiences =
      "${baseUrl}api/contact_work_experiences";
  static const String rawdataPriceLists = "${baseUrl}api/rawdata_price_lists";

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
        "&client_id=hqJ199kBBLePkNt9mhS9EbgaCC6RarYxQux-fzebUZ8"
        "&client_secret=xtvj63aVIPaFNOiGKtOu1Su5EBYzdP_MZTG60uwGzP0";
  }
}
