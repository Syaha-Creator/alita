import 'package:alitapricelist/features/history/data/models/order_history.dart';
import 'package:alitapricelist/features/history/presentation/widgets/payment_info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

OrderHistory _orderWithPayments(List<Map<String, dynamic>> payments) {
  return OrderHistory.fromApiJson(<String, dynamic>{
    'id': 1,
    'no_sp': 'SP-001',
    'order_date': '-',
    'request_date': '-',
    'note': '',
    'customer_name': 'A',
    'phone': '-',
    'address': '-',
    'email': '',
    'extended_amount': 1000000,
    'status': 'Pending',
    'order_letter_details': <dynamic>[],
    'order_letter_payments': payments,
  });
}

String _fmt(num v) => 'Rp ${v.toStringAsFixed(0)}';

Future<void> _pump(WidgetTester tester, OrderHistory order) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PaymentInfoSection(
          order: order,
          onTapAddPayment: () {},
          onTapReceipt: (_) {},
          currencyFormatter: _fmt,
        ),
      ),
    ),
  );
}

void main() {
  group('PaymentInfoSection', () {
    testWidgets(
        'hides payment rows where verified == false (ditolak/duplikat)',
        (tester) async {
      final order = _orderWithPayments([
        {
          'payment_method': 'Transfer',
          'payment_bank': 'BCA',
          'payment_amount': 400000,
          'verified': true,
        },
        {
          'payment_method': 'Transfer',
          'payment_bank': 'Mandiri',
          'payment_amount': 999999,
          'verified': false,
        },
      ]);

      await _pump(tester, order);

      // Baris valid tampil (di row + di footer Total Dibayar), baris ditolak
      // disembunyikan sepenuhnya (tidak ada di row maupun di total).
      expect(find.text(_fmt(400000)), findsNWidgets(2));
      expect(find.text(_fmt(999999)), findsNothing);
      expect(find.text(_fmt(1399999)), findsNothing);
    });

    testWidgets('counts null verified (belum direview) toward total',
        (tester) async {
      final order = _orderWithPayments([
        {
          'payment_method': 'Cash',
          'payment_bank': '-',
          'payment_amount': 250000,
          // 'verified' omitted → null → tetap dihitung.
        },
      ]);

      await _pump(tester, order);

      // Row + footer Total Dibayar keduanya menampilkan nominal yang sama.
      expect(find.text(_fmt(250000)), findsNWidgets(2));
    });

    testWidgets('shows Paper unpaid status and Bayar via Paper.id CTA',
        (tester) async {
      OrderPayment? opened;
      final order = _orderWithPayments([
        {
          'payment_method': 'Paper.id',
          'payment_bank': 'Paper.id',
          'payment_amount': 1000000,
          'paper_id_status': 'UNPAID',
          'paper_id_invoice_url': 'https://stg-v2.paper.id/abc',
        },
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentInfoSection(
              order: order,
              onTapAddPayment: () {},
              onTapReceipt: (_) {},
              onTapPayPaper: (payment) => opened = payment,
              currencyFormatter: _fmt,
            ),
          ),
        ),
      );

      expect(find.text('Belum bayar'), findsOneWidget);
      expect(find.text('Bayar via Paper.id'), findsOneWidget);
      // Unpaid Paper tidak dihitung → Total Dibayar 0, Sisa 1000000
      expect(find.text(_fmt(0)), findsOneWidget);
      expect(find.text(_fmt(1000000)), findsNWidgets(2)); // row amount + sisa
      expect(find.text('Tambah Pembayaran'), findsNothing);

      await tester.tap(find.text('Bayar via Paper.id'));
      await tester.pump();
      expect(opened?.paperIdInvoiceUrl, 'https://stg-v2.paper.id/abc');
    });

    testWidgets(
        'shows Bayar CTA for unpaid Paper even when invoice URL missing',
        (tester) async {
      final order = _orderWithPayments([
        {
          'payment_method': 'Paper.id',
          'payment_bank': 'Paper.id',
          'payment_amount': 3069000,
          'paper_id_status': 'UNPAID',
        },
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentInfoSection(
              order: order,
              onTapAddPayment: () {},
              onTapReceipt: (_) {},
              onTapPayPaper: (_) {},
              currencyFormatter: _fmt,
            ),
          ),
        ),
      );

      expect(find.text('Belum bayar'), findsOneWidget);
      expect(find.text('Bayar via Paper.id'), findsOneWidget);
      expect(find.text('Tambah Pembayaran'), findsNothing);
    });

    testWidgets('Paper PAID shows Sudah bayar without pay CTA', (tester) async {
      final order = _orderWithPayments([
        {
          'payment_method': 'Paper.id',
          'payment_bank': 'Paper.id',
          'payment_amount': 1000000,
          'paper_id_status': 'PAID',
          'paper_id_invoice_url': 'https://stg-v2.paper.id/abc',
        },
      ]);

      await _pump(tester, order);

      expect(find.text('Sudah bayar'), findsOneWidget);
      expect(find.text('Bayar via Paper.id'), findsNothing);
      expect(find.text('Lunas'), findsOneWidget);
    });
  });
}
