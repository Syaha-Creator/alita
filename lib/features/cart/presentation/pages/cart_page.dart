import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/app_constant.dart';
import '../../../../core/utils/format_helper.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartError) {
          CustomToast.showToast(state.message, ToastType.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Keranjang Belanja'),
          actions: [],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, state) {
                    if (state is CartLoaded) {
                      if (state.cartItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 120,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keranjang Anda kosong',
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tambahkan produk untuk memulai!',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final selectedItems = state.cartItems
                            .where((item) => item.isSelected)
                            .toList();
                        double totalPrice = selectedItems.fold(
                          0.0,
                          (sum, item) => sum + (item.netPrice * item.quantity),
                        );
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppPadding.p12),
                                itemCount: state.cartItems.length,
                                itemBuilder: (context, index) {
                                  final cartItem = state.cartItems[index];
                                  return Dismissible(
                                    key: Key(
                                        '${cartItem.product.id}-${cartItem.netPrice}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      color: AppColors.error,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(
                                          right: AppPadding.p20),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await _showDeleteConfirmationDialog(
                                          context, isDark);
                                    },
                                    onDismissed: (direction) {
                                      context
                                          .read<CartBloc>()
                                          .add(RemoveFromCart(
                                            productId: cartItem.product.id,
                                            netPrice: cartItem.netPrice,
                                          ));
                                    },
                                    child: CartItemWidget(item: cartItem),
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(AppPadding.p16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: selectedItems.isEmpty
                                    ? null
                                    : () async {
                                        final result = await showDialog<
                                            CheckoutDialogResult>(
                                          context: context,
                                          builder: (context) =>
                                              CheckoutUserInfoDialog(),
                                        );
                                        if (result != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CheckoutPages(
                                                userName: result.name,
                                                userPhone: result.phone,
                                                userEmail: result.email,
                                                isTakeAway: result.isTakeAway,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppColors.buttonDark
                                      : AppColors.buttonLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size(double.infinity, 56),
                                  elevation: 8,
                                ),
                                child: Text(
                                  'Checkout ${FormatHelper.formatCurrency(totalPrice)}',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    } else if (state is CartError) {
                      return Center(
                        child: Text(
                          'Terjadi kesalahan: ${state.message}',
                          style: TextStyle(
                            color: isDark ? AppColors.error : Colors.red,
                          ),
                        ),
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'ALERT !',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus item ini?',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Iya',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Batal', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
  }
}
