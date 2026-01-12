import 'dart:convert';
import '../../../../config/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/widgets/custom_textfield.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/styled_container.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../services/auth_service.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../widgets/checkout_dialog/checkout_dialog_widgets.dart';

class DraftDetailPage extends StatefulWidget {
  final Map<String, dynamic> draft;
  final int index;

  const DraftDetailPage({
    super.key,
    required this.draft,
    required this.index,
  });

  @override
  State<DraftDetailPage> createState() => _DraftDetailPageState();
}

class _DraftDetailPageState extends State<DraftDetailPage>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerReceiverController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _notesController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _emailController;
  late final TextEditingController _paymentAmountController;
  late final TextEditingController _repaymentDateController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _grandTotalController;

  bool _shippingSameAsCustomer = false;

  bool _isLoading = false;

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
    _paymentAmountController = registerController();
    _repaymentDateController = registerController();
    _customerAddressController = registerController();
    _grandTotalController = registerController();

    // Load draft data into controllers
    _loadDraftData();
  }

  void _loadDraftData() {
    final draft = widget.draft;

    _customerNameController.text = draft['customerName'] as String? ?? '';
    _customerPhoneController.text = draft['customerPhone'] as String? ?? '';
    _emailController.text = draft['email'] as String? ?? '';
    _customerAddressController.text = draft['customerAddress'] as String? ?? '';
    _shippingAddressController.text = draft['shippingAddress'] as String? ?? '';
    _notesController.text = draft['notes'] as String? ?? '';
    _deliveryDateController.text = draft['deliveryDate'] as String? ?? '';
    _paymentAmountController.text = draft['paymentAmount'] as String? ?? '';
    _repaymentDateController.text = draft['repaymentDate'] as String? ?? '';
    _grandTotalController.text =
        (draft['grandTotal'] as double? ?? 0.0).toString();

    _shippingSameAsCustomer = draft['isTakeAway'] as bool? ?? false;
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
          "Harap isi semua kolom yang wajib diisi dan perbaiki error",
          ToastType.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      final key = 'checkout_drafts_$userId';
      final draftStrings = prefs.getStringList(key) ?? [];

      // Get current cart items from CartBloc
      if (!mounted) return;
      final cartState = context.read<CartBloc>().state;
      List<dynamic> currentCartItems = [];

      if (cartState is CartLoaded) {
        currentCartItems = cartState.cartItems;
      }

      // Convert current cart items to serializable format
      final selectedItems = currentCartItems.map((item) {
        // Cast item to dynamic to access properties
        final cartItem = item as dynamic;
        return {
          'product': {
            'id': cartItem.product?.id ?? 0,
            'area': cartItem.product?.area ?? '',
            'channel': cartItem.product?.channel ?? '',
            'brand': cartItem.product?.brand ?? '',
            'kasur': cartItem.product?.kasur ?? '',
            'divan': cartItem.product?.divan ?? '',
            'headboard': cartItem.product?.headboard ?? '',
            'sorong': cartItem.product?.sorong ?? '',
            'ukuran': cartItem.product?.ukuran ?? '',
            'pricelist': cartItem.product?.pricelist ?? 0.0,
            'program': cartItem.product?.program ?? '',
            'eupKasur': cartItem.product?.eupKasur ?? 0.0,
            'eupDivan': cartItem.product?.eupDivan ?? 0.0,
            'eupHeadboard': cartItem.product?.eupHeadboard ?? 0.0,
            'eupSorong': cartItem.product?.eupSorong ?? 0.0,
            'endUserPrice': cartItem.product?.endUserPrice ?? 0.0,
            'bonus': (cartItem.product?.bonus ?? [])
                .map((bonus) => {
                      'name': bonus?.name ?? '',
                      'quantity': bonus?.quantity ?? 0,
                      'takeAway': bonus?.takeAway ?? false,
                    })
                .toList(),
            'discounts': cartItem.product?.discounts ?? [],
            'isSet': cartItem.product?.isSet ?? false,
            'plKasur': cartItem.product?.plKasur ?? 0.0,
            'plDivan': cartItem.product?.plDivan ?? 0.0,
            'plHeadboard': cartItem.product?.plHeadboard ?? 0.0,
            'plSorong': cartItem.product?.plSorong ?? 0.0,
            'bottomPriceAnalyst': cartItem.product?.bottomPriceAnalyst ?? 0.0,
            'disc1': cartItem.product?.disc1 ?? 0.0,
            'disc2': cartItem.product?.disc2 ?? 0.0,
            'disc3': cartItem.product?.disc3 ?? 0.0,
            'disc4': cartItem.product?.disc4 ?? 0.0,
            'disc5': cartItem.product?.disc5 ?? 0.0,
          },
          'quantity': cartItem.quantity ?? 0,
          'netPrice': cartItem.netPrice ?? 0.0,
          'discountPercentages': cartItem.discountPercentages ?? [],
          'isSelected': cartItem.isSelected ?? false,
        };
      }).toList();

      // Preserve the original savedAt to find the draft in SharedPreferences
      final originalSavedAt = widget.draft['savedAt'] as String?;
      if (originalSavedAt == null) {
        CustomToast.showToast(
            'Gagal menyimpan draft: Data tidak valid', ToastType.error);
        return;
      }

      final updatedDraft = {
        'customerName': _customerNameController.text,
        'customerPhone': _customerPhoneController.text,
        'email': _emailController.text,
        'customerAddress': _customerAddressController.text,
        'shippingAddress': _shippingAddressController.text,
        'notes': _notesController.text,
        'deliveryDate': _deliveryDateController.text,
        'paymentAmount': _paymentAmountController.text,
        'repaymentDate': _repaymentDateController.text,
        'selectedItems': selectedItems,
        'grandTotal': double.tryParse(_grandTotalController.text) ?? 0.0,
        'isTakeAway': _shippingSameAsCustomer,
        'savedAt': originalSavedAt,
      };

      // Find and update draft by savedAt (unique identifier) instead of index
      int foundIndex = -1;
      for (int i = 0; i < draftStrings.length; i++) {
        try {
          final draft = jsonDecode(draftStrings[i]) as Map<String, dynamic>;
          if (draft['savedAt'] == originalSavedAt) {
            foundIndex = i;
            break;
          }
        } catch (e) {
          // Skip invalid draft data
          continue;
        }
      }

      if (foundIndex != -1) {
        draftStrings[foundIndex] = jsonEncode(updatedDraft);
        await prefs.setStringList(key, draftStrings);
        if (mounted) {
          CustomToast.showToast('Draft berhasil diupdate', ToastType.success);
          Navigator.pop(context);
        }
      } else {
        CustomToast.showToast('Draft tidak ditemukan', ToastType.error);
      }
    } catch (e) {
      CustomToast.showToast('Gagal menyimpan draft: $e', ToastType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface),
        ),
        title: Text(
          'Edit Draft Checkout',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveDraft,
              child: Text(
                'Simpan',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with summary - menggunakan StyledContainer.primary
                StyledContainer.primary(
                  padding: const EdgeInsets.all(16),
                  borderWidth: 1,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppPadding.p12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Draft Checkout',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Terakhir di edit: ${FormatHelper.formatSimpleDate(DateTime.parse(widget.draft['savedAt'] as String))}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppPadding.p24),

                // Customer Information Section
                SectionHeader(
                  icon: Icons.person_rounded,
                  title: 'Informasi Customer',
                  iconColor: colorScheme.primary,
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _customerNameController,
                  labelText: 'Nama Customer *',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama customer wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _customerPhoneController,
                  labelText: 'Nomor Telepon *',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _customerAddressController,
                  labelText: 'Alamat Customer',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: AppPadding.p24),

                // Order Information Section
                SectionHeader(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Informasi Pesanan',
                  iconColor: colorScheme.primary,
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _grandTotalController,
                  labelText: 'Total Harga *',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Total harga wajib diisi';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Total harga harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _notesController,
                  labelText: 'Catatan',
                  prefixIcon: Icons.note_rounded,
                  maxLines: 3,
                ),

                const SizedBox(height: AppPadding.p24),

                // Delivery Information Section
                SectionHeader(
                  icon: Icons.local_shipping_rounded,
                  title: 'Informasi Pengiriman',
                  iconColor: colorScheme.primary,
                ),
                const SizedBox(height: AppPadding.p12),

                Row(
                  children: [
                    Expanded(
                      child: DeliveryOption(
                        title: 'Pengiriman',
                        icon: Icons.local_shipping_rounded,
                        isSelected: !_shippingSameAsCustomer,
                        onTap: () => setState(() => _shippingSameAsCustomer = false),
                      ),
                    ),
                    const SizedBox(width: AppPadding.p12),
                    Expanded(
                      child: DeliveryOption(
                        title: 'Bawa Langsung',
                        icon: Icons.store_rounded,
                        isSelected: _shippingSameAsCustomer,
                        onTap: () => setState(() => _shippingSameAsCustomer = true),
                      ),
                    ),
                  ],
                ),

                if (!_shippingSameAsCustomer) ...[
                  const SizedBox(height: AppPadding.p12),
                  CustomTextField(
                    controller: _customerReceiverController,
                    labelText: 'Nama Penerima',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: AppPadding.p12),
                  CustomTextField(
                    controller: _shippingAddressController,
                    labelText: 'Alamat Pengiriman',
                    prefixIcon: Icons.location_on_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppPadding.p12),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        _deliveryDateController.text =
                            FormatHelper.formatSimpleDate(date);
                      }
                    },
                    child: CustomTextField(
                      controller: _deliveryDateController,
                      labelText: 'Tanggal Pengiriman',
                      prefixIcon: Icons.calendar_today_rounded,
                      enabled: false,
                    ),
                  ),
                ],

                const SizedBox(height: AppPadding.p24),

                // Payment Information Section
                SectionHeader(
                  icon: Icons.payment_rounded,
                  title: 'Informasi Pembayaran',
                  iconColor: colorScheme.primary,
                ),
                const SizedBox(height: AppPadding.p12),

                CustomTextField(
                  controller: _paymentAmountController,
                  labelText: 'Jumlah Pembayaran',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppPadding.p12),

                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      _repaymentDateController.text =
                          FormatHelper.formatSimpleDate(date);
                    }
                  },
                  child: CustomTextField(
                    controller: _repaymentDateController,
                    labelText: 'Tanggal Pelunasan',
                    prefixIcon: Icons.calendar_today_rounded,
                    enabled: false,
                  ),
                ),

                const SizedBox(height: AppPadding.p32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDraft,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: AppPadding.p12),
                              Text(
                                'Menyimpan...',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppPadding.p24),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
