import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/product_image_utils.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/presentation/widgets/checkout_order_summary.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_display_image_provider.dart';

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

/// [OrderItemTile] memakai Riverpod; hindari jaringan di test.
Widget _summaryTestApp(Widget body) => ProviderScope(
      overrides: [
        productDisplayImageProvider.overrideWith((ref, product) {
          return '${ProductImageUtils.assetUriPrefix}assets/logo/sleepcenter_logo.png';
        }),
      ],
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    );

void main() {
  group('CheckoutOrderSummary', () {
    testWidgets('renders empty when no cart items', (tester) async {
      await tester.pumpWidget(
        _summaryTestApp(
          CheckoutOrderSummary(
            cartItems: const [],
            priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
            isBonusTakeAwayChecked: (_, __) => false,
            currentTakeAwayQty: (_, __) => 1,
            onTakeAwayToggled: (_, __, ___) {},
            onTakeAwayQtyChanged: (_, __, ___) {},
            lineTakeAway: (_) => false,
            onLineTakeAwayChanged: (_, __) {},
          ),
        ),
      );

      expect(find.byType(CheckoutOrderSummary), findsOneWidget);
      expect(find.text('Product 0'), findsNothing);
    });

    testWidgets('renders single cart item', (tester) async {
      await tester.pumpWidget(
        _summaryTestApp(
          CheckoutOrderSummary(
            cartItems: _cartItems(1),
            priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
            isBonusTakeAwayChecked: (_, __) => false,
            currentTakeAwayQty: (_, __) => 1,
            onTakeAwayToggled: (_, __, ___) {},
            onTakeAwayQtyChanged: (_, __, ___) {},
            lineTakeAway: (_) => false,
            onLineTakeAwayChanged: (_, __) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Product 0'), findsOneWidget);
    });

    testWidgets('renders multiple cart items', (tester) async {
      await tester.pumpWidget(
        _summaryTestApp(
          CheckoutOrderSummary(
            cartItems: _cartItems(3),
            priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
            isBonusTakeAwayChecked: (_, __) => false,
            currentTakeAwayQty: (_, __) => 1,
            onTakeAwayToggled: (_, __, ___) {},
            onTakeAwayQtyChanged: (_, __, ___) {},
            lineTakeAway: (_) => false,
            onLineTakeAwayChanged: (_, __) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Product 0'), findsOneWidget);
      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
    });
  });
}
