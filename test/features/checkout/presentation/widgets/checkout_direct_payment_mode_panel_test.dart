import 'package:alitapricelist/features/checkout/presentation/widgets/checkout_direct_payment_mode_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('manual mode shows Paper CTA', (tester) async {
    var paper = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutDirectPaymentModePanel(
            usePaper: false,
            onSelectPaper: () => paper = true,
            onSelectManual: () {},
          ),
        ),
      ),
    );

    expect(find.text('Bayar via Paper.id'), findsOneWidget);
    await tester.tap(find.text('Bayar via Paper.id'));
    expect(paper, isTrue);
  });

  testWidgets('paper mode shows explainer and back to manual', (tester) async {
    var manual = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutDirectPaymentModePanel(
            usePaper: true,
            onSelectPaper: () {},
            onSelectManual: () => manual = true,
          ),
        ),
      ),
    );

    expect(find.text('Pembayaran via Paper.id'), findsOneWidget);
    expect(find.text('Kembali ke pembayaran manual'), findsOneWidget);
    expect(find.text('Bayar via Paper.id'), findsNothing);
    await tester.tap(find.text('Kembali ke pembayaran manual'));
    expect(manual, isTrue);
  });
}
