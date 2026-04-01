import 'dart:convert';

import 'package:alitapricelist/core/services/api_client.dart';
import 'package:alitapricelist/core/services/api_session_expired.dart';
import 'package:alitapricelist/core/utils/app_formatters.dart';
import 'package:alitapricelist/features/approval/logic/approval_inbox_provider.dart';
import 'package:alitapricelist/features/profile/data/models/user_profile.dart';
import 'package:alitapricelist/features/profile/logic/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

const _apiTimeout = Duration(seconds: 30);

UserProfile _testProfile({int id = 7}) {
  return UserProfile(
    id: id,
    name: 'Tester',
    email: 'tester@example.com',
    workTitle: 'Staff',
    workPlaceName: 'HQ',
    areaName: 'Jakarta',
  );
}

/// Single pending approval for [userId] (actionable at first discount slot).
Map<String, dynamic> _wrapPending({
  required int orderLetterId,
  required int userId,
  required String createdAt,
  String workPlace = 'Toko Alpha',
}) {
  return {
    'work_place_name': workPlace,
    'order_letter': {
      'id': orderLetterId,
      'status': 'Pending',
      'created_at': createdAt,
    },
    'order_letter_details': [
      {
        'order_letter_discount': [
          {
            'approver_id': userId.toString(),
            'approved': 'Pending',
          },
        ],
      },
    ],
  };
}

/// History entry: current user already approved their discount line.
Map<String, dynamic> _wrapHistoryApproved({
  required int orderLetterId,
  required int userId,
  required String createdAt,
  String workPlace = 'Toko Beta',
}) {
  return {
    'work_place_name': workPlace,
    'order_letter': {
      'id': orderLetterId,
      'status': 'Pending',
      'created_at': createdAt,
    },
    'order_letter_details': [
      {
        'order_letter_discount': [
          {
            'approver_id': userId.toString(),
            'approved': 'Approved',
          },
        ],
      },
    ],
  };
}

