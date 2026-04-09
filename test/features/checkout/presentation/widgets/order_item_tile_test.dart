import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alitapricelist/features/cart/data/cart_item.dart';
import 'package:alitapricelist/features/checkout/presentation/widgets/order_item_tile.dart';
import 'package:alitapricelist/core/utils/product_image_utils.dart';
import 'package:alitapricelist/features/pricelist/data/models/product.dart';
import 'package:alitapricelist/features/pricelist/logic/product_display_image_provider.dart';
import 'package:alitapricelist/features/product/logic/brand_spec_provider.dart';

Product _product({
  String name = 'Comfort Dream 160x200',
  String ukuran = '160x200',
  bool isSet = false,
  String divan = 'Tanpa Divan',
  String headboard = 'Tanpa Headboard',
  String sorong = 'Tanpa Sorong',
}) =>
    Product(
      id: '1',
      name: name,
      price: 11956000,
      imageUrl: 'https://example.com/img.jpg',
      category: 'Comfort',
      kasur: name,
      ukuran: ukuran,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      isSet: isSet,
      pricelist: 11956000,
      eupKasur: 11956000,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: 11956000,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
    );

CartItem _cartItem({
  Product? product,
  List<CartBonusSnapshot> bonuses = const [],
}) =>
    CartItem(
      product: product ?? _product(),
      quantity: 1,
      bonusSnapshots: bonuses,
    );

Future<void> _pumpTile(WidgetTester tester, Widget tile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandSpecProvider.overrideWith((ref) async => []),
        // Hindari CachedNetworkImage di test (pumpAndSettle tidak pernah selesai).
        productDisplayImageProvider.overrideWith((ref, product) {
          return '${ProductImageUtils.assetUriPrefix}assets/logo/sleepcenter_logo.png';
        }),
      ],
      child: MaterialApp(home: Scaffold(body: tile)),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('OrderItemTile', () {
    testWidgets('renders product name and config text', (tester) async {
      final item = _cartItem();
      await _pumpTile(
        tester,
        OrderItemTile(
          item: item,
          priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
          isBonusTakeAwayChecked: (_) => false,
          currentTakeAwayQty: (_) => 1,
          onTakeAwayToggled: (_, __) {},
          onTakeAwayQtyChanged: (_, __) {},
        ),
      );

      expect(find.text('Comfort Dream 160x200'), findsOneWidget);
      expect(find.text('Kasur Saja'), findsOneWidget);
    });

    testWidgets('renders set label when product is set', (tester) async {
      final item = _cartItem(
        product: _product(
          isSet: true,
          divan: 'Divan Comfort',
          headboard: 'Sandaran Adelio',
          sorong: 'Tanpa Sorong',
        ),
      );
      await _pumpTile(
        tester,
        OrderItemTile(
          item: item,
          priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
          isBonusTakeAwayChecked: (_) => false,
          currentTakeAwayQty: (_) => 1,
          onTakeAwayToggled: (_, __) {},
          onTakeAwayQtyChanged: (_, __) {},
        ),
      );

      expect(find.text('Set Lengkap'), findsOneWidget);
    });

    testWidgets('shows bonus section when showBonusSection is true', (tester) async {
      final item = _cartItem(
        bonuses: const [
          CartBonusSnapshot(name: 'Elegant Pillow', qty: 1, sku: '85031'),
        ],
      );
      await _pumpTile(
        tester,
        OrderItemTile(
          item: item,
          priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
          isBonusTakeAwayChecked: (_) => false,
          currentTakeAwayQty: (_) => 1,
          onTakeAwayToggled: (_, __) {},
          onTakeAwayQtyChanged: (_, __) {},
          showBonusSection: true,
        ),
      );

      expect(find.textContaining('Elegant Pillow'), findsOneWidget);
    });

    testWidgets('hides bonus section when showBonusSection is false', (tester) async {
      final item = _cartItem(
        bonuses: const [
          CartBonusSnapshot(name: 'Elegant Pillow', qty: 1, sku: '85031'),
        ],
      );
      await _pumpTile(
        tester,
        OrderItemTile(
          item: item,
          priceFmt: (n) => 'Rp ${n.toStringAsFixed(0)}',
          isBonusTakeAwayChecked: (_) => false,
          currentTakeAwayQty: (_) => 1,
          onTakeAwayToggled: (_, __) {},
          onTakeAwayQtyChanged: (_, __) {},
          showBonusSection: false,
        ),
      );

      expect(find.textContaining('Elegant Pillow'), findsNothing);
    });
  });
}
