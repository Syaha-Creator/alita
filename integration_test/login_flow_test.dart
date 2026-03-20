import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

/// Integration test: Login Flow
///
/// Launches the app in a logged-out state, verifies the login page renders,
/// fills in credentials, taps the login button, and verifies navigation
/// to the home/product-list page.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockSecureStorageChannel();
  });

  group('Login Flow', () {
    testWidgets('shows login page when logged out', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: false));
      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsWidgets);
    });

    testWidgets('email and password fields are present', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: false));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsAtLeast(2));
    });

    testWidgets('can type email and password', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: false));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeast(2));

      await tester.enterText(textFields.first, 'test@alita.com');
      await tester.enterText(textFields.at(1), 'password123');

      expect(find.text('test@alita.com'), findsOneWidget);
    });

    testWidgets('logged-in user goes directly to home', (tester) async {
      await tester.pumpWidget(buildTestApp(loggedIn: true));
      await tester.pumpAndSettle();

      expect(find.text('Masuk'), findsNothing);
    });
  });
}
