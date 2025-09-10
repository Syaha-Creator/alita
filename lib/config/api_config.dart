class ApiConfig {
  // Base URLs
  static const String baseUrl = "https://staging.alitav2.massindo.com/";
  // static const String baseUrl = "https://a3f7d0dbf05a.ngrok-free.app/";

  // Client credentials
  static const String clientId = "UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8";
  static const String clientSecret =
      "yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dVo";

  // LoginEndpoints
  static const String signIn =
      "${baseUrl}api/sign_in?client_id=$clientId&client_secret=$clientSecret";

  // Contact Work Experiences Endpoints
  static const String contactWorkExperiences =
      "${baseUrl}api/contact_work_experiences";

  // Products Endpoints
  static const String filteredProducts =
      "${baseUrl}api/rawdata_price_lists/filtered_pl";
  static const String plAreas = "${baseUrl}api/pl_areas";
  static const String plChannels = "${baseUrl}api/pl_channels";
  static const String plBrands = "${baseUrl}api/pl_brands";

  // Accessories Endpoints
  static const String accessories = "${baseUrl}api/pl_accessories";

  // Item Lookup Endpoints
  static const String plLookupItemNums = "${baseUrl}api/pl_lookup_item_nums";

  // Approval Endpoints
  static const String orderLetters = "${baseUrl}api/order_letters";
  static const String orderLetterDetails = "${baseUrl}api/order_letter_details";
  static const String orderLetterDiscounts =
      "${baseUrl}api/order_letter_discounts";
  static const String orderLetterApproves =
      "${baseUrl}api/order_letter_approves";

  // Leader Endpoints
  static const String leaderByUser = "${baseUrl}api/leaderbyuser";

  // Device Token Endpoints
  static const String deviceTokens = "${baseUrl}api/device_tokens";

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
    final encodedToken = Uri.encodeComponent(token);
    return "$filteredProducts?area=$encodedArea&channel=$encodedChannel&brand=$encodedBrand&access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk fetch areas
  static String getPlAreasUrl({
    required String token,
  }) {
    final encodedToken = Uri.encodeComponent(token);
    return "$plAreas?access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk fetch channels
  static String getPlChannelsUrl({
    required String token,
  }) {
    final encodedToken = Uri.encodeComponent(token);
    return "$plChannels?access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk fetch brands
  static String getPlBrandsUrl({
    required String token,
  }) {
    final encodedToken = Uri.encodeComponent(token);
    return "$plBrands?access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk fetch accessories
  static String getAccessoriesUrl({
    required String token,
  }) {
    final encodedToken = Uri.encodeComponent(token);
    return "$accessories?access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk contact work experience
  static String getContactWorkExperienceUrl({
    required String token,
    required int userId,
  }) {
    return "$contactWorkExperiences?access_token=$token&client_id=$clientId&client_secret=$clientSecret&user_id=$userId";
  }

  // Helper untuk item lookup
  static String getPlLookupItemNumsUrl({
    required String token,
  }) {
    final encodedToken = Uri.encodeComponent(token);
    return "$plLookupItemNums?access_token=$encodedToken&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk Order Letters
  static String getOrderLettersUrl({
    required String token,
    String? creator,
  }) {
    final creatorParam = creator != null ? "&creator=$creator" : "";
    return "$orderLetters?access_token=$token&client_id=$clientId&client_secret=$clientSecret$creatorParam";
  }

  // Helper untuk Order Letter Details
  static String getOrderLetterDetailsUrl({
    required String token,
    int? orderLetterId,
  }) {
    final orderLetterParam =
        orderLetterId != null ? "&order_letter_id=$orderLetterId" : "";
    return "$orderLetterDetails?access_token=$token&client_id=$clientId&client_secret=$clientSecret$orderLetterParam";
  }

  // Helper untuk Order Letter Discounts
  static String getOrderLetterDiscountsUrl({
    required String token,
    int? orderLetterId,
  }) {
    final orderLetterParam =
        orderLetterId != null ? "&order_letter_id=$orderLetterId" : "";
    return "$orderLetterDiscounts?access_token=$token&client_id=$clientId&client_secret=$clientSecret$orderLetterParam";
  }

  // Helper untuk POST Order Letters
  static String getCreateOrderLetterUrl({
    required String token,
  }) {
    return "$orderLetters?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk POST Order Letter Details
  static String getCreateOrderLetterDetailUrl({
    required String token,
  }) {
    return "$orderLetterDetails?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk POST Order Letter Discounts
  static String getCreateOrderLetterDiscountUrl({
    required String token,
  }) {
    return "$orderLetterDiscounts?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk PUT Order Letter Discounts (update discount)
  static String getUpdateOrderLetterDiscountUrl({
    required String token,
    required int discountId,
  }) {
    return "$orderLetterDiscounts/$discountId?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk PUT Order Letters (update order letter status)
  static String getUpdateOrderLetterUrl({
    required String token,
    required int orderLetterId,
  }) {
    return "$orderLetters/$orderLetterId?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk Order Letter Approves (GET)
  static String getOrderLetterApprovesUrl({
    required String token,
    int? orderLetterId,
    String? approverId,
  }) {
    final orderLetterParam =
        orderLetterId != null ? "&order_letter_id=$orderLetterId" : "";
    final approverParam = approverId != null ? "&approver_id=$approverId" : "";
    return "$orderLetterApproves?access_token=$token&client_id=$clientId&client_secret=$clientSecret$orderLetterParam$approverParam";
  }

  // Helper untuk POST Order Letter Approves
  static String getCreateOrderLetterApproveUrl({
    required String token,
  }) {
    return "$orderLetterApproves?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk Leader by User
  static String getLeaderByUserUrl({
    required String token,
    required String userId,
  }) {
    return "$leaderByUser?user_id=$userId&access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk GET Device Tokens
  static String getDeviceTokensUrl({
    required String token,
    required String userId,
  }) {
    return "$deviceTokens?user_id=$userId&access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }

  // Helper untuk POST Device Token
  static String getCreateDeviceTokenUrl({
    required String token,
  }) {
    return "$deviceTokens?access_token=$token&client_id=$clientId&client_secret=$clientSecret";
  }
}
