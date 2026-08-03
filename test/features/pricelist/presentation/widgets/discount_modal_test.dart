import 'package:alitapricelist/features/pricelist/presentation/widgets/discount_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpModal(
    WidgetTester tester, {
    required List<double> maxLimits,
    required double baseTotalEup,
    List<double> currentDiscounts = const [],
    required void Function(List<double>) onApply,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscountModalContent(
            maxLimits: maxLimits,
            baseTotalEup: baseTotalEup,
            currentDiscounts: currentDiscounts,
            onApply: onApply,
            onClose: () {},
          ),
        ),
      ),
    );
  }

  group('DiscountModalContent — Rp mode thousand separator', () {
    testWidgets(
      'live-formats typed nominal with thousand separators',
      (tester) async {
        await pumpModal(
          tester,
          maxLimits: const [0.5],
          baseTotalEup: 10000000,
          onApply: (_) {},
        );

        await tester.tap(find.text('Rp'));
        await tester.pump();

        await tester.enterText(find.byType(TextFormField), '1500000');
        await tester.pump();

        final field =
            tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.controller!.text, '1.500.000');
      },
    );

    testWidgets(
      'clamping to the max nominal keeps the field re-parseable on Apply '
      '(regression: previously threw "Input tidak valid" after clamp)',
      (tester) async {
        List<double>? applied;

        await pumpModal(
          tester,
          maxLimits: const [0.5],
          baseTotalEup: 10000000,
          onApply: (discounts) => applied = discounts,
        );

        await tester.tap(find.text('Rp'));
        await tester.pump();

        // Max nominal allowed = 10,000,000 * 0.5 = 5,000,000. Type over it.
        await tester.enterText(find.byType(TextFormField), '6000000');
        await tester.pump();

        final field =
            tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.controller!.text, '5.000.000');
        expect(find.text('Input tidak valid'), findsNothing);

        await tester.tap(find.text('Terapkan'));
        await tester.pump();

        expect(applied, isNotNull);
        expect(applied!.single, closeTo(0.5, 0.0001));

        // Let the max-limit toast's auto-dismiss timer finish before the
        // widget tree is torn down, otherwise the test binding asserts on
        // a pending timer.
        await tester.pump(const Duration(seconds: 3));
      },
    );

    testWidgets(
      'switching Rp -> % correctly re-derives percent from a thousand-'
      'separated nominal',
      (tester) async {
        List<double>? applied;

        await pumpModal(
          tester,
          maxLimits: const [0.5],
          baseTotalEup: 10000000,
          onApply: (discounts) => applied = discounts,
        );

        await tester.tap(find.text('Rp'));
        await tester.pump();

        await tester.enterText(find.byType(TextFormField), '2500000');
        await tester.pump();

        await tester.tap(find.text('%'));
        await tester.pump();

        final field =
            tester.widget<TextFormField>(find.byType(TextFormField));
        expect(field.controller!.text, '25');

        await tester.tap(find.text('Terapkan'));
        await tester.pump();

        expect(applied, isNotNull);
        expect(applied!.single, closeTo(0.25, 0.0001));
      },
    );
  });

  group('DiscountModalContent — independent per-tier saving', () {
    testWidgets(
      'each tier is saved directly to its own slot, applied sequentially '
      'to the cascading (post previous-tier) base — not merged into one '
      'accumulated total',
      (tester) async {
        List<double>? applied;

        await pumpModal(
          tester,
          maxLimits: const [0.3, 0.5, 0.5, 0.5],
          baseTotalEup: 10000000,
          onApply: (discounts) => applied = discounts,
        );

        final fields = find.byType(TextFormField);
        expect(fields, findsNWidgets(4));

        // Diskon 1: 10%, Diskon 3: 20%. Diskon 2 & 4 left empty.
        await tester.enterText(fields.at(0), '10');
        await tester.pump();
        await tester.enterText(fields.at(2), '20');
        await tester.pump();

        await tester.tap(find.text('Terapkan'));
        await tester.pump();

        expect(applied, isNotNull);
        // Only the two filled tiers are saved — each independently, at its
        // own index-derived slot — with no auto-cascading/overflow into the
        // empty tiers.
        expect(applied, [closeTo(0.10, 0.0001), closeTo(0.20, 0.0001)]);
      },
    );

    testWidgets(
      'leaves earlier empty tiers alone: a value in tier 2 validates '
      'against the full base when tier 1 is untouched',
      (tester) async {
        List<double>? applied;

        await pumpModal(
          tester,
          maxLimits: const [0.3, 0.5],
          baseTotalEup: 10000000,
          onApply: (discounts) => applied = discounts,
        );

        final fields = find.byType(TextFormField);
        // Tier 2 max = 50% of the full base (tier 1 untouched) = 5,000,000.
        await tester.enterText(fields.at(1), '40');
        await tester.pump();

        await tester.tap(find.text('Terapkan'));
        await tester.pump();

        expect(applied, [closeTo(0.40, 0.0001)]);
      },
    );
  });
}
