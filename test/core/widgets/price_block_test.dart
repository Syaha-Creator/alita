import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/widgets/price_block.dart';

String _formatPrice(double v) => 'Rp ${v.toStringAsFixed(0)}';

void main() {
  group('PriceBlock', () {
    testWidgets('renders formatted price', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PriceBlock(
            price: 500000,
            formatPrice: _formatPrice,
          ),
        ),
      ));

      expect(find.text('Rp 500000'), findsOneWidget);
    });

    testWidgets('shows original price when greater than price', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PriceBlock(
            price: 400000,
            originalPrice: 500000,
            formatPrice: _formatPrice,
          ),
        ),
      ));

      expect(find.text('Rp 500000'), findsOneWidget);
      expect(find.text('Rp 400000'), findsOneWidget);
    });

    testWidgets('hides original price when null', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PriceBlock(
            price: 500000,
            originalPrice: null,
            formatPrice: _formatPrice,
          ),
        ),
      ));

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1);
    });

    testWidgets('hides original price when <= current price', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PriceBlock(
            price: 500000,
            originalPrice: 500000,
            formatPrice: _formatPrice,
          ),
        ),
      ));

      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1);
    });

    testWidgets('original price has lineThrough decoration', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PriceBlock(
            price: 400000,
            originalPrice: 500000,
            formatPrice: _formatPrice,
          ),
        ),
      ));

      final originalText = tester.widget<Text>(find.text('Rp 500000'));
      expect(
        originalText.style?.decoration,
        TextDecoration.lineThrough,
      );
    });
  });
}
