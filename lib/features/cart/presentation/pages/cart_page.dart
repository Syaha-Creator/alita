import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../theme/app_colors.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

import '../widgets/cart_item.dart';
import 'checkout_pages.dart';
import '../../../../core/widgets/custom_toast.dart';
import 'checkout_user_info_dialog.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _navigateToAddProduct(BuildContext context) {
    context.go(RoutePaths.product);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartError) {
          CustomToast.showToast(state.message, ToastType.error);
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded) {
                if (state.activeCartItems.isEmpty) {
                  return _buildEmptyCart(context, colorScheme);
                } else {
                  return _buildCartWithItems(
                      context, state, colorScheme, isDark);
                }
              } else if (state is CartError) {
                return EmptyState.error(
                  title: 'Terjadi Kesalahan',
                  subtitle: state.message,
                  action: ElevatedButton.icon(
                    onPressed: () => context.read<CartBloc>().add(LoadCart()),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              } else {
                return const LoadingState(message: 'Memuat keranjang...');
              }
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StandardAppBar(
      title: 'Keranjang',
      icon: Icons.shopping_cart_rounded,
      centerTitle: true,
      onBack: () => Navigator.of(context).pop(),
      actions: [
        BlocBuilder<CartBloc, CartState>(
          buildWhen: (previous, current) {
            final prevCount =
                previous is CartLoaded ? previous.activeCartItems.length : 0;
            final currCount =
                current is CartLoaded ? current.activeCartItems.length : 0;
            return prevCount != currCount;
          },
          builder: (context, state) {
            final itemCount =
                state is CartLoaded ? state.activeCartItems.length : 0;
            if (itemCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primaryDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCart(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppPadding.p24),
            Text(
              'Keranjang Kosong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppPadding.p8),
            Text(
              'Tambahkan produk untuk memulai',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppPadding.p32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Mulai Belanja',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems(BuildContext context, CartLoaded state,
      ColorScheme colorScheme, bool isDark) {
    final selectedItems = state.selectedItems;
    final totalPrice = selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.netPrice * item.quantity),
    );
    final totalItems = state.activeCartItems.length;
    final selectedCount = selectedItems.length;
    final hasPartialSelection = selectedCount < totalItems && selectedCount > 0;

    return Column(
      children: [
        // Partial selection indicator (only when needed)
        if (hasPartialSelection)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: AppPadding.p8),
                Text(
                  '$selectedCount dari $totalItems produk dipilih',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.activeCartItems.length,
            itemBuilder: (context, index) {
              final cartItem = state.activeCartItems[index];
              return Dismissible(
                key: ValueKey(cartItem.cartLineId),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete_rounded,
                      color: Colors.white, size: 24),
                ),
                confirmDismiss: (direction) async {
                  return await ConfirmationDialog.showDelete(
                    context: context,
                    title: 'Hapus Item',
                    message:
                        'Apakah Anda yakin ingin menghapus item ini dari keranjang?',
                  );
                },
                onDismissed: (direction) {
                  context.read<CartBloc>().add(RemoveFromCart(
                        productId: cartItem.product.id,
                        netPrice: cartItem.netPrice,
                      ));
                },
                child: CartItemWidget(item: cartItem),
              );
            },
          ),
        ),

        // Bottom Action Bar
        _buildBottomBar(
            context, colorScheme, isDark, selectedItems, totalPrice),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme,
      bool isDark, List selectedItems, double totalPrice) {
    final hasSelection = selectedItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Add product button (compact)
            OutlinedButton(
              onPressed: () => _navigateToAddProduct(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),

            const SizedBox(width: AppPadding.p12),

            // Checkout button (expanded)
            Expanded(
              child: ElevatedButton(
                onPressed: hasSelection
                    ? () async {
                        final result = await showDialog<CheckoutDialogResult>(
                          context: context,
                          builder: (context) => CheckoutUserInfoDialog(),
                        );
                        if (result != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPages(
                                userName: result.name,
                                userPhone: result.phone,
                                userEmail: result.email,
                                isTakeAway: result.isTakeAway,
                                isExistingCustomer: result.isExistingCustomer,
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  disabledForegroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.38),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: hasSelection ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: hasSelection
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Checkout',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            FormatHelper.formatCurrency(totalPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Pilih item untuk checkout',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
