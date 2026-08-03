import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/enums/sales_mode.dart';
import 'package:alitapricelist/features/auth/data/services/auth_service.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:alitapricelist/features/indirect/logic/sales_mode_provider.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async => null,
    );
    mockAuthService = MockAuthService();
    container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          () => AuthNotifier(authService: mockAuthService),
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('a second login() call while one is already in flight is ignored '
      '(no duplicate network request, no state race)', () async {
    final completer = Completer<AuthLoginResult>();
    when(() => mockAuthService.login(any(), any()))
        .thenAnswer((_) => completer.future);

    final notifier = container.read(authProvider.notifier);
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

    final notifier = container.read(authProvider.notifier);
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

  test(
    'logout() resets sales mode to direct so it never leaks into the next '
    'account that logs in on this device',
    () async {
      SharedPreferences.setMockInitialValues({'sales_mode_v1': 'indirect'});
      final notifier = container.read(authProvider.notifier);
      // Trigger salesModeProvider's lazy instantiation, then let both its
      // async _load() and AuthNotifier's _init() finish.
      container.read(salesModeProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Sanity check: the previous user's indirect mode is loaded.
      expect(container.read(salesModeProvider), SalesMode.indirect);

      await notifier.logout();

      expect(container.read(salesModeProvider), SalesMode.direct);
    },
  );
}
