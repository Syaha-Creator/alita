import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/format_helper.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/event/cart_event.dart';
import '../bloc/state/cart_state.dart';

class CheckoutPages extends StatefulWidget {
  const CheckoutPages({super.key});

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentMethod = 'Transfer Bank';
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
    },
    {
      'name': 'Kartu Kredit',
      'icon': Icons.credit_card,
    },
    {
      'name': 'E-Wallet',
      'icon': Icons.mobile_friendly,
    },
    {
      'name': 'COD',
      'icon': Icons.local_shipping,
    },
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _promoCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state is CartLoaded) {
                    final totalPrice = state.cartItems.fold(
                      0.0,
                      (sum, item) => sum + (item.netPrice * item.quantity),
                    );
                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Alamat Pengiriman'),
                            _buildAddressInput(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Metode Pembayaran'),
                            _buildPaymentMethodSelector(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Lokasi Penjualan'),
                            _buildPromoCodeInput(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Catatan Tambahan'),
                            _buildNotesInput(),
                            const SizedBox(height: 16),
                            _buildSectionTitle('Ringkasan Pesanan'),
                            _buildOrderSummary(state, totalPrice),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            _buildConfirmButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _addressController,
        decoration: InputDecoration(
          labelText: 'Alamat Lengkap',
          hintText: 'Masukkan alamat pengiriman',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        maxLines: 3,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Alamat tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: _paymentMethods.map((method) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _selectedPaymentMethod == method['name']
                  ? Colors.blue.shade50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),

            // child: RadioListTile<String>(
            //   value: method['name'],
            //   groupValue: _selectedPaymentMethod,
            //   onChanged: (value) {
            //     setState(() {
            //       _selectedPaymentMethod = value!;
            //     });
            //   },
            //   activeColor: Colors.blue.shade700,
            //   title: Row(
            //     children: [
            //       Icon(
            //         method['icon'],
            //         size: 24,
            //         color: _selectedPaymentMethod == method['name']
            //             ? Colors.blue.shade700
            //             : Colors.grey.shade600,
            //       ),
            //       const SizedBox(width: 12),
            //       Text(
            //         method['name'],
            //         style: GoogleFonts.montserrat(
            //           fontSize: 16,
            //           fontWeight: FontWeight.w500,
            //           color: _selectedPaymentMethod == method['name']
            //               ? Colors.blue.shade700
            //               : Colors.grey.shade800,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoCodeInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _promoCodeController,
              decoration: InputDecoration(
                hintText: 'Masukkan nama lokasi',
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // Implement promo code validation logic here
            },
            child: Text(
              'Terapkan',
              style: GoogleFonts.montserrat(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: 'Catatan Tambahan',
          hintText: 'Masukkan catatan untuk pesanan (opsional)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildOrderSummary(CartLoaded state, double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...state.cartItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.kasur} - ${item.product.ukuran} (x${item.quantity})',
                      style: GoogleFonts.montserrat(fontSize: 14),
                    ),
                  ),
                  Text(
                    FormatHelper.formatCurrency(item.netPrice * item.quantity),
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                FormatHelper.formatCurrency(totalPrice),
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartLoaded) {
          final totalPrice = state.cartItems.fold(
            0.0,
            (sum, item) => sum + (item.netPrice * item.quantity),
          );
          return Container(
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
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<CartBloc>().add(Checkout(
                        totalPrice: totalPrice,
                        promoCode: _promoCodeController.text,
                        paymentMethod: _selectedPaymentMethod,
                        shippingAddress: _addressController.text,
                      ));
                  _showSuccessDialog(context);
                }
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
                'Konfirmasi Pesanan',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Pesanan Berhasil',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Pesanan Anda telah diterima. Kami akan mengirimkan konfirmasi melalui email.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              context.read<CartBloc>().add(ClearCart());
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Kembali ke Beranda',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
