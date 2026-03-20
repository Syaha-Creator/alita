import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/app_choice_chip.dart';

void main() {
  group('AppChoiceChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: '160x200',
            selected: false,
            onSelected: (_) {},
          ),
        ),
      ));

      expect(find.text('160x200'), findsOneWidget);
    });

    testWidgets('fires onSelected with toggled value', (tester) async {
      bool? receivedValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: 'Chip',
            selected: false,
            onSelected: (v) => receivedValue = v,
          ),
        ),
      ));

      await tester.tap(find.text('Chip'));
      await tester.pump();
      expect(receivedValue, isTrue);
    });

    testWidgets('selected true fires onSelected with false', (tester) async {
      bool? receivedValue;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: 'Chip',
            selected: true,
            onSelected: (v) => receivedValue = v,
          ),
        ),
      ));

      await tester.tap(find.text('Chip'));
      await tester.pump();
      expect(receivedValue, isFalse);
    });

    testWidgets('shows checkmark when selected and showCheckmark is true',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: 'Chip',
            selected: true,
            showCheckmark: true,
            onSelected: (_) {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('hides checkmark when not selected', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: 'Chip',
            selected: false,
            showCheckmark: true,
            onSelected: (_) {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('not tappable when onSelected is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppChoiceChip(
            label: 'Chip',
            selected: false,
            onSelected: null,
          ),
        ),
      ));

      final gesture = tester.widget<GestureDetector>(
        find.byType(GestureDetector).first,
      );
      expect(gesture.onTap, isNull);
    });
  });
}
