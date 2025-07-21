class AuthModel {
  final String accessToken;
  final String tokenType;
  final String refreshToken;
  final int? createdAt;
  final int id;
  final String email;
  final String name;
  final String? phone;
  final int? areaId;
  final String? area;
  final int? companyId;

  AuthModel({
    required this.accessToken,
    required this.tokenType,
    required this.refreshToken,
    this.createdAt,
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.areaId,
    this.area,
    this.companyId,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    String? token = json['access_token'];
    if (token == null || token.isEmpty) {
      if (json['token'] != null) {
        token = json['token'];
      } else if (json['data'] != null && json['data']['token'] != null) {
        token = json['data']['token'];
      }
    }

    // Extract user data from response
    Map<String, dynamic>? userData;
    if (json['user'] != null) {
      userData = json['user'] as Map<String, dynamic>;
    } else {
      // Fallback to root level if user object doesn't exist
      userData = json;
    }

    final areaId = userData["area_id"];

    return AuthModel(
      accessToken: token ?? "",
      tokenType: json["token_type"] ?? "Bearer",
      refreshToken: json["refresh_token"] ?? "",
      createdAt: json["created_at"] != null ? json["created_at"] as int : null,
      id: userData["id"] ?? 0,
      email: userData["email"] ?? "",
      name: userData["user_name"] ?? userData["name"] ?? "",
      phone: userData["phone"],
      areaId: areaId,
      area: userData["area"],
      companyId: userData["company_id"],
    );
  }
}
