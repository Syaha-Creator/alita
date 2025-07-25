import '../../data/repositories/auth_repository.dart';
import '../entities/auth_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthEntity> call(String email, String password) async {
    final authModel = await repository.login(email, password);
    return AuthEntity(
      id: authModel.id,
      name: authModel.name,
      accessToken: authModel.accessToken,
      refreshToken: authModel.refreshToken,
      expiresIn: authModel.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      areaId: authModel.areaId,
    );
  }
}
