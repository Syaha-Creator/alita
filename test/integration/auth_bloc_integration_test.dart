import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:alitapricelist/core/error/exceptions.dart';
import 'package:alitapricelist/features/authentication/domain/entities/auth_entity.dart';
import 'package:alitapricelist/features/authentication/domain/usecases/login_usecase.dart';
import 'package:alitapricelist/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:alitapricelist/features/authentication/data/repositories/auth_repository.dart';
import 'package:alitapricelist/features/authentication/presentation/bloc/auth_event.dart';
import 'package:alitapricelist/features/authentication/presentation/bloc/auth_state.dart';

import 'auth_bloc_integration_test.mocks.dart';

/// Integration test untuk AuthBloc
///
/// Test ini fokus pada testing behavior BLoC dengan mock LoginUseCase.
/// Note: AuthService.login() adalah static method yang sulit di-mock,
/// jadi kita fokus pada testing flow BLoC dan error handling.

@GenerateMocks([LoginUseCase, AuthRepository])
void main() {
  group('AuthBloc Integration Tests', () {
    late AuthBloc bloc;
    late MockLoginUseCase mockLoginUseCase;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockLoginUseCase = MockLoginUseCase();
      mockAuthRepository = MockAuthRepository();
      bloc = AuthBloc(
        loginUseCase: mockLoginUseCase,
        authRepository: mockAuthRepository,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state should be AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'should emit AuthLoading then AuthSuccess on successful login',
      build: () {
        // Mock successful login response
        final authEntity = AuthEntity(
          id: 1,
          name: 'Test User',
          accessToken: 'test_token_123',
          refreshToken: 'refresh_token_123',
          expiresIn: DateTime.now().millisecondsSinceEpoch + 3600000,
          areaId: 1,
          areaName: 'Jabodetabek',
        );

        when(mockLoginUseCase.call('test@example.com', 'password123'))
            .thenAnswer((_) async => authEntity);

        // Mock repository methods to avoid SharedPreferences calls
        when(mockAuthRepository.saveLoginData(
          token: anyNamed('token'),
          refreshToken: anyNamed('refreshToken'),
          userId: anyNamed('userId'),
          userName: anyNamed('userName'),
          areaId: anyNamed('areaId'),
          areaName: anyNamed('areaName'),
        )).thenAnswer((_) async => true);

        return bloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested('test@example.com', 'password123'),
      ),
      wait: const Duration(milliseconds: 500), // Wait for async operations
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'should emit AuthFailure on ServerException',
      build: () {
        when(mockLoginUseCase.call('test@example.com', 'wrongpassword'))
            .thenThrow(ServerException('Invalid credentials'));

        return bloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested('test@example.com', 'wrongpassword'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthFailure;
        expect(state.error, 'Invalid credentials');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit AuthFailure on NetworkException',
      build: () {
        when(mockLoginUseCase.call('test@example.com', 'password123'))
            .thenThrow(NetworkException('No internet connection'));

        return bloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested('test@example.com', 'password123'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthFailure;
        expect(state.error, 'No internet connection');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'should emit AuthFailure when token is empty',
      build: () {
        final authEntity = AuthEntity(
          id: 1,
          name: 'Test User',
          accessToken: '', // Empty token
          refreshToken: 'refresh_token',
          expiresIn: DateTime.now().millisecondsSinceEpoch + 3600000,
          areaId: 1,
          areaName: 'Jabodetabek',
        );

        when(mockLoginUseCase.call('test@example.com', 'password123'))
            .thenAnswer((_) async => authEntity);

        return bloc;
      },
      act: (bloc) => bloc.add(
        AuthLoginRequested('test@example.com', 'password123'),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>(),
      ],
      verify: (bloc) {
        final state = bloc.state as AuthFailure;
        expect(state.error, 'Login gagal: Token tidak ditemukan.');
      },
    );

    test('should emit AuthInitial on logout', () async {
      // Mock repository logout to avoid SharedPreferences calls
      when(mockAuthRepository.logout()).thenAnswer((_) async => true);

      // Note: Logout calls AuthService.logout() which is static
      // In full integration test, we would need to verify SharedPreferences is cleared
      bloc.add(AuthLogoutRequested());

      // Wait for state change with timeout
      await bloc.stream
          .timeout(const Duration(seconds: 5))
          .firstWhere((state) => state is AuthInitial);

      expect(bloc.state, isA<AuthInitial>());
    });
  });
}
