import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/animated_list_item.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/sheet_scaffold.dart';
import '../../logic/cart_provider.dart';
import 'cart_item_card.dart';
import 'cart_sheet_footer.dart';
import 'cart_sheet_header.dart';

/// [context] = halaman di bawah sheet (yang memanggil [showCartSheet]); dipakai
/// untuk navigasi & membuka ulang sheet setelah kembali dari detail produk.
Future<void> showCartSheet(BuildContext context) {
  final media = MediaQuery.of(context);
  final isTablet = media.size.shortestSide >= 600;

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: isTablet ? const BoxConstraints(maxWidth: 680) : null,
    builder: (sheetContext) {
      if (!isTablet) {
        return CartBottomSheet(anchorContext: context);
      }
      return Align(
        alignment: Alignment.bottomCenter,
        child: CartBottomSheet(anchorContext: context),
      );
    },
  );
}

void _tryReopenCartSheetIfNeeded(BuildContext anchor) {
  if (!anchor.mounted) return;
  try {
    final loc = GoRouterState.of(anchor).matchedLocation;
    if (loc == '/checkout' || loc == '/success') return;
  } catch (_) {
    // Anchor tidak di bawah GoRouter — abaikan guard.
  }
  showCartSheet(anchor);
}

/// Cart Bottom Sheet (Pinterest-style minimalist)
class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key, required this.anchorContext});

  /// Konteks halaman pemanggil sheet (list/detail); tetap mounted saat sheet ditutup.
  final BuildContext anchorContext;

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
                        return AnimatedListItem(
                          index: index,
                          child: RepaintBoundary(
                            child: CartItemCard(
                              item: item,
                              index: index,
                              anchorContext: anchorContext,
                              onReturnFromProductDetail: () =>
                                  _tryReopenCartSheetIfNeeded(anchorContext),
                            ),
                          ),
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
