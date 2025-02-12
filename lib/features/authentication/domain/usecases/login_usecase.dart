import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthEntity> call(String email, String password) async {
    final authModel = await repository.login(email, password);
    return AuthEntity(
      accessToken: authModel.accessToken,
      refreshToken: authModel.refreshToken,
      expiresIn: authModel.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}
