import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/app_search_field.dart';

void main() {
  group('AppSearchField', () {
    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppSearchField(hintText: 'Cari produk...'),
        ),
      ));

      expect(find.text('Cari produk...'), findsOneWidget);
    });

    testWidgets('typing triggers onChanged', (tester) async {
      String? lastValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: 'Search',
            onChanged: (v) => lastValue = v,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      expect(lastValue, 'hello');
    });

    testWidgets('clear button appears after typing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: 'Search',
            onChanged: (_) {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.clear), findsNothing);

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clear button clears text and calls onChanged + onClear',
        (tester) async {
      String? changedValue;
      var clearCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: 'Search',
            onChanged: (v) => changedValue = v,
            onClear: () => clearCalled = true,
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(changedValue, '');
      expect(clearCalled, isTrue);
    });

    testWidgets('clear button hidden when showClearButton is false',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: 'Search',
            showClearButton: false,
            onChanged: (_) {},
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('shows search prefix icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppSearchField(hintText: 'Search'),
        ),
      ));

      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });
}