Future<void> _waitUntilNotLoading(ProviderContainer container) async {
  for (var i = 0; i < 200; i++) {
    if (!container.read(approvalInboxProvider).isLoading) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('approvalInboxProvider stayed loading');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;

  setUpAll(() {
    registerFallbackValue(<String, String>{});
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockApi = MockApiClient();
  });

  group('ApprovalInboxNotifier — initial state', () {
    test('initial fetch runs when skipInitialFetch is false', () async {
      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': []}), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: 2)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _waitUntilNotLoading(container);
      expect(container.read(approvalInboxProvider).isLoading, false);
      verify(
        () => mockApi.get(
          '/order_letter_approvals',
          queryParams: {'user_id': '2'},
          token: null,
          timeout: _apiTimeout,
        ),
      ).called(1);
    });

    test('skipInitialFetch keeps default state (loading, empty, no error)', () {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final s = container.read(approvalInboxProvider);
      expect(s.isLoading, true);
      expect(s.error, isNull);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, isEmpty);
      expect(s.startDate, isNull);
      expect(s.endDate, isNull);
      expect(s.historyWorkPlaceFilter, isNull);

      verifyNever(() => mockApi.get(any()));
    });
  });

  group('ApprovalInboxNotifier — fetch', () {
    test('success: fills pending and history, clears loading and error', () async {
      const userId = 7;
      final body = {
        'result': [
          _wrapPending(
            orderLetterId: 101,
            userId: userId,
            createdAt: '2026-03-20T10:00:00.000Z',
            workPlace: 'Toko Alpha',
          ),
          _wrapHistoryApproved(
            orderLetterId: 102,
            userId: userId,
            createdAt: '2026-03-19T10:00:00.000Z',
            workPlace: 'Toko Beta',
          ),
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.isLoading, false);
      expect(s.error, isNull);
      expect(s.pendingApprovals, hasLength(1));
      expect(s.historyApprovals, hasLength(1));
      expect(
        approvalOrderWrapWorkPlace(s.pendingApprovals.first),
        'Toko Alpha',
      );
      expect(
        approvalOrderWrapWorkPlace(s.historyApprovals.first),
        'Toko Beta',
      );

      verify(
        () => mockApi.get(
          '/order_letter_approvals',
          queryParams: {'user_id': '$userId'},
          token: null,
          timeout: _apiTimeout,
        ),
      ).called(1);
    });

    test('network error: retry twice then error state, lists empty', () async {
      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenThrow(Exception('offline'));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.isLoading, false);
      expect(s.error, contains('offline'));
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, isEmpty);

      verify(
        () => mockApi.get(
          '/order_letter_approvals',
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).called(2);
    });

    test('malformed JSON on 200 surfaces error in state', () async {
      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('not-json', 200));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.isLoading, false);
      expect(s.error, isNotNull);
    });

    test('non-200 (500): error message, not loading', () async {
      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('err', 500));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.isLoading, false);
      expect(s.error, contains('500'));
    });

    test('skips non-map items and invalid wraps; groups duplicate letter id', () async {
      const userId = 7;
      final body = {
        'result': [
          'not-a-map',
          {
            'order_letter': 'bad-type',
            'order_letter_details': <dynamic>[],
          },
          _wrapPending(
            orderLetterId: 301,
            userId: userId,
            createdAt: '2026-04-01T12:00:00.000Z',
          ),
          {
            'order_letter': {
              'id': 301,
              'status': 'Pending',
              'created_at': '2026-04-01T11:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '$userId', 'approved': 'Pending'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      expect(container.read(approvalInboxProvider).pendingApprovals, hasLength(1));
    });

    test('rejected discount moves row to history', () async {
      const userId = 13;
      final body = {
        'result': [
          {
            'work_place_name': 'Toko X',
            'order_letter': {
              'id': 602,
              'status': 'Pending',
              'created_at': '2026-06-01T09:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '$userId', 'approved': 'Rejected'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, hasLength(1));
    });

    test('orders without current user as approver are omitted', () async {
      const userId = 77;
      final body = {
        'result': [
          {
            'order_letter': {
              'id': 701,
              'status': 'Pending',
              'created_at': '2026-07-01T08:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '999', 'approved': 'Pending'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, isEmpty);
    });

    test('user pending discount is ignored when a prior discount is not approved',
        () async {
      const userId = 90;
      final body = {
        'result': [
          {
            'order_letter': {
              'id': 901,
              'status': 'Pending',
              'created_at': '2026-09-10T08:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '1', 'approved': 'Pending'},
                  {'approver_id': '$userId', 'approved': 'Pending'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, isEmpty);
    });

    test('second discount pending is actionable when prior line approved', () async {
      const userId = 88;
      final body = {
        'result': [
          {
            'order_letter': {
              'id': 801,
              'status': 'Pending',
              'created_at': '2026-08-01T08:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '1', 'approved': 'Approved'},
                  {'approver_id': '$userId', 'approved': 'Pending'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      expect(
        container.read(approvalInboxProvider).pendingApprovals,
        hasLength(1),
      );
    });

    test('header Rejected is classified as history', () async {
      const userId = 11;
      final body = {
        'result': [
          {
            'work_place_name': 'Toko R',
            'order_letter': {
              'id': 401,
              'status': 'Rejected',
              'created_at': '2026-05-01T08:00:00.000Z',
            },
            'order_letter_details': [
              {
                'order_letter_discount': [
                  {'approver_id': '$userId', 'approved': 'Pending'},
                ],
              },
            ],
          },
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.pendingApprovals, isEmpty);
      expect(s.historyApprovals, hasLength(1));
    });
  });

  group('ApprovalInboxNotifier — date filter', () {
    test('updateDateFilter sends api dates and refetches', () async {
      final start = DateTime.utc(2026, 2, 1);
      final end = DateTime.utc(2026, 2, 28);

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': []}), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: 9)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(approvalInboxProvider.notifier).updateDateFilter(start, end);
      await _waitUntilNotLoading(container);

      final s = container.read(approvalInboxProvider);
      expect(s.startDate, start);
      expect(s.endDate, end);

      verify(
        () => mockApi.get(
          '/order_letter_approvals',
          queryParams: {
            'user_id': '9',
            'start_date': AppFormatters.apiDate(start),
            'end_date': AppFormatters.apiDate(end),
          },
          token: null,
          timeout: _apiTimeout,
        ),
      ).called(1);
    });

    test('clearDateFilter clears dates then refetches without range', () async {
      final start = DateTime.utc(2026, 3, 1);
      final end = DateTime.utc(2026, 3, 31);

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': []}), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: 3)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(approvalInboxProvider.notifier).updateDateFilter(start, end);
      await _waitUntilNotLoading(container);

      reset(mockApi);
      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'result': []}), 200),
      );

      container.read(approvalInboxProvider.notifier).clearDateFilter();

      final afterClear = container.read(approvalInboxProvider);
      expect(afterClear.startDate, isNull);
      expect(afterClear.endDate, isNull);

      await _waitUntilNotLoading(container);

      verify(
        () => mockApi.get(
          '/order_letter_approvals',
          queryParams: {'user_id': '3'},
          token: null,
          timeout: _apiTimeout,
        ),
      ).called(1);
    });
  });

  group('ApprovalInboxNotifier — work place filter', () {
    test('setHistoryWorkPlaceFilter narrows filteredHistoryApprovals', () async {
      const userId = 5;
      final body = {
        'result': [
          _wrapHistoryApproved(
            orderLetterId: 201,
            userId: userId,
            createdAt: '2026-01-02T00:00:00.000Z',
            workPlace: 'Store North',
          ),
          _wrapHistoryApproved(
            orderLetterId: 202,
            userId: userId,
            createdAt: '2026-01-01T00:00:00.000Z',
            workPlace: 'Store South',
          ),
        ],
      };

      when(
        () => mockApi.get(
          any(),
          queryParams: any(named: 'queryParams'),
          token: null,
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(body), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile(id: userId)),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(approvalInboxProvider.notifier).fetchInbox();
      await _waitUntilNotLoading(container);

      final notifier = container.read(approvalInboxProvider.notifier);
      notifier.setHistoryWorkPlaceFilter('Store South');

      final s = container.read(approvalInboxProvider);
      expect(s.historyWorkPlaceFilter, 'Store South');
      expect(s.historyApprovals, hasLength(2));
      expect(s.filteredHistoryApprovals, hasLength(1));
      expect(
        approvalOrderWrapWorkPlace(s.filteredHistoryApprovals.single),
        'Store South',
      );
      expect(s.historyWorkPlaceOptions, ['Store North', 'Store South']);

      notifier.setHistoryWorkPlaceFilter(null);
      expect(
        container.read(approvalInboxProvider).filteredHistoryApprovals,
        hasLength(2),
      );
    });
  });

  group('ApprovalInboxNotifier — order letter helpers', () {
    test('updateOrderLetterStatus succeeds on 200', () async {
      when(
        () => mockApi.put(
          any(),
          token: null,
          queryParams: any(named: 'queryParams'),
          body: any(named: 'body'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('', 200));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(approvalInboxProvider.notifier)
          .updateOrderLetterStatus(99, 'Approved');

      verify(
        () => mockApi.put(
          '/order_letters/99',
          token: null,
          queryParams: any(named: 'queryParams'),
          body: {'status': 'Approved'},
          timeout: _apiTimeout,
        ),
      ).called(1);
    });

    test('updateOrderLetterStatus accepts 201', () async {
      when(
        () => mockApi.put(
          any(),
          token: null,
          queryParams: any(named: 'queryParams'),
          body: any(named: 'body'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('', 201));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(approvalInboxProvider.notifier)
          .updateOrderLetterStatus(12, 'Pending');
    });

    test('updateOrderLetterStatus throws on non-auth error status', () async {
      when(
        () => mockApi.put(
          any(),
          token: null,
          queryParams: any(named: 'queryParams'),
          body: any(named: 'body'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('fail', 422));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(approvalInboxProvider.notifier)
            .updateOrderLetterStatus(12, 'Pending'),
        throwsException,
      );
    });

    test('updateOrderLetterStatus throws ApiSessionExpiredException on 403',
        () async {
      when(
        () => mockApi.put(
          any(),
          token: null,
          queryParams: any(named: 'queryParams'),
          body: any(named: 'body'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('nope', 403));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(approvalInboxProvider.notifier)
            .updateOrderLetterStatus(1, 'Rejected'),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });

    test('updateOrderLetterStatus throws ApiSessionExpiredException on 401',
        () async {
      when(
        () => mockApi.put(
          any(),
          token: null,
          queryParams: any(named: 'queryParams'),
          body: any(named: 'body'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('nope', 401));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(approvalInboxProvider.notifier)
            .updateOrderLetterStatus(1, 'Rejected'),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });

    test('isAllDiscountsApproved returns false when a discount is not approved',
        () async {
      final detailBody = {
        'result': {
          'order_letter_details': [
            {
              'order_letter_discount': [
                {'approved': 'Approved'},
                {'approved': 'Pending'},
              ],
            },
          ],
        },
      };

      when(
        () => mockApi.get(
          '/order_letters/504',
          token: null,
          queryParams: any(named: 'queryParams'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(detailBody), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(approvalInboxProvider.notifier)
          .isAllDiscountsApproved(504);
      expect(ok, false);
    });

    test('isAllDiscountsApproved returns true when every discount approved',
        () async {
      final detailBody = {
        'result': {
          'order_letter_details': [
            {
              'order_letter_discount': [
                {'approved': 'Approved'},
                {'approved': true},
              ],
            },
          ],
        },
      };

      when(
        () => mockApi.get(
          '/order_letters/500',
          token: null,
          queryParams: any(named: 'queryParams'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(detailBody), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(approvalInboxProvider.notifier)
          .isAllDiscountsApproved(500);
      expect(ok, true);
    });

    test('isAllDiscountsApproved throws ApiSessionExpiredException on 403',
        () async {
      when(
        () => mockApi.get(
          '/order_letters/502',
          token: null,
          queryParams: any(named: 'queryParams'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('forbidden', 403));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(approvalInboxProvider.notifier)
            .isAllDiscountsApproved(502),
        throwsA(isA<ApiSessionExpiredException>()),
      );
    });

    test('isAllDiscountsApproved throws when GET not successful', () async {
      when(
        () => mockApi.get(
          '/order_letters/503',
          token: null,
          queryParams: any(named: 'queryParams'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer((_) async => http.Response('x', 404));

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(approvalInboxProvider.notifier)
            .isAllDiscountsApproved(503),
        throwsException,
      );
    });

    test('isAllDiscountsApproved returns false when no discounts', () async {
      final detailBody = {
        'result': {
          'order_letter_details': [
            {'order_letter_discount': <dynamic>[]},
          ],
        },
      };

      when(
        () => mockApi.get(
          '/order_letters/501',
          token: null,
          queryParams: any(named: 'queryParams'),
          timeout: _apiTimeout,
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(detailBody), 200),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith((ref) async => _testProfile()),
          approvalInboxProvider.overrideWith(
            (ref) => ApprovalInboxNotifier(
              ref,
              apiClient: mockApi,
              skipInitialFetch: true,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ok = await container
          .read(approvalInboxProvider.notifier)
          .isAllDiscountsApproved(501);
      expect(ok, false);
    });
  });

  group('ApprovalLocation', () {
    test('holds address and coordinates', () {
      const loc = ApprovalLocation(
        address: 'Jl. Contoh',
        latitude: -6.1,
        longitude: 106.2,
      );
      expect(loc.address, 'Jl. Contoh');
      expect(loc.latitude, -6.1);
      expect(loc.longitude, 106.2);
    });
  });

  group('formatPlacemarkAddressForApproval', () {
    test('prefers street when non-empty', () {
      const p = Placemark(
        street: 'Jl. Sudirman',
        thoroughfare: 'Ignored',
        locality: 'Jakarta',
      );
      expect(
        formatPlacemarkAddressForApproval(p),
        'Jl. Sudirman, Jakarta',
      );
    });

    test('builds line1 from subThoroughfare and thoroughfare when street empty',
        () {
      const p = Placemark(
        subThoroughfare: '12',
        thoroughfare: 'Gang Mawar',
        locality: 'Bandung',
      );
      expect(
        formatPlacemarkAddressForApproval(p),
        '12 Gang Mawar, Bandung',
      );
    });

    test('prefixes Kecamatan when subAdministrativeArea has no keyword', () {
      const p = Placemark(
        street: 'Jl. A',
        subAdministrativeArea: 'Menteng',
        locality: 'Jakarta Pusat',
      );
      final s = formatPlacemarkAddressForApproval(p);
      expect(s, contains('Kecamatan Menteng'));
      expect(s, contains('Jakarta Pusat'));
    });

    test('does not double-prefix Kecamatan', () {
      const p = Placemark(
        street: 'Jl. B',
        subAdministrativeArea: 'Kecamatan Senen',
      );
      expect(
        formatPlacemarkAddressForApproval(p),
        contains('Kecamatan Senen'),
      );
    });

    test('uses thoroughfare alone when subThoroughfare empty', () {
      const p = Placemark(
        thoroughfare: 'Jalan Raya',
        locality: 'Surabaya',
      );
      expect(
        formatPlacemarkAddressForApproval(p),
        'Jalan Raya, Surabaya',
      );
    });

    test('falls back to name when street and thoroughfare empty', () {
      const p = Placemark(
        name: 'POI Gedung',
        locality: 'Medan',
      );
      expect(
        formatPlacemarkAddressForApproval(p),
        'POI Gedung, Medan',
      );
    });
  });

  group('approvalOrderWrapWorkPlace (pure)', () {
    test('reads nested order_letter work_place_name', () {
      final wrap = {
        'order_letter': {'work_place_name': 'Nested WP'},
      };
      expect(approvalOrderWrapWorkPlace(wrap), 'Nested WP');
    });

    test('reads top-level workplace_name', () {
      final wrap = {'workplace_name': '  Top WP  '};
      expect(approvalOrderWrapWorkPlace(wrap), 'Top WP');
    });

    test('non-map returns empty', () {
      expect(approvalOrderWrapWorkPlace(Object()), '');
    });

    test('reads order_letter work_place fallback', () {
      final wrap = {
        'order_letter': {'work_place': 'Plant Line'},
      };
      expect(approvalOrderWrapWorkPlace(wrap), 'Plant Line');
    });

    test('prefers work_place_name over order_letter work_place', () {
      final wrap = {
        'work_place_name': 'Outer',
        'order_letter': {'work_place': 'Inner'},
      };
      expect(approvalOrderWrapWorkPlace(wrap), 'Outer');
    });
  });

  group('approvalHistoryWorkPlaceOptions / approvalHistoryFilteredByWorkPlace',
      () {
    test('options are sorted case-insensitively', () {
      final history = <dynamic>[
        {'work_place_name': 'Beta'},
        {'work_place_name': 'alpha'},
      ];
      expect(
        approvalHistoryWorkPlaceOptions(history),
        ['alpha', 'Beta'],
      );
    });

    test('filtered list empty filter returns full history', () {
      final history = <dynamic>[
        {'work_place_name': 'A'},
      ];
      expect(approvalHistoryFilteredByWorkPlace(history, null), history);
      expect(approvalHistoryFilteredByWorkPlace(history, ''), history);
    });

    test('filtered list keeps only matching work place', () {
      final history = <dynamic>[
        {'work_place_name': 'One'},
        {'work_place_name': 'Two'},
      ];
      final out = approvalHistoryFilteredByWorkPlace(history, 'Two');
      expect(out, hasLength(1));
      expect(approvalOrderWrapWorkPlace(out.single), 'Two');
    });
  });
}
