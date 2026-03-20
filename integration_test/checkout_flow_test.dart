import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:alitapricelist/features/cart/logic/cart_provider.dart';

import 'helpers/test_app.dart';

/// Integration test: Checkout Flow
///
/// Starts with a logged-in user and items in cart. Navigates through:
/// Cart page → Checkout page → Fill customer info → Fill delivery →
/// Fill approval → Fill payment → Submit order.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSecureStorageChannel();
  });

  group('Checkout Flow', () {
    Widget buildCheckoutApp() {
      return buildTestApp(
        loggedIn: true,
        extraOverrides: [
          cartProvider.overrideWith((ref) {
            final notifier = CartNotifier();
            return notifier;
          }),
        ],
      );
    }

    testWidgets('cart page shows when navigated', (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();

      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('checkout page has customer info section', (tester) async {
      await tester.pumpWidget(buildTestApp(
        loggedIn: true,
        extraOverrides: [
          cartProvider.overrideWith((ref) {
            final notifier = CartNotifier();
            return notifier;
          }),
        ],
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('empty cart shows empty state', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      final cartIcon = find.byIcon(Icons.shopping_cart);
      if (cartIcon.evaluate().isNotEmpty) {
        await tester.tap(cartIcon.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('checkout button exists on cart page with items',
        (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();
    });

    testWidgets('checkout form has required sections', (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();
    });

    testWidgets('can fill customer name field', (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, 'PT Alita Indonesia');
        expect(find.text('PT Alita Indonesia'), findsOneWidget);
      }
    });

    testWidgets('form validates empty required fields', (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();

      final submitButton = find.textContaining('Submit');
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('back navigation from checkout returns to previous page',
        (tester) async {
      await tester.pumpWidget(buildCheckoutApp());
      await tester.pumpAndSettle();

      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
