import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:alitapricelist/features/indirect/data/models/assigned_store.dart';
import 'package:alitapricelist/features/indirect/data/services/indirect_store_discount_service.dart';
import 'package:alitapricelist/features/indirect/logic/indirect_session_provider.dart';

class MockDiscountService extends Mock
    implements IndirectStoreDiscountService {}

AssignedStore _store({required int addressNumber, String name = 'Toko'}) =>
    AssignedStore(
      addressNumber: addressNumber,
      alphaName: name,
      address: 'Jl. Test',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDiscountService mockService;
  late ProviderContainer container;

  setUp(() async {
    // AuthNotifier._init() reads SharedPreferences + secure storage on
    // construction — give it a non-empty access token (isLoggedIn: false so
    // the Firebase/FCM side-effect branch in _init() is skipped) so
    // IndirectSessionNotifier.selectStore() takes the fetch path.
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall call) async {
        if (call.method == 'read') return 'test-token';
        return null;
      },
    );

    mockService = MockDiscountService();
    container = ProviderContainer(
      overrides: [
        indirectSessionProvider.overrideWith(
          () => IndirectSessionNotifier(discountService: mockService),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Providers are lazily created on first read — force authProvider's
    // AuthNotifier to construct now so its constructor-triggered _init()
    // actually starts, then wait for it to finish loading the token.
    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  group('IndirectSessionNotifier.clear vs in-flight fetch', () {
    test('clear() while a fetch is in-flight prevents the stale fetch '
        'result from clobbering the cleared state', () async {
      final storeA = _store(addressNumber: 111, name: 'Toko A');
      final completer =
          Completer<({List<double> discounts, String discountCode})>();
      when(() => mockService.fetchDiscounts(
            token: any(named: 'token'),
            addressNumber: any(named: 'addressNumber'),
          )).thenAnswer((_) => completer.future);

      final notifier = container.read(indirectSessionProvider.notifier);
      final selectFuture = notifier.selectStore(storeA);

      // Fetch is now in-flight (not yet resolved) — clear the session
      // before it completes, simulating a mode switch / logout mid-fetch.
      notifier.clear();
      expect(container.read(indirectSessionProvider).hasStore, isFalse);

      // Now let the stale fetch resolve.
      completer.complete((discounts: [5.0, 3.0], discountCode: 'D1'));
      await selectFuture;

      final state = container.read(indirectSessionProvider);
      expect(state.hasStore, isFalse,
          reason: 'clear() must not be clobbered by a stale in-flight fetch');
      expect(state.hasDiscounts, isFalse);
    });

    test('selecting a new store while a fetch for the old store is '
        'in-flight still ignores the stale result (existing guard)', () async {
      final storeA = _store(addressNumber: 111, name: 'Toko A');
      final storeB = _store(addressNumber: 222, name: 'Toko B');
      final completerA =
          Completer<({List<double> discounts, String discountCode})>();
      final completerB =
          Completer<({List<double> discounts, String discountCode})>();

      when(() => mockService.fetchDiscounts(
            token: any(named: 'token'),
            addressNumber: any(named: 'addressNumber'),
          )).thenAnswer((invocation) {
        final addr = invocation.namedArguments[#addressNumber] as int;
        return addr == 111 ? completerA.future : completerB.future;
      });

      final notifier = container.read(indirectSessionProvider.notifier);
      final futureA = notifier.selectStore(storeA);
      final futureB = notifier.selectStore(storeB);

      completerB.complete((discounts: [2.0], discountCode: 'DB'));
      await futureB;
      // Stale completion for A arrives after B already won.
      completerA.complete((discounts: [9.0], discountCode: 'DA'));
      await futureA;

      final state = container.read(indirectSessionProvider);
      expect(state.selectedStore?.addressNumber, 222);
      expect(state.discountCode, 'DB');
    });
  });
}
