import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_badge.dart';
import '../../logic/cart_provider.dart';
import 'cart_bottom_sheet.dart';

/// Floating Action Button untuk Cart dengan badge
class CartFAB extends ConsumerWidget {
  const CartFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref.watch(cartTotalItemsProvider);

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        FloatingActionButton(
          onPressed: () {
            showCartSheet(context);
          },
          backgroundColor: AppColors.accent,
          elevation: 4,
          child: const Icon(
            Icons.shopping_cart,
            color: AppColors.surface,
          ),
        ),
        if (totalItems > 0)
          Positioned(
            right: 0,
            top: 0,
            child: FloatingBadge(count: totalItems),
          ),
      ],
    );
  }
}
