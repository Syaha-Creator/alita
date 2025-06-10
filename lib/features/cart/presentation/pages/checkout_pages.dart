// File: lib/features/cart/presentation/pages/checkout_pages.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/pdf_services.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

class CheckoutPages extends StatefulWidget {
  const CheckoutPages({super.key});

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  // Using mixin for automatic disposal
  late final TextEditingController _addressController;
  late final TextEditingController _promoCodeController;
  late final TextEditingController _notesController;
  late final TextEditingController _customerNameController;

  String _selectedPaymentMethod = 'Transfer Bank';
  bool _isGeneratingPDF = false;

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
  void initState() {
    super.initState();

    // Register controllers for auto-disposal
    _addressController = registerController();
    _promoCodeController = registerController();
    _notesController = registerController();
    _customerNameController = registerController();
  }

  Future<void> _generateAndSharePDF(
      List<CartEntity> selectedItems, double totalPrice) async {
    try {
      setState(() => _isGeneratingPDF = true);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(AppPadding.p20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Membuat PDF...'),
              ],
            ),
          ),
        ),
      );

      // Generate PDF
      final Uint8List pdfBytes = await PDFService.generateCheckoutPDF(
        cartItems: selectedItems,
        totalPrice: totalPrice,
        customerInfo: _customerNameController.text,
        paymentMethod: _selectedPaymentMethod,
        shippingAddress: _addressController.text,
        promoCode: _promoCodeController.text,
        notes: _notesController.text,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show PDF options dialog
      _showPDFOptionsDialog(pdfBytes);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        CustomToast.showToast(
          'Gagal membuat PDF: $e',
          ToastType.error,
        );
      }
    } finally {
      setState(() => _isGeneratingPDF = false);
    }
  }

  void _showPDFOptionsDialog(Uint8List pdfBytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'PDF Berhasil Dibuat',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Invoice checkout telah dibuat dalam format PDF. Pilih aksi yang ingin dilakukan:',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                final filePath = await PDFService.savePDFToDevice(pdfBytes);
                CustomToast.showToast(
                  'PDF disimpan di: ${filePath.split('/').last}',
                  ToastType.success,
                );
              } catch (e) {
                CustomToast.showToast(
                  'Gagal menyimpan PDF: $e',
                  ToastType.error,
                );
              }
            },
            child: Text('Simpan'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                final fileName =
                    'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
                await PDFService.sharePDF(pdfBytes, fileName);
                CustomToast.showToast(
                  'PDF siap dibagikan',
                  ToastType.success,
                );
              } catch (e) {
                CustomToast.showToast(
                  'Gagal membagikan PDF: $e',
                  ToastType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Bagikan',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                    final selectedItems = state.selectedItems;
                    final totalPrice = selectedItems.fold(
                      0.0,
                      (sum, item) => sum + (item.netPrice * item.quantity),
                    );
                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppPadding.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Informasi Pelanggan'),
                            _buildCustomerNameInput(),
                            const SizedBox(height: 16),
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
                            _buildOrderSummary(selectedItems, totalPrice),
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

  Widget _buildCustomerNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _customerNameController,
        decoration: InputDecoration(
          labelText: 'Nama Pelanggan',
          hintText: 'Masukkan nama pelanggan',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Nama pelanggan tidak boleh kosong';
          }
          return null;
        },
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
      padding: const EdgeInsets.all(AppPadding.p8),
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
            child: RadioListTile<String>(
              value: method['name'],
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              activeColor: Colors.blue.shade700,
              title: Row(
                children: [
                  Icon(
                    method['icon'],
                    size: 24,
                    color: _selectedPaymentMethod == method['name']
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    method['name'],
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedPaymentMethod == method['name']
                          ? Colors.blue.shade700
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromoCodeInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.p8, vertical: AppPadding.p8),
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

  Widget _buildOrderSummary(List<CartEntity> selectedItems, double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...selectedItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppPadding.p8),
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
            padding: const EdgeInsets.all(AppPadding.p16),
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
              onPressed: _isGeneratingPDF
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _showCheckoutConfirmationDialog(
                            context, state, totalPrice);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isGeneratingPDF ? Colors.grey : Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 56),
                elevation: 8,
              ),
              child: _isGeneratingPDF
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Memproses...',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : Text(
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

  void _showCheckoutConfirmationDialog(
      BuildContext context, CartLoaded state, double totalPrice) {
    final selectedItems = state.selectedItems;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Konfirmasi Checkout',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total: ${FormatHelper.formatCurrency(totalPrice)}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Apakah Anda ingin melanjutkan checkout dan membuat invoice PDF?',
              style: GoogleFonts.montserrat(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Checkout without PDF
              Navigator.pop(ctx);
              context.read<CartBloc>().add(Checkout(
                    totalPrice: totalPrice,
                    promoCode: _promoCodeController.text,
                    paymentMethod: _selectedPaymentMethod,
                    shippingAddress: _addressController.text,
                  ));
              _showSuccessDialog(context, false);
            },
            child: Text('Checkout Saja'),
          ),
          ElevatedButton(
            onPressed: () {
              // Checkout with PDF
              Navigator.pop(ctx);
              context.read<CartBloc>().add(Checkout(
                    totalPrice: totalPrice,
                    promoCode: _promoCodeController.text,
                    paymentMethod: _selectedPaymentMethod,
                    shippingAddress: _addressController.text,
                  ));
              _generateAndSharePDF(selectedItems, totalPrice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: Text(
              'Checkout + PDF',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, bool withPDF) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Pesanan Berhasil',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        content: Text(
          withPDF
              ? 'Pesanan Anda telah diterima dan invoice PDF telah dibuat.'
              : 'Pesanan Anda telah diterima. Kami akan mengirimkan konfirmasi melalui email.',
          style: GoogleFonts.montserrat(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
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
