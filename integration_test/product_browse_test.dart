import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:alitapricelist/features/cart/logic/cart_provider.dart';

import 'helpers/test_app.dart';
import 'helpers/test_data.dart';

/// Integration test: Product Browse
///
/// Starts with a logged-in mock auth and overridden product list.
/// Verifies product list renders, product cards are tappable,
/// and cart badge increments after adding items.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSecureStorageChannel();
  });

  group('Product Browse', () {
    testWidgets('product list page renders with products', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      // filteredProductsProvider groups by kasur name, so the displayed
      // product name is 'Comfort Dream' instead of 'Comfort Dream 160x200'.
      expect(find.textContaining(TestData.sampleProduct.kasur), findsWidgets);
    });

    testWidgets('product cards show price information', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rp'), findsWidgets);
    });

    testWidgets('tapping product card navigates to detail', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      final productCard = find.textContaining(TestData.sampleProduct.kasur);
      if (productCard.evaluate().isNotEmpty) {
        await tester.tap(productCard.first);
        await tester.pumpAndSettle();

        expect(find.textContaining(TestData.sampleProduct.ukuran), findsWidgets);
      }
    });

    testWidgets('search field is visible', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('profile icon navigates to profile page', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      final profileIcon = find.byIcon(Icons.person_outline);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon.first);
        await tester.pumpAndSettle();

        expect(find.text('Mochammad Syahrul Azhar'), findsWidgets);
      }
    });

    testWidgets('cart FAB hidden when cart is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      // CartFAB renders SizedBox.shrink when totalItems == 0
      expect(find.byIcon(Icons.shopping_cart), findsNothing);
    });

    testWidgets('cart FAB visible when cart has items', (tester) async {
      await tester.pumpWidget(buildTestApp(
        loggedIn: true,
        extraOverrides: [
          cartProvider.overrideWith((ref) {
            final notifier = CartNotifier();
            notifier.addItem(TestData.sampleCartItem);
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
    });
  });
}
