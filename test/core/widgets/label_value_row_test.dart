import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/label_value_row.dart';

void main() {
  group('LabelValueRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LabelValueRow(label: 'Subtotal', value: 'Rp 500.000'),
        ),
      ));

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Rp 500.000'), findsOneWidget);
    });

    testWidgets('applies custom label style', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LabelValueRow(
            label: 'Total',
            value: 'Rp 1.000.000',
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text('Total'));
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('applies custom value style', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LabelValueRow(
            label: 'Tax',
            value: '10%',
            valueStyle: TextStyle(color: Colors.red),
          ),
        ),
      ));

      final text = tester.widget<Text>(find.text('10%'));
      expect(text.style?.color, Colors.red);
    });

    testWidgets('uses Row with spaceBetween alignment', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: LabelValueRow(label: 'A', value: 'B'),
        ),
      ));

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });
  });
}
