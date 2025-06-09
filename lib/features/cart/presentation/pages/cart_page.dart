import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/format_helper.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item.dart';
import 'checkout_pages.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            Icon(Icons.shopping_cart_outlined,
                                size: 120, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Keranjang Anda kosong',
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan produk untuk memulai!',
                              style: GoogleFonts.montserrat(
                                  fontSize: 14, color: Colors.grey),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: state.cartItems.length,
                              itemBuilder: (context, index) {
                                final cartItem = state.cartItems[index];
                                return Dismissible(
                                  key: Key(
                                      '${cartItem.product.id}-${cartItem.netPrice}'),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red.shade700,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await _showDeleteConfirmationDialog(
                                        context);
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
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
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
                                backgroundColor: Colors.blue.shade700,
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
                        child: Text('Terjadi kesalahan: ${state.message}'));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Text('ALERT !'),
            ],
          ),
          content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Iya'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700),
              child: const Text('Batal', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );
  }
}
