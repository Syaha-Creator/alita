import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/empty_state_view.dart';

/// Empty cart state for checkout page.
class CheckoutEmptyState extends StatelessWidget {
  const CheckoutEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Surat Pesanan'),
        elevation: 0,
      ),
      body: EmptyStateView(
        icon: Icons.shopping_cart_outlined,
        title: 'Keranjang kosong',
        subtitle: 'Tambahkan produk terlebih dahulu',
        action: ActionButtonBar(
          fullWidth: false,
          mainAxisSize: MainAxisSize.min,
          height: 44,
          borderRadius: 14,
          primaryLabel: 'Kembali ke Beranda',
          onPrimaryPressed: () => context.go('/'),
        ),
      ),
    );
  }
}
