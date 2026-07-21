import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/auth/data/services/auth_service.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;

  setUp(() {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async => null,
    );
    mockAuthService = MockAuthService();
  });

  test('a second login() call while one is already in flight is ignored '
      '(no duplicate network request, no state race)', () async {
    final completer = Completer<AuthLoginResult>();
    when(() => mockAuthService.login(any(), any()))
        .thenAnswer((_) => completer.future);

    final notifier = AuthNotifier(authService: mockAuthService);
    // Let the constructor's _init() finish so it doesn't race our assertions.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final first = notifier.login('user@test.com', 'pw1');
    // Double-tap / retry while the first request is still in flight.
    final second = notifier.login('user@test.com', 'pw2');

    completer.complete(const AuthLoginResult(
      accessToken: 'tok-1',
      userEmail: 'user@test.com',
      userId: 42,
      userName: 'Test User',
      userImageUrl: '',
      areaId: 1,
    ));

    await first;
    await second;

    verify(() => mockAuthService.login(any(), any())).called(1);
    expect(notifier.state.isLoggedIn, isTrue);
    expect(notifier.state.accessToken, 'tok-1');
  });

  test('login() can be called again after a previous attempt finished',
      () async {
    when(() => mockAuthService.login(any(), any())).thenAnswer(
      (_) async => const AuthLoginResult(
        accessToken: 'tok-a',
        userEmail: 'a@test.com',
        userId: 1,
        userName: 'A',
        userImageUrl: '',
        areaId: 1,
      ),
    );

    final notifier = AuthNotifier(authService: mockAuthService);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await notifier.login('a@test.com', 'pw');
    expect(notifier.state.accessToken, 'tok-a');

    when(() => mockAuthService.login(any(), any())).thenAnswer(
      (_) async => const AuthLoginResult(
        accessToken: 'tok-b',
        userEmail: 'b@test.com',
        userId: 2,
        userName: 'B',
        userImageUrl: '',
        areaId: 1,
      ),
    );
    await notifier.login('b@test.com', 'pw');

    expect(notifier.state.accessToken, 'tok-b');
    verify(() => mockAuthService.login(any(), any())).called(2);
  });
}
