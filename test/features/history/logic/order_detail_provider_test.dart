import 'dart:convert';
import 'dart:io';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/core/services/api_session_expired.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:alitapricelist/features/history/logic/order_detail_provider.dart';
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

Map<String, dynamic> _orderLetterJson({
  int id = 42,
  String status = 'Pending',
}) {
  return {
    'order_letter': {
      'id': id,
      'no_sp': 'SP-$id',
      'order_date': '2026-03-10',
      'request_date': '2026-03-15',
      'note': '',
      'customer_name': 'Customer $id',
      'phone': '081234567890',
      'address': 'Jl. Test No. $id',
      'email': 'c$id@test.com',
      'extended_amount': 1000000,
      'status': status,
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
    registerFallbackValue(<http.MultipartFile>[]);
    registerFallbackValue(<Object?, Object?>{});
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

  void mockDirectGetSuccess(int orderId, {String status = 'Pending'}) {
    when(() => mockApi.get('/order_letters/$orderId')).thenAnswer(
      (_) async =>
          http.Response(jsonEncode(_orderLetterJson(id: orderId, status: status)), 200),
    );
  }

  group('orderDetailProvider — build (fetch)', () {
    test('resolves OrderHistory when the direct GET succeeds', () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();

      final order = await container.read(orderDetailProvider(42).future);

      expect(order.id, 42);
      expect(order.noSp, 'SP-42');
    });

    test('throws when order is not found via direct GET or list fallback',
        () async {
      when(() => mockApi.get('/order_letters/99'))
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
        container.read(orderDetailProvider(99).future),
        throwsA(isA<Exception>()),
      );
    });

    test('401 on direct GET triggers logout + ApiSessionExpiredException',
        () async {
      when(() => mockApi.get('/order_letters/7'))
          .thenAnswer((_) async => http.Response('Unauthorized', 401));

      final container = buildContainer();

      await expectLater(
        container.read(orderDetailProvider(7).future),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });
  });

  group('orderDetailProvider — updateStatus', () {
    test('success updates status and refetches', () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();
      await container.read(orderDetailProvider(42).future);

      when(
        () => mockApi.put('/order_letters/42', body: any(named: 'body')),
      ).thenAnswer((_) async => http.Response('{}', 200));
      // Refresh after the update re-fetches — keep responding with
      // "Approved" so the assertion below reflects the new status.
      mockDirectGetSuccess(42, status: 'Approved');

      await container
          .read(orderDetailProvider(42).notifier)
          .updateStatus('Approved');

      final state = container.read(orderDetailProvider(42));
      expect(state.value?.status, 'Approved');
    });

    test('non-200/201 response throws with server error message', () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();
      await container.read(orderDetailProvider(42).future);

      when(
        () => mockApi.put('/order_letters/42', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'Ditolak'}), 422),
      );

      await expectLater(
        container.read(orderDetailProvider(42).notifier).updateStatus('X'),
        throwsA(
          isA<Exception>()
              .having((e) => e.toString(), 'message', contains('Ditolak')),
        ),
      );
    });

    test('401 triggers logout + ApiSessionExpiredException', () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();
      await container.read(orderDetailProvider(42).future);

      when(
        () => mockApi.put('/order_letters/42', body: any(named: 'body')),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      await expectLater(
        container.read(orderDetailProvider(42).notifier).updateStatus('X'),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });
  });

  group('orderDetailProvider — addAdditionalPayment', () {
    late File receiptFile;

    setUp(() {
      receiptFile = File(
        '${Directory.systemTemp.path}/order_detail_test_receipt.jpg',
      )..writeAsBytesSync([0, 1, 2, 3]);
    });

    tearDown(() {
      if (receiptFile.existsSync()) receiptFile.deleteSync();
    });

    test('success posts multipart with expected fields and refetches',
        () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();
      await container.read(orderDetailProvider(42).future);

      when(
        () => mockApi.postMultipart(
          '/order_letter_payments',
          fields: any(named: 'fields'),
          files: any(named: 'files'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 201));

      await container.read(orderDetailProvider(42).notifier).addAdditionalPayment(
            payload: {'amount': '500000', 'payment_method': 'Transfer'},
            receiptFile: receiptFile,
          );

      final captured = verify(
        () => mockApi.postMultipart(
          '/order_letter_payments',
          fields: captureAny(named: 'fields'),
          files: any(named: 'files'),
        ),
      ).captured;
      final fields = captured.single as Map<String, String>;
      expect(fields['order_letter_payment[order_letter_id]'], '42');
      expect(fields['order_letter_payment[amount]'], '500000');
      expect(fields['order_letter_payment[payment_method]'], 'Transfer');
    });

    test('401 triggers logout + ApiSessionExpiredException', () async {
      mockDirectGetSuccess(42);
      final container = buildContainer();
      await container.read(orderDetailProvider(42).future);

      when(
        () => mockApi.postMultipart(
          '/order_letter_payments',
          fields: any(named: 'fields'),
          files: any(named: 'files'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      await expectLater(
        container.read(orderDetailProvider(42).notifier).addAdditionalPayment(
              payload: {'amount': '1'},
              receiptFile: receiptFile,
            ),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });
  });
}
