import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/features/authentication/data/models/auth_model.dart';
import 'package:alitapricelist/features/authentication/data/repositories/auth_repository.dart';
import 'package:alitapricelist/features/authentication/domain/entities/auth_entity.dart';
import 'package:alitapricelist/features/authentication/domain/usecases/login_usecase.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('should return AuthEntity from repository', () async {
      // Arrange
      final authModel = AuthModel(
        accessToken: 'test_access_token',
        tokenType: 'Bearer',
        refreshToken: 'test_refresh_token',
        createdAt: 1234567890,
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        areaId: 1,
        area: 'Jabodetabek',
      );

      when(mockRepository.login(any, any)).thenAnswer((_) async => authModel);

      // Act
      final result = await useCase.call('test@example.com', 'password123');

      // Assert
      expect(result, isA<AuthEntity>());
      expect(result.id, equals(1));
      expect(result.name, equals('Test User'));
      expect(result.accessToken, equals('test_access_token'));
      expect(result.refreshToken, equals('test_refresh_token'));
      expect(result.areaId, equals(1));
      expect(result.areaName, equals('Jabodetabek'));
      verify(mockRepository.login('test@example.com', 'password123')).called(1);
    });

    test('should use current timestamp if createdAt is null', () async {
      // Arrange
      final authModel = AuthModel(
        accessToken: 'test_access_token',
        tokenType: 'Bearer',
        refreshToken: 'test_refresh_token',
        createdAt: null, // No createdAt
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        areaId: 1,
        area: 'Jabodetabek',
      );

      when(mockRepository.login(any, any)).thenAnswer((_) async => authModel);

      // Act
      final result = await useCase.call('test@example.com', 'password123');

      // Assert
      expect(result.expiresIn, greaterThan(0));
      // Should use current timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      expect(result.expiresIn, lessThanOrEqualTo(now));
    });

    test('should handle null areaId and areaName', () async {
      // Arrange
      final authModel = AuthModel(
        accessToken: 'test_access_token',
        tokenType: 'Bearer',
        refreshToken: 'test_refresh_token',
        createdAt: 1234567890,
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        areaId: null,
        area: null,
      );

      when(mockRepository.login(any, any)).thenAnswer((_) async => authModel);

      // Act
      final result = await useCase.call('test@example.com', 'password123');

      // Assert
      expect(result.areaId, isNull);
      expect(result.areaName, isNull);
    });
  });
}
