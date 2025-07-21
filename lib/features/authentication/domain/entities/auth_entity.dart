class AuthEntity {
  final int id;
  final String name;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int? areaId;

  AuthEntity({
    required this.id,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.areaId,
  });
}
