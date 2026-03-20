import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/auth/logic/auth_provider.dart';

void main() {
  group('AuthState', () {
    test('default values', () {
      const state = AuthState();
      expect(state.isLoggedIn, false);
      expect(state.userEmail, '');
      expect(state.defaultArea, 'Jabodetabek');
      expect(state.isLoading, true);
      expect(state.accessToken, '');
      expect(state.userId, 0);
      expect(state.userName, '');
      expect(state.userImageUrl, '');
      expect(state.errorMessage, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const original = AuthState(
        isLoggedIn: true,
        userEmail: 'a@b.com',
        userId: 42,
        userName: 'Alice',
      );
      final copy = original.copyWith(userName: 'Bob');
      expect(copy.isLoggedIn, true);
      expect(copy.userEmail, 'a@b.com');
      expect(copy.userId, 42);
      expect(copy.userName, 'Bob');
    });

    test('copyWith can set errorMessage', () {
      const state = AuthState();
      final withError = state.copyWith(errorMessage: 'Gagal login');
      expect(withError.errorMessage, 'Gagal login');
    });

    test('copyWith clearError removes errorMessage', () {
      final state = const AuthState().copyWith(errorMessage: 'Error!');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('clearError false preserves errorMessage', () {
      final state = const AuthState().copyWith(errorMessage: 'E');
      final notCleared = state.copyWith(clearError: false);
      expect(notCleared.errorMessage, 'E');
    });

    test('copyWith overrides multiple fields', () {
      const original = AuthState(isLoading: true);
      final updated = original.copyWith(
        isLoggedIn: true,
        isLoading: false,
        accessToken: 'tok',
        userId: 5206,
        defaultArea: 'Surabaya',
      );
      expect(updated.isLoggedIn, true);
      expect(updated.isLoading, false);
      expect(updated.accessToken, 'tok');
      expect(updated.userId, 5206);
      expect(updated.defaultArea, 'Surabaya');
    });
  });
}
