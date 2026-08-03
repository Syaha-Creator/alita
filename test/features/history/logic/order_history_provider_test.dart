import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/core/services/api_session_expired.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:alitapricelist/features/history/logic/order_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Bypasses [AuthNotifier._init]'s secure-storage reads (which aren't
/// mocked in this test file) by overriding `build()` directly — same
/// pattern used for `_NoOpApprovalInboxNotifier` in the approval tests.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

Map<String, dynamic> _orderLetterRow({
  required int id,
  String noSp = 'SP-001',
  String createdAt = '2026-03-10T08:00:00',
}) {
  return {
    'order_letter': {
      'id': id,
      'no_sp': noSp,
      'order_date': '2026-03-10',
      'request_date': '2026-03-15',
      'note': '',
      'customer_name': 'Customer $id',
      'phone': '08123456789$id',
      'address': 'Jl. Test No. $id',
      'email': 'c$id@test.com',
      'extended_amount': 1000000 * id,
      'status': 'Pending',
      'created_at': createdAt,
    },
    'order_letter_details': <dynamic>[],
    'order_letter_payments': <dynamic>[],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(const Duration(seconds: 15));
  });

  // authProvider.logout() (triggered by the 401 test below) reaches into
  // StorageService's secure storage — mock the channel so it resolves
  // instead of throwing MissingPluginException.
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

  group('orderHistoryProvider', () {
    test('throws when userId is 0 (not logged in)', () async {
      final container = buildContainer(userId: 0);

      await expectLater(
        container.read(orderHistoryProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('fetches, parses, and sorts orders newest-first', () async {
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: {'user_id': '5'},
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'status': 'success',
            'result': [
              _orderLetterRow(
                id: 1,
                noSp: 'SP-OLD',
                createdAt: '2026-01-01T08:00:00',
              ),
              _orderLetterRow(
                id: 2,
                noSp: 'SP-NEW',
                createdAt: '2026-03-01T08:00:00',
              ),
            ],
          }),
          200,
        ),
      );

      final container = buildContainer();
      final orders = await container.read(orderHistoryProvider.future);

      expect(orders, hasLength(2));
      // Newest createdAt first.
      expect(orders[0].noSp, 'SP-NEW');
      expect(orders[1].noSp, 'SP-OLD');
    });

    test('includes date_from/date_to query params when dateFilterProvider '
        'is set', () async {
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'status': 'success', 'result': []}), 200),
      );

      final container = buildContainer();
      container.read(dateFilterProvider.notifier).state = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );

      await container.read(orderHistoryProvider.future);

      final captured = verify(
        () => mockApi.get(
          '/order_letters',
          queryParams: captureAny(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).captured;
      final queryParams = captured.single as Map<String, String>;
      expect(queryParams['user_id'], '5');
      expect(queryParams['date_from'], '2026-01-01');
      expect(queryParams['date_to'], '2026-01-31');
    });

    test('throws on non-200 response', () async {
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response('Server error', 500));

      final container = buildContainer();

      await expectLater(
        container.read(orderHistoryProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on malformed (non-success) API response body', () async {
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'status': 'error', 'message': 'Boom'}),
          200,
        ),
      );

      final container = buildContainer();

      await expectLater(
        container.read(orderHistoryProvider.future),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message', contains('Boom')),
        ),
      );
    });

    test('401 logs out and throws ApiSessionExpiredException', () async {
      when(
        () => mockApi.get(
          '/order_letters',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final container = buildContainer();

      await expectLater(
        container.read(orderHistoryProvider.future),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });
  });
}
