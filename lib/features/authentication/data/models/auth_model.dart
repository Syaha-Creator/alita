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
    return AuthModel(
      accessToken: json["access_token"] ?? "",
      tokenType: json["token_type"] ?? "Bearer",
      refreshToken: json["refresh_token"] ?? "",
      createdAt: json["created_at"] != null ? json["created_at"] as int : null,
      id: json["id"] ?? 0,
      email: json["email"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"],
      areaId: json["area_id"],
      area: json["area"],
      companyId: json["company_id"],
    );
  }
}
