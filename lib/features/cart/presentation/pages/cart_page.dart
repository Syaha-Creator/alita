import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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

  void _navigateToAddProduct(BuildContext context) {
    context.go(RoutePaths.product);
  }

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
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Keranjang Belanja',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded) {
                if (state.cartItems.isEmpty) {
                  return _buildEmptyCart(context, isDark);
                } else {
                  return _buildCartWithItems(context, state, isDark);
                }
              } else if (state is CartError) {
                return _buildErrorState(context, state, isDark);
              } else {
                return _buildLoadingState();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppPadding.p24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color:
                    isDark ? AppColors.textSecondaryDark : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Keranjang Anda kosong',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tambahkan produk untuk memulai belanja Anda',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(context),
                icon: const Icon(Icons.add_shopping_cart, size: 24),
                label: Text(
                  'Mulai Belanja',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.buttonDark : AppColors.buttonLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor:
                      (isDark ? AppColors.buttonDark : AppColors.buttonLight)
                          .withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems(
      BuildContext context, CartLoaded state, bool isDark) {
    final selectedItems =
        state.cartItems.where((item) => item.isSelected).toList();
    final totalPrice = selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.netPrice * item.quantity),
    );
    final totalItems =
        selectedItems.fold(0, (sum, item) => sum + item.quantity);

    return Column(
      children: [
        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppPadding.p4),
            itemCount: state.cartItems.length,
            itemBuilder: (context, index) {
              final cartItem = state.cartItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppPadding.p4,
                  vertical: AppPadding.p4,
                ),
                child: Dismissible(
                  key: Key('${cartItem.product.id}-${cartItem.netPrice}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppPadding.p20),
                    child:
                        const Icon(Icons.delete, color: Colors.white, size: 24),
                  ),
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmationDialog(context, isDark);
                  },
                  onDismissed: (direction) {
                    context.read<CartBloc>().add(RemoveFromCart(
                          productId: cartItem.product.id,
                          netPrice: cartItem.netPrice,
                        ));
                  },
                  child: CartItemWidget(item: cartItem),
                ),
              );
            },
          ),
        ),

        // Bottom action buttons
        Container(
          padding: const EdgeInsets.all(AppPadding.p16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Add more products button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToAddProduct(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  label: Text(
                    'Tambah Produk Lain',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.buttonDark : AppColors.buttonLight,
                    side: BorderSide(
                      color:
                          isDark ? AppColors.buttonDark : AppColors.buttonLight,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () async {
                          final result = await showDialog<CheckoutDialogResult>(
                            context: context,
                            builder: (context) => CheckoutUserInfoDialog(),
                          );
                          if (result != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPages(
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
                    backgroundColor:
                        isDark ? AppColors.buttonDark : AppColors.buttonLight,
                    disabledBackgroundColor: isDark
                        ? AppColors.textSecondaryDark.withOpacity(0.3)
                        : Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor:
                        (isDark ? AppColors.buttonDark : AppColors.buttonLight)
                            .withOpacity(0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Checkout',
                        style: GoogleFonts.montserrat(
                          color: selectedItems.isEmpty
                              ? (isDark
                                  ? AppColors.textSecondaryDark
                                  : Colors.grey.shade600)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (selectedItems.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          FormatHelper.formatCurrency(totalPrice),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, CartError state, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Terjadi Kesalahan',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.read<CartBloc>().add(LoadCart()),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.buttonDark : AppColors.buttonLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat keranjang...'),
        ],
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warning, color: AppColors.error, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Hapus Item',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus item ini dari keranjang?',
            style: GoogleFonts.montserrat(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: GoogleFonts.montserrat(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }
}
