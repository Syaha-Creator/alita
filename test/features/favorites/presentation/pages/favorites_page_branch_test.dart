import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart';

/// Regression test for `favorites_page.dart`'s body branch selection.
///
/// The old code combined `productsAsync.isLoading`/`.hasError` with
/// `favoriteProducts.isEmpty` into a single flag — conflating "no product
/// data has ever loaded" with "user simply has zero favorites". That bug
/// made the page flash a loading skeleton (or error screen) on every
/// background catalog reload/error whenever the user had no favorites,
/// even though favorites don't depend on a fresh fetch succeeding.
///
/// [_resolveBranch] is the corrected logic (uses `AsyncValue.when()`, the
/// project-mandated structured API): loading/error screens are reserved for
/// a genuine first load with no cached data at all; once any product data
/// has ever loaded (fresh or stale), whether to show the grid or the empty
/// state depends purely on the favorites list.
enum _Branch { loadingSkeleton, errorState, emptyState, grid }

_Branch _resolveBranch(
  AsyncValue<ProductListLoadResult> productsAsync,
  List<Product> favoriteProducts,
) {
  return productsAsync.when(
    skipError: true,
    loading: () =>
        favoriteProducts.isEmpty ? _Branch.loadingSkeleton : _Branch.grid,
    error: (_, __) =>
        favoriteProducts.isEmpty ? _Branch.errorState : _Branch.grid,
    data: (_) => favoriteProducts.isEmpty ? _Branch.emptyState : _Branch.grid,
  );
}

void main() {
  Product product(String id) => Product(
        id: id,
        name: 'Produk $id',
        price: 1000000,
        imageUrl: 'https://example.com/$id.png',
        category: 'kasur',
        kasur: 'Kasur $id',
        ukuran: '160x200',
        divan: '-',
        headboard: '-',
        sorong: '-',
        isSet: false,
        pricelist: 1000000,
        eupKasur: 1000000,
        eupDivan: 0,
        eupHeadboard: 0,
        eupSorong: 0,
        plKasur: 1000000,
        plDivan: 0,
        plHeadboard: 0,
        plSorong: 0,
      );

  final withData =
      ProductListLoadResult(products: [product('p1'), product('p2')]);
  final favorited = [product('p1')];

  group('favorites_page branch selection', () {
    test('first load, no data yet -> loading skeleton', () {
      expect(
        _resolveBranch(const AsyncValue.loading(), const []),
        _Branch.loadingSkeleton,
      );
    });

    test('first load fails, no data yet -> error state', () {
      expect(
        _resolveBranch(
          AsyncValue.error(Exception('boom'), StackTrace.empty),
          const [],
        ),
        _Branch.errorState,
      );
    });

    test('has data, user has favorites -> grid', () {
      expect(
        _resolveBranch(AsyncValue.data(withData), favorited),
        _Branch.grid,
      );
    });

    test('has data, user has zero favorites -> empty state', () {
      expect(
        _resolveBranch(AsyncValue.data(withData), const []),
        _Branch.emptyState,
      );
    });

    test(
      'bug fix: background reload with cached data + zero favorites shows '
      'empty state, not a loading flash',
      () {
        final reloading = const AsyncValue<ProductListLoadResult>.loading()
            .copyWithPrevious(AsyncValue.data(withData));

        expect(_resolveBranch(reloading, const []), _Branch.emptyState);
      },
    );

    test(
      'bug fix: background reload failure with cached data + zero favorites '
      'shows empty state, not an error screen',
      () {
        final erroring = AsyncValue<ProductListLoadResult>.error(
          Exception('boom'),
          StackTrace.empty,
        ).copyWithPrevious(AsyncValue.data(withData));

        expect(_resolveBranch(erroring, const []), _Branch.emptyState);
      },
    );

    test('background reload with cached data + favorites still shows grid', () {
      final reloading = const AsyncValue<ProductListLoadResult>.loading()
          .copyWithPrevious(AsyncValue.data(withData));

      expect(_resolveBranch(reloading, favorited), _Branch.grid);
    });

    test(
      'edge case: favorites resolved independently of productsAsync (e.g. '
      'test overrides) still shows the grid during a first load instead of '
      'a skeleton',
      () {
        expect(
          _resolveBranch(const AsyncValue.loading(), favorited),
          _Branch.grid,
        );
      },
    );
  });
}
