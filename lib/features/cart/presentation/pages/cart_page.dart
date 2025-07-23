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
import '../../../../services/approval_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../features/approval/presentation/bloc/approval_bloc.dart';
import '../../../../features/approval/presentation/bloc/approval_state.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<ApprovalBloc, ApprovalState>(
      listener: (context, state) {
        if (state is ApprovalSuccess) {
          CustomToast.showToast(state.message, ToastType.success);
        } else if (state is ApprovalError) {
          CustomToast.showToast(state.message, ToastType.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Keranjang Belanja'),
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
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CheckoutPages(),
                                          ),
                                        );
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
                            if (state.cartItems.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showApprovalDialog(context),
                                icon: const Icon(Icons.approval),
                                label: const Text('Send Cart for Approval'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.warning,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                            ],
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

  Future<void> _showApprovalDialog(BuildContext context) async {
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Cart for Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter customer name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: customerPhoneController,
              decoration: const InputDecoration(
                labelText: 'Customer Phone',
                hintText: 'Enter customer phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (customerNameController.text.isEmpty ||
                  customerPhoneController.text.isEmpty) {
                CustomToast.showToast(
                    'Please fill in all fields', ToastType.error);
                return;
              }

              Navigator.of(dialogContext).pop();

              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final cartState = context.read<CartBloc>().state;
                if (cartState is CartLoaded) {
                  final result = await ApprovalService.createApprovalFromCart(
                    cartItems: cartState.cartItems,
                    customerName: customerNameController.text,
                    customerPhone: customerPhoneController.text,
                  );

                  Navigator.of(context).pop(); // Close loading

                  if (result['success']) {
                    CustomToast.showToast('Approval request sent successfully',
                        ToastType.success);
                    // Clear cart after successful approval
                    context.read<CartBloc>().add(ClearCart());
                  } else {
                    CustomToast.showToast(result['message'], ToastType.error);
                  }
                } else {
                  Navigator.of(context).pop(); // Close loading
                  CustomToast.showToast('Cart is empty', ToastType.error);
                }
              } catch (e) {
                Navigator.of(context).pop(); // Close loading
                CustomToast.showToast(
                    'Error sending approval: $e', ToastType.error);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
