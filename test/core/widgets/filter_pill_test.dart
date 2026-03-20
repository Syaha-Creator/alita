import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/filter_pill.dart';

void main() {
  group('FilterPill', () {
    testWidgets('renders text and icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            icon: Icons.location_on,
            text: 'Jakarta',
            onTap: () {},
            isActive: false,
          ),
        ),
      ));

      expect(find.text('Jakarta'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('shows trailing dropdown icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            icon: Icons.location_on,
            text: 'Jakarta',
            onTap: () {},
            isActive: false,
          ),
        ),
      ));

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            icon: Icons.location_on,
            text: 'Jakarta',
            onTap: () => tapped = true,
            isActive: false,
          ),
        ),
      ));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('active state uses bold font weight', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            icon: Icons.location_on,
            text: 'Jakarta',
            onTap: () {},
            isActive: true,
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text('Jakarta'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('inactive state uses normal font weight', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FilterPill(
            icon: Icons.location_on,
            text: 'Jakarta',
            onTap: () {},
            isActive: false,
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text('Jakarta'));
      expect(text.style?.fontWeight, FontWeight.normal);
    });
  });
}
