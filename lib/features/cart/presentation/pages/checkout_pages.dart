import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/pdf_services.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';

class CheckoutPages extends StatefulWidget {
  const CheckoutPages({super.key});

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _showroomController;
  late final TextEditingController _notesController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _emailController;
  late final TextEditingController _paymentAmountController;
  late final TextEditingController _repaymentDateController;

  bool _isGeneratingPDF = false;
  String _selectedPaymentMethod = 'Tunai';

  @override
  void initState() {
    super.initState();
    _customerNameController = registerController();
    _customerPhoneController = registerController();
    _shippingAddressController = registerController();
    _showroomController = registerController();
    _notesController = registerController();
    _deliveryDateController = registerController();
    _emailController = registerController();
    _paymentAmountController = registerController();
    _repaymentDateController = registerController();
  }

  Future<void> _generateAndSharePDF(
      List<CartEntity> selectedItems, bool isDark) async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
          "Harap isi semua kolom yang wajib diisi dan perbaiki error",
          ToastType.error);
      return;
    }

    setState(() => _isGeneratingPDF = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: isDark ? AppColors.accentDark : AppColors.accentLight,
                ),
                const SizedBox(width: 16),
                Text(
                  'Membuat PDF...',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      final String? salesName = await AuthService.getCurrentUserName();
      final double paymentAmount =
          FormatHelper.parseCurrencyToDouble(_paymentAmountController.text);

      final Uint8List pdfBytes = await PDFService.generateCheckoutPDF(
        cartItems: selectedItems,
        customerName: _customerNameController.text,
        phoneNumber: _customerPhoneController.text,
        shippingAddress: _shippingAddressController.text,
        showroom: _showroomController.text,
        keterangan: _notesController.text,
        salesName: salesName ?? "Sales",
        deliveryDate: _deliveryDateController.text,
        email: _emailController.text,
        paymentMethod: _selectedPaymentMethod,
        paymentAmount: paymentAmount,
        repaymentDate: _repaymentDateController.text,
      );

      if (mounted) Navigator.pop(context);

      _showPDFOptionsDialog(pdfBytes);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomToast.showToast('Gagal membuat PDF: $e', ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPDF = false);
      }
    }
  }

  void _showPDFOptionsDialog(Uint8List pdfBytes) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'PDF Berhasil Dibuat',
          style: TextStyle(
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'Pilih aksi yang ingin dilakukan:',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                final filePath = await PDFService.savePDFToDevice(pdfBytes);
                CustomToast.showToast(
                    'PDF disimpan di: ${filePath.split('/').last}',
                    ToastType.success);
              } catch (e) {
                CustomToast.showToast(
                    'Gagal menyimpan PDF: $e', ToastType.error);
              }
            },
            child: Text(
              'Simpan',
              style: TextStyle(
                color: isDark ? AppColors.accentDark : AppColors.accentLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                Navigator.pop(ctx);
                await PDFService.sharePDF(pdfBytes,
                    'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
              } catch (e) {
                CustomToast.showToast(
                    'Gagal membagikan PDF: $e', ToastType.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.buttonDark : AppColors.buttonLight,
            ),
            child: const Text('Bagikan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  if (state is CartLoaded) {
                    final selectedItems = state.selectedItems;
                    final subtotal = selectedItems.fold(0.0,
                        (sum, item) => sum + (item.netPrice * item.quantity));
                    final ppn = subtotal * 0.11;
                    final grandTotal = subtotal + ppn;

                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppPadding.p16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Informasi Pelanggan'),
                            CustomTextField(
                                controller: _customerNameController,
                                labelText: 'Nama Pelanggan',
                                validator: (val) =>
                                    val!.isEmpty ? 'Wajib diisi' : null),
                            const SizedBox(height: 12),
                            CustomTextField(
                                controller: _customerPhoneController,
                                labelText: 'Nomor Telepon',
                                keyboardType: TextInputType.phone,
                                validator: (val) =>
                                    val!.isEmpty ? 'Wajib diisi' : null),
                            const SizedBox(height: 12),
                            CustomTextField(
                                controller: _emailController,
                                labelText: 'Email Pelanggan (Opsional)',
                                keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Informasi Pengiriman'),
                            CustomTextField(
                                controller: _shippingAddressController,
                                labelText: 'Alamat Pengiriman',
                                maxLines: 3,
                                validator: (val) =>
                                    val!.isEmpty ? 'Wajib diisi' : null),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _deliveryDateController,
                              decoration: const InputDecoration(
                                labelText: 'Tanggal Kirim',
                                hintText: 'Pilih Tanggal (Min. H+3)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () async {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());
                                final DateTime firstSelectableDate =
                                    DateTime.now().add(const Duration(days: 3));

                                DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: firstSelectableDate,
                                    firstDate: firstSelectableDate,
                                    lastDate: DateTime(2100));
                                if (picked != null) {
                                  _deliveryDateController.text =
                                      FormatHelper.formatSimpleDate(picked);
                                  _formKey.currentState?.validate();
                                }
                              },
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Tanggal kirim wajib diisi';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Informasi Tambahan'),
                            CustomTextField(
                                controller: _showroomController,
                                labelText: 'Showroom / Pameran (Opsional)'),
                            const SizedBox(height: 12),
                            CustomTextField(
                                controller: _notesController,
                                labelText: 'Keterangan / Catatan (Opsional)',
                                maxLines: 3),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Informasi Pembayaran'),
                            _buildPaymentMethodSelector(),
                            const SizedBox(height: 16),
                            _buildPaymentAmountInput(grandTotal),
                            const SizedBox(height: 12),
                            _buildRepaymentDateInput(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Ringkasan Pesanan'),
                            _buildOrderSummary(
                                selectedItems, subtotal, ppn, grandTotal),
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

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metode Pembayaran',
          style:
              GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Tunai'),
                value: 'Tunai',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Credit Card'),
                value: 'Credit Card',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPaymentMethod = value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentAmountInput(double grandTotal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _paymentAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah Pembayaran',
              hintText: 'Masukkan jumlah yang dibayar',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixText: 'Rp ',
            ),
            onChanged: (value) {
              String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (cleaned.isNotEmpty) {
                double parsedValue = double.parse(cleaned);
                String formatted = FormatHelper.formatNumber(parsedValue);
                _paymentAmountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: formatted.length),
                  ),
                );
              } else {
                _paymentAmountController.clear();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jumlah pembayaran wajib diisi';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              side: BorderSide(color: Theme.of(context).primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lunas'),
            onPressed: () {
              final formattedGrandTotal = FormatHelper.formatNumber(grandTotal);
              _paymentAmountController.value = TextEditingValue(
                text: formattedGrandTotal,
                selection: TextSelection.fromPosition(
                  TextPosition(offset: formattedGrandTotal.length),
                ),
              );

              final formattedToday =
                  FormatHelper.formatSimpleDate(DateTime.now());
              _repaymentDateController.text = formattedToday;

              _formKey.currentState?.validate();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepaymentDateInput() {
    return TextFormField(
      controller: _repaymentDateController,
      decoration: const InputDecoration(
        labelText: 'Tanggal Pelunasan',
        hintText: 'Pilih Tanggal',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100));
        if (picked != null) {
          _repaymentDateController.text = FormatHelper.formatSimpleDate(picked);
          _formKey.currentState?.validate();
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tanggal pelunasan wajib diisi';
        }

        if (_deliveryDateController.text.isEmpty) {
          return null;
        }

        final deliveryDate =
            FormatHelper.parseSimpleDate(_deliveryDateController.text);
        final repaymentDate = FormatHelper.parseSimpleDate(value);

        if (deliveryDate == null || repaymentDate == null) {
          return 'Format tanggal tidak valid';
        }
        final deadline = deliveryDate.subtract(const Duration(days: 3));

        if (repaymentDate.isAfter(deadline)) {
          return 'Pelunasan maks. H-3 sebelum Tgl Kirim';
        }

        return null;
      },
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8.0, top: 8.0),
        child: Text(title,
            style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)),
      );

  Widget _buildOrderSummary(List<CartEntity> selectedItems, double subtotal,
      double ppn, double grandTotal) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...selectedItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child:
                              Text('${item.product.kasur} (x${item.quantity})',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ))),
                      Text(
                          FormatHelper.formatCurrency(
                              item.netPrice * item.quantity),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          )),
                    ],
                  ),
                )),
            Divider(
                height: 24,
                thickness: 0.5,
                color: isDark
                    ? AppColors.textSecondaryDark.withOpacity(0.2)
                    : AppColors.textSecondaryLight.withOpacity(0.2)),
            _buildSummaryRow('Subtotal', subtotal, isDark: isDark),
            _buildSummaryRow('PPN (11%)', ppn, isDark: isDark),
            Divider(
                height: 16,
                thickness: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark.withOpacity(0.3)
                    : AppColors.textSecondaryLight.withOpacity(0.3)),
            _buildSummaryRow('Grand Total', grandTotal,
                isGrandTotal: true, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value,
      {bool isGrandTotal = false, bool isDark = false}) {
    final style = TextStyle(
      fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
      fontSize: isGrandTotal ? 16 : 14,
      color: isGrandTotal
          ? (isDark ? AppColors.accentDark : Theme.of(context).primaryColor)
          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(FormatHelper.formatCurrency(value), style: style),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            return CustomButton(
              text: _isGeneratingPDF
                  ? 'Memproses...'
                  : 'Buat & Bagikan Surat Pesanan',
              onPressed: () =>
                  _generateAndSharePDF(state.selectedItems, isDark),
              isLoading: _isGeneratingPDF,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
