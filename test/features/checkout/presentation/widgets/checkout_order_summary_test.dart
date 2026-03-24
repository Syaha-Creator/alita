import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/presentation/widgets/checkout_order_summary.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';

Product _product({String id = '1', String name = 'Test Product'}) => Product(
      id: id,
      name: name,
      price: 1000000,
      imageUrl: '',
      category: 'C',
      kasur: name,
      ukuran: '160x200',
      divan: '',
      headboard: '',
      sorong: '',
      isSet: false,
      pricelist: 1000000,
      eupKasur: 1000000,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: 1000000,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

List<CartItem> _cartItems(int count) => List.generate(
      count,
      (i) => CartItem(
        product: _product(id: '$i', name: 'Product $i'),
        quantity: 1,
      ),
    );

void main() {
  group('CheckoutOrderSummary', () {
    testWidgets('renders empty when no cart items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CheckoutOrderSummary(
                cartItems: const [],
                priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
                isBonusTakeAwayChecked: (_, __) => false,
                currentTakeAwayQty: (_, __) => 1,
                onTakeAwayToggled: (_, __, ___) {},
                onTakeAwayQtyChanged: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CheckoutOrderSummary), findsOneWidget);
      expect(find.text('Product 0'), findsNothing);
    });

    testWidgets('renders single cart item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CheckoutOrderSummary(
                cartItems: _cartItems(1),
                priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
                isBonusTakeAwayChecked: (_, __) => false,
                currentTakeAwayQty: (_, __) => 1,
                onTakeAwayToggled: (_, __, ___) {},
                onTakeAwayQtyChanged: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Product 0'), findsOneWidget);
    });

    testWidgets('renders multiple cart items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CheckoutOrderSummary(
                cartItems: _cartItems(3),
                priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
                isBonusTakeAwayChecked: (_, __) => false,
                currentTakeAwayQty: (_, __) => 1,
                onTakeAwayToggled: (_, __, ___) {},
                onTakeAwayQtyChanged: (_, __, ___) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Product 0'), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
    });
  });
}
