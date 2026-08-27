import 'package:alitapricelist/features/checkout/presentation/order_success_route_args.dart';
import 'package:alitapricelist/features/checkout/presentation/pages/order_success_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Paper fail mode shows recreate CTA only', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderSuccessPage(
            args: const OrderSuccessRouteArgs(
              noSp: '261101TEST',
              expectPaperPayment: true,
              orderLetterId: 99,
              paperPaymentAmount: 500000,
              paperCreatorId: 7,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Buat ulang link Paper.id'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsNothing);
    expect(find.textContaining('Pesanan Berhasil, Pembayaran Belum Siap'),
        findsOneWidget);
    expect(find.textContaining('No. SP 261101TEST'), findsOneWidget);
  });

  testWidgets('Paper OK mode shows pay + home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderSuccessPage(
            args: const OrderSuccessRouteArgs(
              noSp: '261101OK',
              paperInvoiceUrl: 'https://paper.id/inv/1',
              expectPaperPayment: true,
              orderLetterId: 1,
              paperPaymentAmount: 100,
              paperCreatorId: 1,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Bayar via Paper.id'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
    expect(find.text('Buat ulang link Paper.id'), findsNothing);
  });
}
