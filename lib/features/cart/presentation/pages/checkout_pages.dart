import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/checkout_service.dart';
import '../../../../services/auth_service.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/cart_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import 'draft_checkout_page.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Konversi ke double dan format
    double value = double.parse(cleaned);
    String formatted = FormatHelper.formatTextFieldCurrency(cleaned);

    // Hitung posisi cursor yang benar
    int cursorPosition = formatted.length;
    if (newValue.selection.baseOffset < newValue.text.length) {
      // Jika user mengetik di tengah, coba pertahankan posisi relatif
      int oldLength = oldValue.text.length;
      int newLength = formatted.length;
      int oldCursor = newValue.selection.baseOffset;

      if (oldLength > 0) {
        double ratio = oldCursor / oldLength;
        cursorPosition = (ratio * newLength).round();
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

class PaymentMethod {
  final String type;
  final String name;
  final double amount;
  final String? reference;
  final String receiptImagePath; // Changed from optional to required

  PaymentMethod({
    required this.type,
    required this.name,
    required this.amount,
    this.reference,
    required this.receiptImagePath, // Now required
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'amount': amount,
      'reference': reference,
      'receiptImagePath': receiptImagePath,
    };
  }
}

class CheckoutPages extends StatefulWidget {
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? userAddress;
  final bool isTakeAway;
  final bool isExistingCustomer;

  const CheckoutPages({
    super.key,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.isTakeAway = false,
    this.isExistingCustomer = false,
  });

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerReceiverController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _notesController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _emailController;
  late final TextEditingController _customerAddressController;
  bool _shippingSameAsCustomer = false;

  // Payment related variables
  String _paymentType = 'full'; // 'full' or 'partial'
  final List<PaymentMethod> _paymentMethods = [];
  double _totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _customerNameController = registerController();
    _customerPhoneController = registerController();
    _emailController = registerController();
    _customerReceiverController = registerController();
    _shippingAddressController = registerController();
    _notesController = registerController();
    _deliveryDateController = registerController();
    _customerAddressController = registerController();

    if (widget.userName != null) {
      _customerNameController.text = widget.userName!;
    }
    if (widget.userPhone != null) {
      _customerPhoneController.text = widget.userPhone!;
    }
    if (widget.userEmail != null) _emailController.text = widget.userEmail!;
    if (widget.userAddress != null) {
      _customerAddressController.text = widget.userAddress!;
    }
  }

  Future<void> _saveDraft(List<CartEntity> selectedItems) async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
          "Harap isi semua kolom yang wajib diisi dan perbaiki error",
          ToastType.error);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      final draft = {
        'customerName': _customerNameController.text,
        'customerPhone': _customerPhoneController.text,
        'email': _emailController.text,
        'customerAddress': _customerAddressController.text,
        'shippingAddress': _shippingAddressController.text,
        'notes': _notesController.text,
        'deliveryDate': _deliveryDateController.text,
        'selectedItems': selectedItems
            .map((item) => {
                  'product': {
                    'id': item.product.id,
                    'kasur': item.product.kasur,
                    'ukuran': item.product.ukuran,
                    'brand': item.product.brand,
                    'pricelist': item.product.pricelist,
                  },
                  'quantity': item.quantity,
                  'netPrice': item.netPrice,
                })
            .toList(),
        'grandTotal': selectedItems.fold(
            0.0, (sum, item) => sum + (item.netPrice * item.quantity)),
        'isTakeAway': widget.isTakeAway,
        'isExistingCustomer': widget.isExistingCustomer,
        'savedAt': DateTime.now().toIso8601String(),
      };

      draftStrings.add(jsonEncode(draft));
      await prefs.setStringList(key, draftStrings);

      CustomToast.showToast('Draft berhasil disimpan', ToastType.success);
    } catch (e) {
      CustomToast.showToast('Gagal menyimpan draft: $e', ToastType.error);
    }
  }

  Future<void> _generateAndSharePDF(
      List<CartEntity> selectedItems, bool isDark) async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
          "Harap isi semua kolom yang wajib diisi dan perbaiki error",
          ToastType.error);
      return;
    }

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
                Expanded(
                  child: Text(
                    'Membuat surat pesanan dan PDF...',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create Order Letter
      final checkoutService = locator<CheckoutService>();
      final orderLetterResult = await checkoutService.createOrderLetterFromCart(
        cartItems: selectedItems,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        email: _emailController.text,
        customerAddress: _customerAddressController.text,
        shipToName: _customerReceiverController.text,
        addressShipTo: _shippingAddressController.text,
        requestDate: _deliveryDateController.text,
        note: _notesController.text,
      );

      if (orderLetterResult['success'] != true) {
        if (mounted) {
          Navigator.pop(context);
          CustomToast.showToast(
              'Gagal membuat surat pesanan: ${orderLetterResult['message']}',
              ToastType.error);
        }
        return;
      }

      if (mounted) Navigator.pop(context);

      // Show success message with order letter info
      final orderLetterId = orderLetterResult['orderLetterId'];
      final noSp = orderLetterResult['noSp'];

      if (mounted) {
        CustomToast.showToast(
            'Surat pesanan berhasil dibuat!\nNo. SP: $noSp', ToastType.success);

        // Clear selected items from cart
        context.read<CartBloc>().add(ClearCart());

        // Navigate back to product page
        Navigator.of(context).popUntil(
            (route) => route.isFirst || route.settings.name == '/product');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomToast.showToast(
            'Gagal membuat surat pesanan: $e', ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DraftCheckoutPage(),
                ),
              );
            },
            icon: Icon(
              Icons.drafts_outlined,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            final selectedItems = state.selectedItems;
            final grandTotal = selectedItems.fold(
                0.0, (sum, item) => sum + (item.netPrice * item.quantity));

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Header Summary Card
                  _buildHeaderSummary(selectedItems, grandTotal, isDark),

                  const SizedBox(height: 20),

                  // Customer Info Section
                  _buildCustomerInfoSection(isDark),

                  const SizedBox(height: 20),

                  // Shipping Info Section
                  _buildShippingInfoSection(isDark),

                  const SizedBox(height: 20),

                  // Order Summary Section
                  _buildOrderSummarySection(selectedItems, grandTotal, isDark),

                  const SizedBox(height: 20),

                  // Payment Section
                  _buildPaymentSection(selectedItems, grandTotal, isDark),

                  const SizedBox(height: 20), // Space for bottom button
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoaded) {
            final selectedItems = state.selectedItems;
            final grandTotal = selectedItems.fold(
                0.0, (sum, item) => sum + (item.netPrice * item.quantity));
            return _buildBottomButton(selectedItems, grandTotal, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderSummary(
      List<CartEntity> selectedItems, double grandTotal, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? AppColors.primaryDark.withOpacity(0.1)
                : AppColors.primaryLight.withOpacity(0.05),
            isDark
                ? AppColors.primaryDark.withOpacity(0.05)
                : AppColors.primaryLight.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withOpacity(0.2)
              : AppColors.primaryLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withOpacity(0.8)
              : AppColors.surfaceLight.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.surfaceLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan Pesanan',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.surfaceLight : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedItems.length} item • Total: ${FormatHelper.formatCurrency(grandTotal)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.isExistingCustomer) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_user,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Customer Existing',
                      style: GoogleFonts.montserrat(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informasi Customer',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildModernTextField(
                    controller: _customerNameController,
                    label: 'Nama Customer',
                    icon: Icons.person,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Nama customer wajib diisi'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _customerPhoneController,
                    label: 'Nomor Telepon',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Nomor telepon wajib diisi'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(val)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _customerAddressController,
                    label: 'Alamat Customer',
                    icon: Icons.location_on,
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Alamat customer wajib diisi'
                        : null,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pengiriman',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildModernTextField(
                  controller: _customerReceiverController,
                  label: 'Nama Penerima',
                  icon: Icons.person_pin,
                  validator: (val) => val == null || val.isEmpty
                      ? 'Nama penerima wajib diisi'
                      : null,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                if (!widget.isTakeAway) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Alamat pengiriman sama dengan alamat customer',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: isDark ? AppColors.surfaceLight : Colors.black,
                      ),
                    ),
                    value: _shippingSameAsCustomer,
                    onChanged: (val) {
                      setState(() {
                        _shippingSameAsCustomer = val ?? false;
                        if (_shippingSameAsCustomer) {
                          _shippingAddressController.text =
                              _customerAddressController.text;
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  _buildModernTextField(
                    controller: _shippingAddressController,
                    label: 'Alamat Pengiriman',
                    icon: Icons.location_on,
                    maxLines: 3,
                    validator: (val) => val == null || val.isEmpty
                        ? 'Alamat pengiriman wajib diisi'
                        : null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      _deliveryDateController.text =
                          FormatHelper.formatSimpleDate(picked);
                      _formKey.currentState?.validate();
                    }
                  },
                  child: _buildModernTextField(
                    controller: _deliveryDateController,
                    label: 'Tanggal Pengiriman',
                    icon: Icons.calendar_today,
                    enabled: false,
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Tanggal kirim wajib diisi';
                      }
                      return null;
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _notesController,
                  label: 'Catatan (Opsional)',
                  icon: Icons.note,
                  maxLines: 3,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(
      List<CartEntity> selectedItems, double grandTotal, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    size: 20),
                const SizedBox(width: 8),
                Text(
                  'Detail Pesanan',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...selectedItems.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.kasur,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.surfaceLight
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity} × ${FormatHelper.formatCurrency(item.netPrice)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            FormatHelper.formatCurrency(
                                item.netPrice * item.quantity),
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pesanan',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.surfaceLight : Colors.black,
                        ),
                      ),
                      Text(
                        FormatHelper.formatCurrency(grandTotal),
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: GoogleFonts.montserrat(
        fontSize: 14,
        color: isDark ? AppColors.surfaceLight : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: GoogleFonts.montserrat(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        errorStyle: GoogleFonts.montserrat(
          color: Colors.red,
          fontSize: 12,
        ),
        filled: true,
        fillColor: enabled
            ? (isDark ? AppColors.cardDark : AppColors.surfaceLight)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
      ),
    );
  }

  Widget _buildPaymentSection(
      List<CartEntity> selectedItems, double grandTotal, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payment_outlined,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pembayaran',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Type Selection
                Text(
                  'Tipe Pembayaran',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentTypeOption(
                        title: 'Lunas',
                        subtitle: 'Bayar penuh',
                        isSelected: _paymentType == 'full',
                        onTap: () => setState(() {
                          _paymentType = 'full';
                          _paymentMethods.clear();
                          _totalPaid = 0.0;
                        }),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentTypeOption(
                        title: 'Cicilan',
                        subtitle: 'Bayar sebagian',
                        isSelected: _paymentType == 'partial',
                        onTap: () => setState(() {
                          _paymentType = 'partial';
                          _paymentMethods.clear();
                          _totalPaid = 0.0;
                        }),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Payment Methods
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? AppColors.surfaceLight : Colors.black,
                          ),
                        ),
                        Text(
                          '* Struk pembayaran wajib diisi',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showPaymentMethodDialog(grandTotal, isDark),
                      icon: Icon(
                        Icons.add,
                        size: 16,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      label: Text(
                        'Tambah',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Methods List
                if (_paymentMethods.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Belum ada metode pembayaran',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._paymentMethods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final payment = entry.value;
                    return _buildPaymentMethodCard(payment, index, isDark);
                  }),

                const SizedBox(height: 16),

                // Payment Summary
                if (_paymentMethods.isNotEmpty)
                  _buildPaymentSummary(grandTotal, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.1)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    : (isDark ? AppColors.surfaceLight : Colors.black),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: isSelected
                    ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withOpacity(0.8)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(
      PaymentMethod payment, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getPaymentIcon(payment.type),
              size: 16,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.surfaceLight : Colors.black,
                  ),
                ),
                if (payment.reference != null && payment.reference!.isNotEmpty)
                  Text(
                    'Ref: ${payment.reference}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                // Always show receipt indicator since it's now required
                Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Struk tersedia',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            FormatHelper.formatCurrency(payment.amount),
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 8),
          // Always show view receipt button since receipt is now required
          IconButton(
            onPressed: () =>
                _showReceiptImage(payment.receiptImagePath, isDark),
            icon: Icon(
              Icons.visibility,
              size: 18,
              color: AppColors.success,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removePaymentMethod(index),
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.red[400],
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(double grandTotal, bool isDark) {
    _totalPaid =
        _paymentMethods.fold(0.0, (sum, payment) => sum + payment.amount);
    final remaining = grandTotal - _totalPaid;
    final isFullyPaid = _totalPaid >= grandTotal;
    final isOverPaid = _totalPaid > grandTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFullyPaid
              ? AppColors.success.withOpacity(0.3)
              : isOverPaid
                  ? AppColors.warning.withOpacity(0.3)
                  : (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                      .withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pesanan',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                FormatHelper.formatCurrency(grandTotal),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.surfaceLight : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Dibayar',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                FormatHelper.formatCurrency(_totalPaid),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFullyPaid
                      ? AppColors.success
                      : isOverPaid
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFullyPaid
                    ? 'Lunas'
                    : isOverPaid
                        ? 'Kelebihan'
                        : 'Sisa Pembayaran',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isFullyPaid
                      ? AppColors.success
                      : isOverPaid
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight),
                ),
              ),
              Text(
                isFullyPaid
                    ? '✓'
                    : FormatHelper.formatCurrency(remaining.abs()),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isFullyPaid
                      ? AppColors.success
                      : isOverPaid
                          ? AppColors.warning
                          : (isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight),
                ),
              ),
            ],
          ),
          // Payment Status Indicator
          if (!isFullyPaid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                          .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tambahkan pembayaran untuk melanjutkan',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type) {
      case 'bri':
        return Icons.account_balance;
      case 'bca':
        return Icons.account_balance;
      case 'mandiri':
        return Icons.account_balance;
      case 'bni':
        return Icons.account_balance;
      case 'btn':
        return Icons.account_balance;
      case 'credit_card':
        return Icons.credit_card;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  void _removePaymentMethod(int index) {
    setState(() {
      _paymentMethods.removeAt(index);
    });
  }

  bool _isPaymentComplete(double grandTotal) {
    if (_paymentMethods.isEmpty) return false;

    _totalPaid =
        _paymentMethods.fold(0.0, (sum, payment) => sum + payment.amount);
    return _totalPaid >= grandTotal;
  }

  String _getPaymentStatusText(double grandTotal) {
    if (_paymentMethods.isEmpty) {
      return 'Belum ada pembayaran';
    }

    _totalPaid =
        _paymentMethods.fold(0.0, (sum, payment) => sum + payment.amount);
    final remaining = grandTotal - _totalPaid;

    if (_totalPaid >= grandTotal) {
      return 'Pembayaran lengkap';
    } else {
      return 'Sisa: ${FormatHelper.formatCurrency(remaining)}';
    }
  }

  void _showPaymentMethodDialog(double grandTotal, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodDialog(
        grandTotal: grandTotal,
        isDark: isDark,
        existingPayments: _paymentMethods,
        onPaymentAdded: (payment) {
          setState(() {
            _paymentMethods.add(payment);
          });
        },
      ),
    );
  }

  void _showReceiptImage(String imagePath, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Foto Struk Pembayaran',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : AppColors.cardLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[400],
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gagal memuat gambar',
                                style: GoogleFonts.montserrat(
                                  color: Colors.red[400],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      List<CartEntity> selectedItems, double grandTotal, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total Summary Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primaryDark.withOpacity(0.2)
                        : AppColors.primaryLight.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pesanan',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FormatHelper.formatCurrency(grandTotal),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryDark.withOpacity(0.1)
                            : AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Draft Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveDraft(selectedItems),
                      icon: Icon(
                        Icons.save_outlined,
                        size: 16,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                      ),
                      label: Text(
                        'Simpan Draft',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primaryLight,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Main Action Button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isPaymentComplete(grandTotal)
                          ? () => _generateAndSharePDF(selectedItems, isDark)
                          : null,
                      icon: Icon(
                        _isPaymentComplete(grandTotal)
                            ? Icons.shopping_cart_checkout
                            : Icons.lock,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isPaymentComplete(grandTotal)
                            ? 'Buat Surat Pesanan'
                            : _getPaymentStatusText(grandTotal),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaymentComplete(grandTotal)
                            ? (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
                            : Colors.grey[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: _isPaymentComplete(grandTotal) ? 3 : 0,
                        shadowColor: isDark
                            ? AppColors.primaryDark.withOpacity(0.4)
                            : AppColors.primaryLight.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodDialog extends StatefulWidget {
  final double grandTotal;
  final bool isDark;
  final Function(PaymentMethod) onPaymentAdded;
  final List<PaymentMethod> existingPayments;

  const _PaymentMethodDialog({
    required this.grandTotal,
    required this.isDark,
    required this.onPaymentAdded,
    required this.existingPayments,
  });

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _selectedType = 'bri';
  String? _receiptImagePath;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  // Calculate remaining amount to be paid
  double _getRemainingAmount() {
    final totalPaid = widget.existingPayments
        .fold(0.0, (sum, payment) => sum + payment.amount);
    return widget.grandTotal - totalPaid;
  }

  // Get hint text based on remaining amount
  String _getAmountHintText() {
    final remaining = _getRemainingAmount();
    return FormatHelper.formatCurrency(remaining);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payment_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Pembayaran',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pilih metode dan jumlah pembayaran',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: widget.isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment Method Selection
                    Text(
                      'Metode Pembayaran',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: widget.isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'bri', child: Text('BRI')),
                        DropdownMenuItem(value: 'bca', child: Text('BCA')),
                        DropdownMenuItem(
                            value: 'mandiri', child: Text('Bank Mandiri')),
                        DropdownMenuItem(value: 'bni', child: Text('BNI')),
                        DropdownMenuItem(value: 'btn', child: Text('BTN')),
                        DropdownMenuItem(
                            value: 'credit_card', child: Text('Kartu Kredit')),
                        DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                        DropdownMenuItem(
                            value: 'other', child: Text('Lainnya')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Jumlah Pembayaran',
                        hintText: _getAmountHintText(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: widget.isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jumlah pembayaran wajib diisi';
                        }
                        final amount =
                            FormatHelper.parseCurrencyToDouble(value);
                        if (amount <= 0) {
                          return 'Jumlah pembayaran tidak valid';
                        }
                        final remaining = _getRemainingAmount();
                        if (amount > remaining) {
                          return 'Jumlah tidak boleh melebihi sisa pembayaran (${FormatHelper.formatCurrency(remaining)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Receipt Image Upload
                    Text(
                      'Foto Struk Pembayaran *',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? AppColors.cardDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _receiptImagePath != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_receiptImagePath!),
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return _buildImagePlaceholder();
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: _removeReceiptImage,
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reference Input (Optional)
                    TextFormField(
                      controller: _referenceController,
                      decoration: InputDecoration(
                        labelText: 'Referensi/No. Transaksi (Opsional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: widget.isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              side: BorderSide(
                                color: widget.isDark
                                    ? AppColors.primaryDark
                                    : AppColors.primaryLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primaryLight,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Tambah',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate receipt image is required
      if (_receiptImagePath == null || _receiptImagePath!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto struk pembayaran wajib diisi',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final amount = FormatHelper.parseCurrencyToDouble(_amountController.text);
      final reference = _referenceController.text.trim();

      final payment = PaymentMethod(
        type: _selectedType,
        name: _getPaymentName(_selectedType),
        amount: amount,
        reference: reference.isEmpty ? null : reference,
        receiptImagePath: _receiptImagePath!,
      );

      widget.onPaymentAdded(payment);
      Navigator.pop(context);
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap untuk ambil foto atau pilih dari galeri',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Struk pembayaran wajib diisi',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            // Options
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              title: Text(
                'Ambil Foto',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Gunakan kamera untuk mengambil foto struk',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: widget.isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                  size: 24,
                ),
              ),
              title: Text(
                'Pilih dari Galeri',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Pilih foto struk dari galeri',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_open,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              title: Text(
                'Pilih File',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                'Pilih file gambar dari penyimpanan',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickReceiptImageFromFile();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _saveImageFile(image.path);
      }
    } catch (e) {
      print('Image picker failed: $e');
      CustomToast.showToast(
          'Gagal mengambil foto: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _pickReceiptImageFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          await _saveImageFile(filePath);
        }
      }
    } catch (e) {
      print('File picker failed: $e');
      CustomToast.showToast(
          'Gagal memilih file: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _saveImageFile(String sourcePath) async {
    try {
      // Save image to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      // Compress image to approximately 150KB
      await _compressImage(sourcePath, filePath);

      setState(() {
        _receiptImagePath = filePath;
      });

      CustomToast.showToast('Foto struk berhasil diupload', ToastType.success);
    } catch (e) {
      print('Error saving image: $e');
      CustomToast.showToast(
          'Gagal menyimpan gambar: ${e.toString()}', ToastType.error);
    }
  }

  Future<void> _compressImage(String sourcePath, String targetPath) async {
    try {
      // Read the image file
      final File sourceFile = File(sourcePath);
      final Uint8List imageBytes = await sourceFile.readAsBytes();

      // Decode the image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate target size (150KB = 153,600 bytes)
      const int targetSizeBytes = 150 * 1024;

      // Start with high quality and reduce until we reach target size
      int quality = 95;
      Uint8List compressedBytes = Uint8List(0);

      while (quality > 10) {
        // Encode with current quality
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(originalImage, quality: quality));

        // Check if we're within target size
        if (compressedBytes.length <= targetSizeBytes) {
          break;
        }

        // Reduce quality by 10
        quality -= 10;
      }

      // If still too large, try resizing the image
      if (compressedBytes.length > targetSizeBytes) {
        // Calculate resize factor based on current size vs target
        double resizeFactor =
            math.sqrt(targetSizeBytes / compressedBytes.length);

        // Calculate new dimensions
        int newWidth = (originalImage.width * resizeFactor).round();
        int newHeight = (originalImage.height * resizeFactor).round();

        // Ensure minimum dimensions
        newWidth = math.max(newWidth, 200);
        newHeight = math.max(newHeight, 200);

        // Resize the image
        final img.Image resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
        );

        // Encode with good quality
        compressedBytes =
            Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
      }

      // Write compressed image to target path
      final File targetFile = File(targetPath);
      await targetFile.writeAsBytes(compressedBytes);

      print(
          'Image compressed: ${compressedBytes.length} bytes (target: $targetSizeBytes bytes)');
    } catch (e) {
      print('Error compressing image: $e');
      // Fallback: copy original file if compression fails
      final File sourceFile = File(sourcePath);
      final File targetFile = File(targetPath);
      await sourceFile.copy(targetPath);
    }
  }

  void _removeReceiptImage() {
    setState(() {
      _receiptImagePath = null;
    });
  }

  String _getPaymentName(String type) {
    switch (type) {
      case 'bri':
        return 'BRI';
      case 'bca':
        return 'BCA';
      case 'mandiri':
        return 'Bank Mandiri';
      case 'bni':
        return 'BNI';
      case 'btn':
        return 'BTN';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'cash':
        return 'Tunai';
      default:
        return 'Lainnya';
    }
  }
}
