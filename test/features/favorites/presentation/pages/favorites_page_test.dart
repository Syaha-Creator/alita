import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alitapricelist/core/services/connectivity_service.dart';
import 'package:alitapricelist/features/favorites/logic/favorites_provider.dart';
import 'package:alitapricelist/features/favorites/presentation/pages/favorites_page.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_provider.dart';
import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';

/// Regression test for the responsive favorites grid: verifies the real
/// [SliverMasonryGrid] rendered by [FavoritesPage] resolves the column count
/// from `AppLayoutTokens.gridColumnCountForWidth` at phone/tablet/desktop
/// widths, so a future revert to a hardcoded `crossAxisCount` fails loudly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pins the test surface to [size] at devicePixelRatio 1 and restores the
  /// default surface after the test so other tests aren't affected.
  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  int renderedCrossAxisCount(WidgetTester tester) {
    final grid =
        tester.widget<SliverMasonryGrid>(find.byType(SliverMasonryGrid));
    final delegate =
        grid.gridDelegate as SliverSimpleGridDelegateWithFixedCrossAxisCount;
    return delegate.crossAxisCount;
  }

  Product fakeProduct(String id) => Product(
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

  Future<void> pumpFavoritesPage(
    WidgetTester tester, {
    required Size screenSize,
    required List<Product> favorites,
  }) async {
    setScreenSize(tester, screenSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Bypass network/master-data providers — only the grid layout is
          // under test here, not product fetching.
          productListProvider.overrideWith(
            (ref) async => const ProductListLoadResult(products: []),
          ),
          favoriteProductsProvider.overrideWith((ref) => favorites),
          isOfflineProvider.overrideWith((ref) => false),
          brandSpecProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: FavoritesPage()),
      ),
    );
    await tester.pump();
    // Drain AnimatedListItem's staggered entrance timers/animations so no
    // pending Timer trips the test framework's post-test invariant check.
    await tester.pump(const Duration(seconds: 1));
  }

  group('FavoritesPage responsive grid', () {
    final favorites = List.generate(6, (i) => fakeProduct('p$i'));

    testWidgets('renders 2 columns on phone-sized screens', (tester) async {
      await pumpFavoritesPage(
        tester,
        screenSize: const Size(360, 800),
        favorites: favorites,
      );

      expect(renderedCrossAxisCount(tester), 2);
    });

    testWidgets('renders 3 columns on tablet-sized screens', (tester) async {
      await pumpFavoritesPage(
        tester,
        screenSize: const Size(700, 1000),
        favorites: favorites,
      );

      expect(renderedCrossAxisCount(tester), 3);
    });

    testWidgets('renders 4 columns on desktop/large-tablet screens',
        (tester) async {
      await pumpFavoritesPage(
        tester,
        screenSize: const Size(1000, 800),
        favorites: favorites,
      );

      expect(renderedCrossAxisCount(tester), 4);
    });
  });
}
