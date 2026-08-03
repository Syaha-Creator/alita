import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/core/services/api_session_expired.dart';
import 'package:alitapricelist/features/approval/logic/approval_order_wrap_provider.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Bypasses [AuthNotifier._init]'s secure-storage reads by overriding
/// `build()` directly, same pattern used across the other provider tests.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  void mockSecureStorageChannel() {
    final store = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        switch (call.method) {
          case 'read':
            return store[call.arguments['key']];
          case 'write':
            store[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          case 'delete':
            store.remove(call.arguments['key']);
            return null;
          case 'deleteAll':
            store.clear();
            return null;
          default:
            return null;
        }
      },
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSecureStorageChannel();
    mockApi = MockApiClient();
  });

  ProviderContainer buildContainer({int userId = 5}) {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          () => _FakeAuthNotifier(AuthState(userId: userId, isLoading: false)),
        ),
        apiClientProvider.overrideWithValue(mockApi),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('approvalOrderWrapProvider', () {
    test('resolves the raw wrap map when the direct GET succeeds', () async {
      when(() => mockApi.get('/order_letters/10')).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'order_letter': {'id': 10, 'status': 'Pending'},
          }),
          200,
        ),
      );

      final container = buildContainer();
      final wrap = await container.read(approvalOrderWrapProvider(10).future);

      expect(wrap['order_letter']['id'], 10);
    });

    test('throws when the order letter cannot be found', () async {
      when(() => mockApi.get('/order_letters/11'))
          .thenAnswer((_) async => http.Response('Not found', 404));
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: any(named: 'queryParams'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': <dynamic>[]}), 200),
      );

      final container = buildContainer();

      await expectLater(
        container.read(approvalOrderWrapProvider(11).future),
        throwsA(isA<Exception>()),
      );
    });

    test('401 triggers logout + rethrows ApiSessionExpiredException',
        () async {
      when(() => mockApi.get('/order_letters/12'))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      final container = buildContainer();

      await expectLater(
        container.read(approvalOrderWrapProvider(12).future),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });
  });
}
