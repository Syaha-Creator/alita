import 'package:flutter/material.dart';

import '../../../cart/data/cart_item.dart';
import 'order_item_tile.dart';

/// Order summary section showing all cart items with take-away controls.
///
/// Extracted from [CheckoutPage] build method to reduce file size.
class CheckoutOrderSummary extends StatelessWidget {
  final List<CartItem> cartItems;
  final String Function(num) priceFmt;
  final bool Function(int itemIndex, CartBonusSnapshot bonus)
      isBonusTakeAwayChecked;
  final int Function(int itemIndex, CartBonusSnapshot bonus) currentTakeAwayQty;
  final void Function(int itemIndex, CartBonusSnapshot bonus, bool checked)
      onTakeAwayToggled;
  final void Function(int itemIndex, CartBonusSnapshot bonus, int qty)
      onTakeAwayQtyChanged;

  const CheckoutOrderSummary({
    super.key,
    required this.cartItems,
    required this.priceFmt,
    required this.isBonusTakeAwayChecked,
    required this.currentTakeAwayQty,
    required this.onTakeAwayToggled,
    required this.onTakeAwayQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(cartItems.length, (index) {
          final item = cartItems[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == cartItems.length - 1 ? 0 : 12,
            ),
            child: RepaintBoundary(
              child: OrderItemTile(
                item: item,
                priceFmt: priceFmt,
                isBonusTakeAwayChecked: (b) =>
                    isBonusTakeAwayChecked(index, b),
                currentTakeAwayQty: (b) => currentTakeAwayQty(index, b),
                onTakeAwayToggled: (b, checked) =>
                    onTakeAwayToggled(index, b, checked),
                onTakeAwayQtyChanged: (b, qty) =>
                    onTakeAwayQtyChanged(index, b, qty),
              ),
            ),
          );
        }),
      ],
    );
  }
}
