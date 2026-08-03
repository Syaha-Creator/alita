import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';
import 'package:alitapricelist/features/profile/logic/profile_provider.dart';
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

Map<String, dynamic> _cweResponse({
  int userId = 7,
  String name = 'Tester',
  String workTitle = 'Analis',
}) {
  return {
    'result': [
      {
        'user': {'id': userId, 'name': name, 'email': 'tester@test.com'},
        'work_title': workTitle,
        'work_place': {'name': 'HQ'},
        'area': {'id': 3, 'name': 'Jakarta'},
        'company': {'id': 2},
        'divisions': <dynamic>[],
      },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(const Duration(seconds: 15));
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

  ProviderContainer buildContainer({int userId = 7}) {
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

  group('profileProvider', () {
    test('returns null when userId is 0 (not logged in)', () async {
      final container = buildContainer(userId: 0);

      final profile = await container.read(profileProvider.future);

      expect(profile, isNull);
      verifyNever(() => mockApi.get(any(), queryParams: any(named: 'queryParams'), timeout: any(named: 'timeout')));
    });

    test('fetches and parses the profile, using userId as query param',
        () async {
      when(
        () => mockApi.get(
          '/contact_work_experiences',
          queryParams: {'user_id': '7'},
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(_cweResponse()), 200),
      );

      final container = buildContainer();
      final profile = await container.read(profileProvider.future);

      expect(profile, isNotNull);
      expect(profile!.id, 7);
      expect(profile.name, 'Tester');
      expect(profile.workTitle, 'Analis');
      expect(profile.areaId, 3);
    });

    test('returns null on empty result list', () async {
      when(
        () => mockApi.get(
          '/contact_work_experiences',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': <dynamic>[]}), 200),
      );

      final container = buildContainer();
      final profile = await container.read(profileProvider.future);

      expect(profile, isNull);
    });

    test('returns null (does not throw) on 5xx server error', () async {
      when(
        () => mockApi.get(
          '/contact_work_experiences',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response('Server error', 503));

      final container = buildContainer();
      final profile = await container.read(profileProvider.future);

      expect(profile, isNull);
    });

    test('throws on non-200/non-5xx response', () async {
      when(
        () => mockApi.get(
          '/contact_work_experiences',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response('Not found', 404));

      final container = buildContainer();

      await expectLater(
        container.read(profileProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on malformed response body', () async {
      when(
        () => mockApi.get(
          '/contact_work_experiences',
          queryParams: any(named: 'queryParams'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response('not json', 200));

      final container = buildContainer();

      await expectLater(
        container.read(profileProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });
}
