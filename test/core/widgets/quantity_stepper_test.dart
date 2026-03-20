import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/quantity_stepper.dart';

void main() {
  group('QuantityStepper', () {
    testWidgets('displays quantity text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 5,
            onDecrement: () {},
            onIncrement: () {},
          ),
        ),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('minus button fires onDecrement', (tester) async {
      var decremented = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 3,
            onDecrement: () => decremented = true,
            onIncrement: () {},
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.remove));
      expect(decremented, isTrue);
    });

    testWidgets('plus button fires onIncrement', (tester) async {
      var incremented = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 3,
            onDecrement: () {},
            onIncrement: () => incremented = true,
          ),
        ),
      ));

      await tester.tap(find.byIcon(Icons.add));
      expect(incremented, isTrue);
    });

    testWidgets('uses custom decrement icon', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 1,
            onDecrement: () {},
            onIncrement: () {},
            decrementIcon: Icons.delete_outline,
          ),
        ),
      ));

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('renders with quantity of zero', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuantityStepper(
            quantity: 0,
            onDecrement: () {},
            onIncrement: () {},
          ),
        ),
      ));

      expect(find.text('0'), findsOneWidget);
    });
  });
}
