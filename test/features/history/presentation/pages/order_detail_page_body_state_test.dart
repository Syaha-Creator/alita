import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/history/data/models/order_history.dart';

/// Regression test proving that switching `order_detail_page.dart`'s body
/// from manual `isLoading`/`hasError`/`hasValue` checks to `AsyncValue.when()`
/// (Riverpod's structured API, mandated by project rules) does not change
/// which body branch gets rendered for any reachable [AsyncValue] state.
///
/// The page intentionally favors showing stale data over flashing a
/// skeleton/error whenever a value is already cached (stale-while-revalidate)
/// — this test locks in that behavior across the refactor.
enum _Branch { skeleton, error, content }

_Branch _oldLogic(AsyncValue<OrderHistory> state) {
  if (state.isLoading && !state.hasValue) return _Branch.skeleton;
  if (state.hasError && !state.hasValue) return _Branch.error;
  return _Branch.content;
}

_Branch _newLogic(AsyncValue<OrderHistory> state) {
  return state.when(
    skipError: true, // stale-while-revalidate: keep showing cached data
    loading: () => _Branch.skeleton,
    error: (_, __) => _Branch.error,
    data: (_) => _Branch.content,
  );
}

void main() {
  final fakeOrder = OrderHistory.fromApiJson(const {
    'id': 1,
    'no_sp': 'SP-1',
    'status': 'pending',
  });

  final states = <String, AsyncValue<OrderHistory>>{
    'initial loading, no value': const AsyncValue.loading(),
    'loading while refreshing, has stale value':
        const AsyncValue<OrderHistory>.loading()
            .copyWithPrevious(AsyncValue.data(fakeOrder)),
    'initial error, no value': AsyncValue.error(Exception('boom'), StackTrace.empty),
    'error after refresh, has stale value': AsyncValue<OrderHistory>.error(
      Exception('boom'),
      StackTrace.empty,
    ).copyWithPrevious(AsyncValue.data(fakeOrder)),
    'has data': AsyncValue.data(fakeOrder),
  };

  group('order_detail_page body branch selection', () {
    for (final entry in states.entries) {
      test(
        '${entry.key}: old manual-check logic and new .when() logic agree',
        () {
          expect(_newLogic(entry.value), _oldLogic(entry.value));
        },
      );
    }

    test('sanity: skeleton only for a genuinely-first load', () {
      expect(_oldLogic(states['initial loading, no value']!), _Branch.skeleton);
    });

    test('sanity: error only for a first-load failure with no cached data',
        () {
      expect(_oldLogic(states['initial error, no value']!), _Branch.error);
    });

    test('sanity: stale-while-revalidate keeps content on refresh loading',
        () {
      expect(
        _oldLogic(states['loading while refreshing, has stale value']!),
        _Branch.content,
      );
    });

    test('sanity: stale-while-revalidate keeps content on refresh error', () {
      expect(
        _oldLogic(states['error after refresh, has stale value']!),
        _Branch.content,
      );
    });
  });
}
