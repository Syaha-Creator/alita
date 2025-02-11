class AuthEntity {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });
}
