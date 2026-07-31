import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart';

/// Regression test proving that switching `product_detail_from_link_page.dart`
/// from a manual `productsAsync.isLoading` check to `AsyncValue.when()`
/// (mandated by project rules) does not change which screen gets rendered
/// for any reachable [AsyncValue] state, crossed with whether the requested
/// product id exists in the resolved list.
enum _Branch { loadingScreen, notFoundScreen, productDetail }

Product _product(String id) => Product(
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

_Branch _oldLogic(
  AsyncValue<ProductListLoadResult> state,
  String productId,
) {
  final products = state.valueOrNull?.products ?? const <Product>[];
  final found = products.where((p) => p.id == productId).firstOrNull;

  if (state.isLoading && products.isEmpty) return _Branch.loadingScreen;
  if (found == null) return _Branch.notFoundScreen;
  return _Branch.productDetail;
}

_Branch _newLogic(
  AsyncValue<ProductListLoadResult> state,
  String productId,
) {
  _Branch resolve(List<Product> products) {
    final found = products.where((p) => p.id == productId).firstOrNull;
    return found == null ? _Branch.notFoundScreen : _Branch.productDetail;
  }

  return state.when(
    skipError: true,
    loading: () => _Branch.loadingScreen,
    error: (_, __) => resolve(const []),
    data: (result) => resolve(result.products),
  );
}

void main() {
  final withP1 = ProductListLoadResult(products: [_product('p1')]);

  final states = <String, AsyncValue<ProductListLoadResult>>{
    'initial loading, no value': const AsyncValue.loading(),
    'reload while switching filters, has stale value':
        const AsyncValue<ProductListLoadResult>.loading()
            .copyWithPrevious(AsyncValue.data(withP1)),
    'initial error, no value':
        AsyncValue.error(Exception('boom'), StackTrace.empty),
    'error after reload, has stale value': AsyncValue<ProductListLoadResult>
        .error(Exception('boom'), StackTrace.empty)
        .copyWithPrevious(AsyncValue.data(withP1)),
    'has data, product present': AsyncValue.data(withP1),
    'has data, product absent':
        AsyncValue.data(const ProductListLoadResult(products: [])),
  };

  group('product_detail_from_link_page branch selection', () {
    for (final entry in states.entries) {
      test('${entry.key}: old manual-check and new .when() logic agree', () {
        expect(_newLogic(entry.value, 'p1'), _oldLogic(entry.value, 'p1'));
      });
    }

    test('sanity: shows loading only for a genuine first load', () {
      expect(
        _oldLogic(states['initial loading, no value']!, 'p1'),
        _Branch.loadingScreen,
      );
    });

    test('sanity: keeps stale product list visible while reloading', () {
      expect(
        _oldLogic(
          states['reload while switching filters, has stale value']!,
          'p1',
        ),
        _Branch.productDetail,
      );
    });
  });
}
