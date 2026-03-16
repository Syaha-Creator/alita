import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../logic/cart_provider.dart';
import 'cart_item_card.dart';
import 'cart_sheet_footer.dart';
import 'cart_sheet_header.dart';

/// Cart Bottom Sheet (Pinterest-style minimalist)
class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: SheetScaffold(
        includeBottomSafePadding: false,
        child: Column(
          children: [
            const CartSheetHeader(),
            const Divider(height: 1),
            Expanded(
              child: cartItems.isEmpty
                  ? _buildEmptyCart(context)
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 8,
                        bottom: 12,
                      ),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return RepaintBoundary(
                          child: CartItemCard(item: item, index: index),
                        );
                      },
                    ),
            ),
            if (cartItems.isNotEmpty) const CartSheetFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return const EmptyStateView(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      subtitle: 'Add some products to get started',
    );
  }
}
