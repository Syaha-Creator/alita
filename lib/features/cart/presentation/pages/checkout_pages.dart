import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../../../../config/app_constant.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../services/enhanced_checkout_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/order_letter_contact_service.dart';
import '../../../../services/order_letter_payment_service.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
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
    String formatted = "Rp ${FormatHelper.formatCurrency(value)}";

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
  final String methodType; // BRI, BCA, Cash, etc
  final String methodName; // Display name
  final double amount;
  final String? reference;
  final String receiptImagePath; // Changed from optional to required

  PaymentMethod({
    required this.methodType,
    required this.methodName,
    required this.amount,
    this.reference,
    required this.receiptImagePath, // Now required
  });

  Map<String, dynamic> toJson() {
    return {
      'methodType': methodType,
      'methodName': methodName,
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
  final Map<String, dynamic>? draftData; // For loading existing draft

  const CheckoutPages({
    super.key,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.isTakeAway = false,
    this.isExistingCustomer = false,
    this.draftData,
  });

  // Named constructor for loading from draft
  CheckoutPages.fromDraft({
    super.key,
    required this.draftData,
  })  : userName = null,
        userPhone = null,
        userEmail = null,
        userAddress = null,
        isTakeAway = draftData?['isTakeAway'] as bool? ?? false,
        isExistingCustomer = draftData?['isExistingCustomer'] as bool? ?? false;

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerPhone2Controller;
  late final TextEditingController _customerReceiverController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _notesController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _emailController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _spgCodeController;
  bool _shippingSameAsCustomer = false;
  bool _showSecondPhone = false;

  // Payment related variables
  String _paymentType = 'full'; // 'full' or 'partial'
  final List<PaymentMethod> _paymentMethods = [];
  double _totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _customerNameController = registerController();
    _customerPhoneController = registerController();
    _customerPhone2Controller = registerController();
    _emailController = registerController();
    _customerReceiverController = registerController();
    _shippingAddressController = registerController();
    _notesController = registerController();
    _deliveryDateController = registerController();
    _customerAddressController = registerController();
    _spgCodeController = registerController();

    // Load from draft if available, otherwise use widget parameters
    if (widget.draftData != null) {
      _loadFromDraft(widget.draftData!);
    } else {
      // Load from widget parameters (existing behavior)
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
  }

  // Load all data from draft
  void _loadFromDraft(Map<String, dynamic> draft) {
    // Customer Information
    _customerNameController.text = draft['customerName'] as String? ?? '';
    _customerPhoneController.text = draft['customerPhone'] as String? ?? '';
    _customerPhone2Controller.text = draft['customerPhone2'] as String? ?? '';
    _emailController.text = draft['email'] as String? ?? '';
    _customerAddressController.text = draft['customerAddress'] as String? ?? '';
    _spgCodeController.text = draft['spgCode'] as String? ?? '';

    // Shipping Information
    _customerReceiverController.text =
        draft['customerReceiver'] as String? ?? '';
    _shippingAddressController.text = draft['shippingAddress'] as String? ?? '';
    _notesController.text = draft['notes'] as String? ?? '';
    _deliveryDateController.text = draft['deliveryDate'] as String? ?? '';
    _shippingSameAsCustomer = draft['shippingSameAsCustomer'] as bool? ?? false;
    _showSecondPhone = draft['showSecondPhone'] as bool? ?? false;

    // Payment Information
    _paymentType = draft['paymentType'] as String? ?? 'full';
    _totalPaid = draft['totalPaid'] as double? ?? 0.0;

    // Load payment methods
    final paymentMethodsData = draft['paymentMethods'] as List<dynamic>? ?? [];
    _paymentMethods.clear();
    for (final paymentData in paymentMethodsData) {
      final payment = paymentData as Map<String, dynamic>;
      _paymentMethods.add(PaymentMethod(
        methodType: payment['methodType'] as String? ??
            payment['type'] as String? ??
            '',
        methodName: payment['methodName'] as String? ??
            payment['name'] as String? ??
            '',
        amount: payment['amount'] as double? ?? 0.0,
        reference: payment['reference'] as String?,
        receiptImagePath: payment['receiptImagePath'] as String? ?? '',
      ));
    }

    // Cart items will be handled separately
    // We'll restore bonus take away states after cart is loaded
    _restoreCartItemsFromDraft(draft);

    print('Draft loaded successfully: ${draft['customerName']}');
    print('Payment methods restored: ${_paymentMethods.length}');
    print('Take away status: ${draft['isTakeAway']}');
  }

  // Restore cart items from draft data
  Future<void> _restoreCartItemsFromDraft(Map<String, dynamic> draft) async {
    try {
      final itemsData = draft['selectedItems'] as List<dynamic>? ?? [];

      print('=== RESTORING CART FROM DRAFT ===');
      print('Total items in draft: ${itemsData.length}');

      // Clear current cart first
      context.read<CartBloc>().add(ClearCart());

      // Wait a bit for cart to clear
      await Future.delayed(const Duration(milliseconds: 100));

      // Add each item back to cart with restored bonus take away data
      for (int i = 0; i < itemsData.length; i++) {
        final itemData = itemsData[i];
        print('Processing item ${i + 1}/${itemsData.length}');

        final item = itemData as Map<String, dynamic>;
        final productData = item['product'] as Map<String, dynamic>;

        print(
            'Item ${i + 1} - Product: ${productData['kasur']} ${productData['ukuran']}');
        print('Item ${i + 1} - Quantity: ${item['quantity']}');
        print('Item ${i + 1} - Net Price: ${item['netPrice']}');

        // Reconstruct bonus items
        final bonusData = productData['bonus'] as List<dynamic>? ?? [];
        final bonusItems = bonusData.map((bonus) {
          final bonusMap = bonus as Map<String, dynamic>;
          return BonusItem(
            name: bonusMap['name'] as String,
            quantity: bonusMap['quantity'] as int,
            originalQuantity: bonusMap['originalQuantity'] as int? ??
                (bonusMap['quantity'] as int),
            takeAway: bonusMap['takeAway'] as bool?,
          );
        }).toList();

        // Reconstruct product entity
        final product = ProductEntity(
          id: productData['id'] as int,
          area: '',
          channel: '',
          brand: productData['brand'] as String,
          kasur: productData['kasur'] as String,
          divan: productData['divan'] as String? ?? '',
          headboard: productData['headboard'] as String? ?? '',
          sorong: productData['sorong'] as String? ?? '',
          ukuran: productData['ukuran'] as String,
          pricelist: productData['pricelist'] as double,
          program: '',
          eupKasur: productData['eupKasur'] as double? ?? 0,
          eupDivan: productData['eupDivan'] as double? ?? 0,
          eupHeadboard: productData['eupHeadboard'] as double? ?? 0,
          eupSorong: productData['eupSorong'] as double? ?? 0,
          endUserPrice: productData['pricelist'] as double,
          bonus: bonusItems,
          discounts: [],
          isSet: false,
          plKasur: productData['plKasur'] as double? ?? 0,
          plDivan: productData['plDivan'] as double? ?? 0,
          plHeadboard: productData['plHeadboard'] as double? ?? 0,
          plSorong: productData['plSorong'] as double? ?? 0,
          bottomPriceAnalyst: 0,
          disc1: 0,
          disc2: 0,
          disc3: 0,
          disc4: 0,
          disc5: 0,
        );

        // Convert bonusTakeAway data
        final bonusTakeAwayData =
            item['bonusTakeAway'] as Map<String, dynamic>?;
        Map<String, bool>? bonusTakeAway;
        if (bonusTakeAwayData != null) {
          bonusTakeAway = bonusTakeAwayData
              .map((key, value) => MapEntry(key, value as bool));
        }

        // Add to cart with bonus take away data
        print('Adding item ${i + 1} to cart...');
        context.read<CartBloc>().add(AddToCart(
              product: product,
              quantity: item['quantity'] as int,
              netPrice: item['netPrice'] as double,
              discountPercentages:
                  (item['discountPercentages'] as List<dynamic>?)
                          ?.map((d) => d as double)
                          .toList() ??
                      [],
            ));
        print('Item ${i + 1} added to cart successfully');

        // After adding to cart, update bonus take away if needed
        if (bonusTakeAway != null && bonusTakeAway.isNotEmpty) {
          print('Updating bonus take away for item ${i + 1}');
          // Wait a bit for cart to be updated
          await Future.delayed(const Duration(milliseconds: 50));

          context.read<CartBloc>().add(UpdateBonusTakeAway(
                productId: product.id,
                netPrice: item['netPrice'] as double,
                bonusTakeAway: bonusTakeAway,
              ));
          print('Bonus take away updated for item ${i + 1}');
        }

        // Add delay between items to ensure proper processing
        await Future.delayed(const Duration(milliseconds: 100));
      }

      print('=== CART RESTORATION COMPLETED ===');
      print('Cart items restored from draft: ${itemsData.length} items');
    } catch (e) {
      print('Error restoring cart items from draft: $e');
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
        // Customer Information
        'customerName': _customerNameController.text,
        'customerPhone': _customerPhoneController.text,
        'customerPhone2': _customerPhone2Controller.text,
        'email': _emailController.text,
        'customerAddress': _customerAddressController.text,
        'spgCode': _spgCodeController.text,

        // Shipping Information
        'customerReceiver': _customerReceiverController.text,
        'shippingAddress': _shippingAddressController.text,
        'notes': _notesController.text,
        'deliveryDate': _deliveryDateController.text,
        'shippingSameAsCustomer': _shippingSameAsCustomer,
        'showSecondPhone': _showSecondPhone,

        // Cart Items with Bonus Take Away
        'selectedItems': selectedItems
            .map((item) => {
                  'product': {
                    'id': item.product.id,
                    'kasur': item.product.kasur,
                    'divan': item.product.divan,
                    'headboard': item.product.headboard,
                    'sorong': item.product.sorong,
                    'ukuran': item.product.ukuran,
                    'brand': item.product.brand,
                    'pricelist': item.product.pricelist,
                    'plKasur': item.product.plKasur,
                    'plDivan': item.product.plDivan,
                    'plHeadboard': item.product.plHeadboard,
                    'plSorong': item.product.plSorong,
                    'eupKasur': item.product.eupKasur,
                    'eupDivan': item.product.eupDivan,
                    'eupHeadboard': item.product.eupHeadboard,
                    'eupSorong': item.product.eupSorong,
                    'bonus': item.product.bonus
                        .map((bonus) => {
                              'name': bonus.name,
                              'quantity': bonus.quantity,
                              'takeAway': bonus.takeAway,
                            })
                        .toList(),
                  },
                  'quantity': item.quantity,
                  'netPrice': item.netPrice,
                  'bonusTakeAway': item.bonusTakeAway,
                  'discountPercentages': item.discountPercentages,
                })
            .toList(),

        // Payment Information
        'paymentMethods': _paymentMethods
            .map((payment) => {
                  'methodType': payment.methodType,
                  'methodName': payment.methodName,
                  'amount': payment.amount,
                  'reference': payment.reference,
                  'receiptImagePath': payment.receiptImagePath,
                })
            .toList(),
        'paymentType': _paymentType,
        'totalPaid': _totalPaid,

        // Totals
        'grandTotal': selectedItems.fold(
            0.0, (sum, item) => sum + (item.netPrice * item.quantity)),

        // Settings
        'isTakeAway': widget.isTakeAway,
        'isExistingCustomer': widget.isExistingCustomer,

        // Metadata
        'savedAt': DateTime.now().toIso8601String(),
        'version': '2.0', // Version for backward compatibility
      };

      // Check if this is updating an existing draft
      if (widget.draftData != null && widget.draftData!['savedAt'] != null) {
        // Find and replace existing draft
        final originalSavedAt = widget.draftData!['savedAt'] as String;
        final draftIndex = draftStrings.indexWhere((draftString) {
          try {
            final existingDraft =
                jsonDecode(draftString) as Map<String, dynamic>;
            return existingDraft['savedAt'] == originalSavedAt;
          } catch (e) {
            return false;
          }
        });

        if (draftIndex != -1) {
          // Replace existing draft
          draftStrings[draftIndex] = jsonEncode(draft);
          print('Updated existing draft at index $draftIndex');
        } else {
          // If not found, add as new draft
          draftStrings.add(jsonEncode(draft));
          print('Added new draft (original not found)');
        }
      } else {
        // Add new draft
        draftStrings.add(jsonEncode(draft));
        print('Added new draft');
      }

      await prefs.setStringList(key, draftStrings);

      CustomToast.showToast('Draft berhasil disimpan', ToastType.success);

      // Clear all items from cart after saving to draft
      context.read<CartBloc>().add(ClearCart());

      // Navigate to draft checkout page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DraftCheckoutPage(),
        ),
      );
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

      // Create Order Letter with Item Mapping (without phone - will be uploaded separately)
      final enhancedCheckoutService = locator<EnhancedCheckoutService>();
      final orderLetterResult =
          await enhancedCheckoutService.checkoutWithItemMapping(
        cartItems: selectedItems,
        customerName: _customerNameController.text,
        customerPhone: '', // Remove phone from order letter
        email: _emailController.text,
        customerAddress: _customerAddressController.text,
        shipToName: _customerReceiverController.text,
        addressShipTo: _shippingAddressController.text,
        spgCode: _spgCodeController.text,
        requestDate: _deliveryDateController.text,
        note: _notesController.text,
        isTakeAway: widget.isTakeAway,
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

      // Upload phone numbers using contacts API
      final orderLetterId = orderLetterResult['orderLetterId'];
      final noSp = orderLetterResult['noSp'];

      if (orderLetterId != null) {
        try {
          // Upload phone numbers
          final contactService = locator<OrderLetterContactService>();
          await contactService.uploadPhoneNumbers(
            orderLetterId: orderLetterId,
            primaryPhone: _customerPhoneController.text,
            secondaryPhone: _showSecondPhone &&
                    _customerPhone2Controller.text.trim().isNotEmpty
                ? _customerPhone2Controller.text.trim()
                : null,
          );

          // Upload payment methods if any
          if (_paymentMethods.isNotEmpty) {
            print(
                'CheckoutPage: Uploading ${_paymentMethods.length} payment methods');
            final paymentService = locator<OrderLetterPaymentService>();
            final currentUserId = await AuthService.getCurrentUserId();

            if (currentUserId != null) {
              try {
                final paymentData = _convertPaymentMethodsToApiFormat();
                print('CheckoutPage: Payment data to upload: $paymentData');

                await paymentService.uploadPaymentMethods(
                  orderLetterId: orderLetterId,
                  paymentMethods: paymentData,
                  creator: currentUserId,
                  note: 'Payment from checkout',
                );
                print('CheckoutPage: Payment methods uploaded successfully');
              } catch (paymentError) {
                print('CheckoutPage: Error uploading payments: $paymentError');
                // Show toast to user about payment upload failure
                if (mounted) {
                  CustomToast.showToast(
                    'Pembayaran gagal diupload: ${paymentError.toString()}',
                    ToastType.warning,
                  );
                }
              }
            } else {
              print('CheckoutPage: Cannot upload payments - user ID is null');
            }
          } else {
            print('CheckoutPage: No payment methods to upload');
          }
        } catch (e) {
          // Log error but don't fail the checkout
          print('Warning: Failed to upload phone numbers or payments: $e');
        }
      }

      if (mounted) {
        CustomToast.showToast(
            'Surat pesanan berhasil dibuat!\nNo. SP: $noSp', ToastType.success);

        // Clear entire cart after successful checkout
        context.read<CartBloc>().add(ClearCart());

        // Navigate to approval monitoring page to see the new order
        context.go(RoutePaths.approvalMonitoring);
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

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          title: Text(
            'Checkout',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
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

                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Customer Info Section
                    _buildCustomerInfoSection(isDark),

                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Shipping Info Section
                    _buildShippingInfoSection(isDark),

                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Order Summary Section
                    _buildOrderSummarySection(
                        selectedItems, grandTotal, isDark),

                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ),

                    // Bonus Take Away Section (only show if not take away and has bonus)
                    if (!widget.isTakeAway &&
                        selectedItems
                            .any((item) => item.product.bonus.isNotEmpty))
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
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
                              padding: ResponsiveHelper.getCardPadding(context),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.card_giftcard_outlined,
                                      color: isDark
                                          ? AppColors.primaryDark
                                          : AppColors.primaryLight,
                                      size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Opsi Pengambilan Bonus',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.surfaceLight
                                              : Colors.black,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: ResponsiveHelper.getCardPadding(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih item bonus yang ingin diambil sendiri di toko:',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...selectedItems.expand((item) {
                                    if (item.product.bonus.isEmpty) {
                                      return <Widget>[];
                                    }

                                    return item.product.bonus.map((bonus) {
                                      final isChecked =
                                          item.bonusTakeAway?[bonus.name] ??
                                              false;

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: ResponsiveHelper
                                            .getResponsivePadding(context),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.cardDark
                                              : AppColors.cardLight,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey[800]!
                                                : Colors.grey[200]!,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isChecked,
                                              onChanged: (value) {
                                                final currentTakeAway =
                                                    Map<String, bool>.from(
                                                        item.bonusTakeAway ??
                                                            {});
                                                currentTakeAway[bonus.name] =
                                                    value ?? false;

                                                context
                                                    .read<CartBloc>()
                                                    .add(UpdateBonusTakeAway(
                                                      productId:
                                                          item.product.id,
                                                      netPrice: item.netPrice,
                                                      bonusTakeAway:
                                                          currentTakeAway,
                                                    ));
                                              },
                                              activeColor: isDark
                                                  ? AppColors.primaryDark
                                                  : AppColors.primaryLight,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    bonus.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isDark
                                                              ? AppColors
                                                                  .surfaceLight
                                                              : Colors.black,
                                                        ),
                                                  ),
                                                  Text(
                                                    'Qty: ${bonus.quantity * item.quantity}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontSize: 12,
                                                          color: isDark
                                                              ? Colors.grey[400]
                                                              : Colors
                                                                  .grey[600],
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    });
                                  }),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? Colors.blue[900]
                                              : Colors.blue[50])
                                          ?.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.blue[700]!
                                            : Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: isDark
                                              ? Colors.blue[300]
                                              : Colors.blue[700],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Item yang dicentang akan diambil di toko, sisanya akan dikirim bersama pesanan utama.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.blue[300]
                                                      : Colors.blue[700],
                                                ),
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
                      ),

                    if (!widget.isTakeAway &&
                        selectedItems
                            .any((item) => item.product.bonus.isNotEmpty))
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 16,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),

                    // Payment Section
                    _buildPaymentSection(selectedItems, grandTotal, isDark),

                    SizedBox(
                      height: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 16,
                        tablet: 20,
                        desktop: 24,
                      ),
                    ), // Space for bottom button
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.surfaceLight
                                  : Colors.black,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedItems.length} item • Total: ${FormatHelper.formatCurrency(grandTotal)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    controller: _spgCodeController,
                    label: 'Kode SPG',
                    icon: Icons.badge,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPhoneNumberSection(isDark),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                isDark ? AppColors.surfaceLight : Colors.black,
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.surfaceLight
                                            : Colors.black,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qty: ${item.quantity} × ${FormatHelper.formatCurrency(item.netPrice)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.surfaceLight
                                  : Colors.black,
                            ),
                      ),
                      Text(
                        FormatHelper.formatCurrency(grandTotal),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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

  List<Map<String, dynamic>> _convertPaymentMethodsToApiFormat() {
    return _paymentMethods.map((payment) {
      // Get payment category based on methodType
      final paymentCategory = _getPaymentCategoryFromMethod(payment.methodType);
      final categoryDisplayName = _getCategoryDisplayName(paymentCategory);

      return {
        'payment_method': paymentCategory,
        'payment_bank': payment.methodName,
        'payment_number': payment.reference ?? '',
        'payment_amount': payment.amount,
        'note':
            'Payment via $categoryDisplayName ${payment.methodName}${payment.reference != null ? ' - Ref: ${payment.reference}' : ''}',
        'receipt_image_path': payment.receiptImagePath,
      };
    }).toList();
  }

  // Get payment category from method type
  String _getPaymentCategoryFromMethod(String methodType) {
    // Transfer Bank
    if (methodType == 'bri' ||
        methodType == 'bca' ||
        methodType == 'mandiri' ||
        methodType == 'bni' ||
        methodType == 'btn' ||
        methodType == 'other_bank') {
      return 'transfer';
    }
    // Credit Card
    else if (methodType.endsWith('_credit') || methodType == 'other_credit') {
      return 'credit';
    }
    // PayLater
    else if (methodType == 'akulaku' ||
        methodType == 'kredivo' ||
        methodType == 'indodana' ||
        methodType == 'other_paylater') {
      return 'paylater';
    }
    // Digital Payment (QRIS, E-wallet, etc.)
    else if (methodType == 'qris' ||
        methodType == 'gopay' ||
        methodType == 'ovo' ||
        methodType == 'dana' ||
        methodType == 'shopeepay' ||
        methodType == 'linkaja' ||
        methodType == 'other_digital') {
      return 'other';
    }
    // Default fallback
    else {
      return 'other';
    }
  }

  // Get display name for payment category
  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'transfer':
        return 'Transfer Bank';
      case 'credit':
        return 'Kartu Kredit';
      case 'paylater':
        return 'PayLater';
      case 'other':
        return 'Digital Payment';
      default:
        return 'Pembayaran';
    }
  }

  String? _validatePhoneNumber(String? value, bool isRequired) {
    if (isRequired && (value == null || value.trim().isEmpty)) {
      return 'Nomor telepon wajib diisi';
    }

    if (value != null && value.trim().isNotEmpty) {
      // Remove all non-digit characters for validation
      final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');

      // Check minimum length (8 digits for local numbers)
      if (cleanNumber.length < 8) {
        return 'Nomor telepon minimal 8 digit';
      }

      // Check maximum length (15 digits including country code)
      if (cleanNumber.length > 15) {
        return 'Nomor telepon maksimal 15 digit';
      }

      // Check if starts with valid Indonesian prefixes
      if (cleanNumber.startsWith('08') ||
          cleanNumber.startsWith('628') ||
          cleanNumber.startsWith('8')) {
        return null; // Valid Indonesian number
      }

      // Check for international format
      if (cleanNumber.startsWith('0') || cleanNumber.length >= 10) {
        return null; // Assume valid for other formats
      }

      return 'Format nomor telepon tidak valid';
    }

    return null;
  }

  Widget _buildPhoneNumberSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary phone number with add button
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _customerPhoneController,
                label: 'Nomor Telepon',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) => _validatePhoneNumber(val, true),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            // Add second phone button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _showSecondPhone
                    ? Colors.red.withOpacity(0.1)
                    : (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showSecondPhone
                      ? Colors.red
                      : (isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _showSecondPhone ? Icons.remove : Icons.add,
                  color: _showSecondPhone
                      ? Colors.red
                      : (isDark
                          ? AppColors.primaryDark
                          : AppColors.primaryLight),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showSecondPhone = !_showSecondPhone;
                    if (!_showSecondPhone) {
                      _customerPhone2Controller.clear();
                    }
                  });
                },
                tooltip: _showSecondPhone
                    ? 'Hapus nomor kedua'
                    : 'Tambah nomor kedua',
              ),
            ),
          ],
        ),
        // Second phone number field (conditional)
        if (_showSecondPhone) ...[
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _buildModernTextField(
              controller: _customerPhone2Controller,
              label: 'Nomor Telepon Kedua (Opsional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (val) => _validatePhoneNumber(val, false),
              isDark: isDark,
            ),
          ),
        ],
      ],
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
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      onFieldSubmitted: (_) {
        // Move focus to next field or dismiss keyboard
        FocusScope.of(context).nextFocus();
      },
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppColors.surfaceLight : Colors.black,
            fontSize: ResponsiveHelper.getResponsiveFontSize(
              context,
              mobile: 14,
              tablet: 15,
              desktop: 16,
            ),
          ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
          size: ResponsiveHelper.getResponsiveIconSize(
            context,
            mobile: 18,
            tablet: 20,
            desktop: 22,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(
              context,
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
          ),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
            ),
        errorStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red,
              fontSize: ResponsiveHelper.getResponsiveFontSize(
                context,
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
            ),
        filled: true,
        fillColor: enabled
            ? (isDark ? AppColors.cardDark : AppColors.surfaceLight)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        contentPadding: ResponsiveHelper.getResponsivePaddingWithZoom(
          context,
          mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.surfaceLight : Colors.black,
                      ),
                ),
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                ),
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
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                    ),
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
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 16,
                    tablet: 20,
                    desktop: 24,
                  ),
                ),

                // Payment Methods
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Metode Pembayaran',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.surfaceLight
                                        : Colors.black,
                                  ),
                        ),
                        Text(
                          '* Struk pembayaran wajib diisi',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark
                            ? AppColors.primaryDark
                            : AppColors.primaryLight)
                        : (isDark ? AppColors.surfaceLight : Colors.black),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: isSelected
                        ? (isDark
                                ? AppColors.primaryDark
                                : AppColors.primaryLight)
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
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(
          context,
          mobile: 6,
          tablet: 8,
          desktop: 10,
        ),
      ),
      padding: ResponsiveHelper.getCardPadding(context),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(
            context,
            mobile: 6,
            tablet: 8,
            desktop: 10,
          ),
        ),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          // Payment Icon
          Container(
            padding: EdgeInsets.all(
              ResponsiveHelper.getResponsiveSpacing(
                context,
                mobile: 6,
                tablet: 8,
                desktop: 10,
              ),
            ),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.primaryDark : AppColors.primaryLight)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(
                  context,
                  mobile: 4,
                  tablet: 6,
                  desktop: 8,
                ),
              ),
            ),
            child: Icon(
              _getPaymentIcon(payment.methodType),
              size: ResponsiveHelper.getResponsiveIconSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 12,
              desktop: 16,
            ),
          ),
          // Payment Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.methodName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.surfaceLight : Colors.black,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (payment.reference != null &&
                    payment.reference!.isNotEmpty) ...[
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveSpacing(
                      context,
                      mobile: 2,
                      tablet: 3,
                      desktop: 4,
                    ),
                  ),
                  Text(
                    'Ref: ${payment.reference}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                            context,
                            mobile: 10,
                            tablet: 11,
                            desktop: 12,
                          ),
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(
                  height: ResponsiveHelper.getResponsiveSpacing(
                    context,
                    mobile: 2,
                    tablet: 3,
                    desktop: 4,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.receipt,
                      size: ResponsiveHelper.getResponsiveIconSize(
                        context,
                        mobile: 10,
                        tablet: 12,
                        desktop: 14,
                      ),
                      color: AppColors.success,
                    ),
                    SizedBox(
                      width: ResponsiveHelper.getResponsiveSpacing(
                        context,
                        mobile: 3,
                        tablet: 4,
                        desktop: 5,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Struk tersedia',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: ResponsiveHelper.getResponsiveFontSize(
                                context,
                                mobile: 9,
                                tablet: 10,
                                desktop: 11,
                              ),
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Flexible(
            child: Text(
              FormatHelper.formatCurrency(payment.amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 3,
              tablet: 4,
              desktop: 6,
            ),
          ),
          // Action Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () =>
                    _showReceiptImage(payment.receiptImagePath, isDark),
                icon: Icon(
                  Icons.visibility,
                  size: ResponsiveHelper.getResponsiveIconSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: AppColors.success,
                ),
                constraints: BoxConstraints(
                  minWidth: ResponsiveHelper.getMinTouchTargetSize(context),
                  minHeight: ResponsiveHelper.getMinTouchTargetSize(context),
                ),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => _removePaymentMethod(index),
                icon: Icon(
                  Icons.delete_outline,
                  size: ResponsiveHelper.getResponsiveIconSize(
                    context,
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  color: Colors.red[400],
                ),
                constraints: BoxConstraints(
                  minWidth: ResponsiveHelper.getMinTouchTargetSize(context),
                  minHeight: ResponsiveHelper.getMinTouchTargetSize(context),
                ),
                padding: EdgeInsets.zero,
              ),
            ],
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              Text(
                FormatHelper.formatCurrency(grandTotal),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
              ),
              Text(
                FormatHelper.formatCurrency(_totalPaid),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  IconData _getPaymentIcon(String methodType) {
    // Transfer Bank
    if (methodType == 'bri' ||
        methodType == 'bca' ||
        methodType == 'mandiri' ||
        methodType == 'bni' ||
        methodType == 'btn' ||
        methodType == 'other_bank') {
      return Icons.account_balance;
    }
    // Credit Card
    else if (methodType.endsWith('_credit') || methodType == 'other_credit') {
      return Icons.credit_card;
    }
    // PayLater
    else if (methodType == 'akulaku' ||
        methodType == 'kredivo' ||
        methodType == 'indodana' ||
        methodType == 'other_paylater') {
      return Icons.schedule;
    }
    // Digital Payment (QRIS, E-wallet, etc.)
    else if (methodType == 'qris' ||
        methodType == 'gopay' ||
        methodType == 'ovo' ||
        methodType == 'dana' ||
        methodType == 'shopeepay' ||
        methodType == 'linkaja' ||
        methodType == 'other_digital') {
      return Icons.qr_code;
    }
    // Default
    else {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          FormatHelper.formatCurrency(grandTotal),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  String _selectedPaymentCategory = 'transfer'; // transfer, credit, paylater
  String _selectedMethodType = 'bri';
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
    final remaining = widget.grandTotal - totalPaid;
    return double.parse(remaining.toStringAsFixed(2));
  }

  // Get hint text based on remaining amount
  String _getAmountHintText() {
    final remaining = _getRemainingAmount();
    return FormatHelper.formatCurrency(remaining);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final availableHeight = ResponsiveHelper.getSafeModalHeight(context);
    final safePadding = ResponsiveHelper.getSafeAreaPadding(context);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // Prevent tap from bubbling up
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            margin: EdgeInsets.only(
              top: safePadding.top + 60,
              bottom: 0,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: true, // Handle keyboard properly
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: ResponsiveHelper.getResponsivePaddingWithZoom(
                      context,
                      mobile: const EdgeInsets.all(20),
                      tablet: const EdgeInsets.all(24),
                      desktop: const EdgeInsets.all(28),
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.payment_outlined,
                            color: colorScheme.onPrimary,
                            size: ResponsiveHelper.getResponsiveIconSize(
                              context,
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tambah Pembayaran',
                                style: GoogleFonts.inter(
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    mobile: 18,
                                    tablet: 20,
                                    desktop: 22,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pilih metode dan jumlah pembayaran',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close Button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: ResponsiveHelper.getResponsivePaddingWithZoom(
                        context,
                        mobile: const EdgeInsets.all(20),
                        tablet: const EdgeInsets.all(24),
                        desktop: const EdgeInsets.all(28),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Payment Category Selection
                            Text(
                              'Metode Pembayaran',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedPaymentCategory,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'transfer',
                                    child: Text('Transfer Bank')),
                                DropdownMenuItem(
                                    value: 'credit',
                                    child: Text('Kartu Kredit')),
                                DropdownMenuItem(
                                    value: 'paylater', child: Text('PayLater')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Lainnya')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedPaymentCategory = value;
                                    // Reset method type when category changes
                                    final methods =
                                        _getPaymentMethodsByCategory(value);
                                    _selectedMethodType = methods.isNotEmpty
                                        ? methods.first['value']!
                                        : '';
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Specific Payment Method Selection
                            Text(
                              'Channel Pembayaran',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedMethodType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              items: _getPaymentMethodsByCategory(
                                      _selectedPaymentCategory)
                                  .map((method) => DropdownMenuItem(
                                        value: method['value'],
                                        child: Text(method['label']!),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedMethodType = value);
                                }
                              },
                            ),

                            const SizedBox(height: 12),

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
                                fillColor: colorScheme.surface,
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
                                const double tolerance = 0.1;
                                final roundedAmount =
                                    double.parse(amount.toStringAsFixed(2));
                                final roundedRemaining =
                                    double.parse(remaining.toStringAsFixed(2));

                                if (roundedAmount >
                                    roundedRemaining + tolerance) {
                                  return 'Jumlah tidak boleh melebihi sisa pembayaran (${FormatHelper.formatCurrency(remaining)})';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Receipt Image Upload
                            Text(
                              'Foto Struk Pembayaran *',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.outline,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: _receiptImagePath != null
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                color: Colors.black
                                                    .withOpacity(0.6),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: IconButton(
                                                onPressed: _removeReceiptImage,
                                                icon: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                padding:
                                                    const EdgeInsets.all(4),
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
                                fillColor: colorScheme.surface,
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
                                      foregroundColor: colorScheme.primary,
                                      side: BorderSide(
                                          color: colorScheme.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    child: Text(
                                      'Batal',
                                      style: GoogleFonts.inter(
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
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    child: Text(
                                      'Tambah',
                                      style: GoogleFonts.inter(
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
                  ),
                ],
              ),
            ),
          ),
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
              style: GoogleFonts.inter(
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
        methodType: _selectedMethodType,
        methodName: _getPaymentName(_selectedMethodType),
        amount: amount,
        reference: reference.isEmpty ? null : reference,
        receiptImagePath: _receiptImagePath!,
      );

      widget.onPaymentAdded(payment);
      Navigator.pop(context);
    }
  }

  Widget _buildImagePlaceholder() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap untuk ambil foto atau pilih dari galeri',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Struk pembayaran wajib diisi',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
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
                color: colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Gunakan kamera untuk mengambil foto struk',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                'Pilih dari Galeri',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Pilih foto struk dari galeri',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                'Pilih file gambar dari penyimpanan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
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

  String _getPaymentName(String methodType) {
    switch (methodType) {
      // Transfer Bank
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
      case 'other_bank':
        return 'Bank Lainnya';

      // Credit Card
      case 'bri_credit':
        return 'Kartu Kredit BRI';
      case 'bca_credit':
        return 'Kartu Kredit BCA';
      case 'mandiri_credit':
        return 'Kartu Kredit Mandiri';
      case 'bni_credit':
        return 'Kartu Kredit BNI';
      case 'other_credit':
        return 'Kartu Kredit Lainnya';

      // PayLater
      case 'akulaku':
        return 'Akulaku';
      case 'kredivo':
        return 'Kredivo';
      case 'indodana':
        return 'Indodana';
      case 'other_paylater':
        return 'PayLater Lainnya';

      // Digital Payment
      case 'qris':
        return 'QRIS';
      case 'gopay':
        return 'GoPay';
      case 'ovo':
        return 'OVO';
      case 'dana':
        return 'DANA';
      case 'shopeepay':
        return 'ShopeePay';
      case 'linkaja':
        return 'LinkAja';
      case 'other_digital':
        return 'Digital Lainnya';

      default:
        return 'Lainnya';
    }
  }

  // Get payment methods based on category
  List<Map<String, String>> _getPaymentMethodsByCategory(String category) {
    switch (category) {
      case 'transfer':
        return [
          {'value': 'bri', 'label': 'BRI'},
          {'value': 'bca', 'label': 'BCA'},
          {'value': 'mandiri', 'label': 'Bank Mandiri'},
          {'value': 'bni', 'label': 'BNI'},
          {'value': 'btn', 'label': 'BTN'},
          {'value': 'other_bank', 'label': 'Bank Lainnya'},
        ];
      case 'credit':
        return [
          {'value': 'bri_credit', 'label': 'Kartu Kredit BRI'},
          {'value': 'bca_credit', 'label': 'Kartu Kredit BCA'},
          {'value': 'mandiri_credit', 'label': 'Kartu Kredit Mandiri'},
          {'value': 'bni_credit', 'label': 'Kartu Kredit BNI'},
          {'value': 'other_credit', 'label': 'Kartu Kredit Lainnya'},
        ];
      case 'paylater':
        return [
          {'value': 'akulaku', 'label': 'Akulaku'},
          {'value': 'kredivo', 'label': 'Kredivo'},
          {'value': 'indodana', 'label': 'Indodana'},
          {'value': 'other_paylater', 'label': 'PayLater Lainnya'},
        ];
      case 'other':
        return [
          {'value': 'qris', 'label': 'QRIS'},
          {'value': 'gopay', 'label': 'GoPay'},
          {'value': 'ovo', 'label': 'OVO'},
          {'value': 'dana', 'label': 'DANA'},
          {'value': 'shopeepay', 'label': 'ShopeePay'},
          {'value': 'linkaja', 'label': 'LinkAja'},
          {'value': 'other_digital', 'label': 'Digital Lainnya'},
        ];
      default:
        return [];
    }
  }
}
