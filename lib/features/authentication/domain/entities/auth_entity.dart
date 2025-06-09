class AuthEntity {
  final int id;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthEntity({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}
