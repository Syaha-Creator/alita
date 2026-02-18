import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

import '../../../../config/app_constant.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/utils/controller_disposal_mixin.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../services/auth_service.dart';
import '../../../approval/data/models/approval_sales_model.dart';
import '../../domain/usecases/checkout_usecase.dart';
import '../../domain/usecases/save_draft_usecase.dart';
import '../widgets/checkout/approver_selection_section.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/entities/cart_entity.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import 'draft_checkout_page.dart';

// Checkout widgets modular
import '../widgets/checkout/checkout_widgets.dart';

class CheckoutPages extends StatefulWidget {
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? userAddress;
  final bool isTakeAway;
  final bool isExistingCustomer;
  final Map<String, dynamic>? draftData;

  // Indirect checkout mode
  final bool isIndirectCheckout;
  final IndirectStoreInfo? indirectStoreInfo;

  const CheckoutPages({
    super.key,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.userAddress,
    this.isTakeAway = false,
    this.isExistingCustomer = false,
    this.draftData,
    this.isIndirectCheckout = false,
    this.indirectStoreInfo,
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
        isExistingCustomer = draftData?['isExistingCustomer'] as bool? ?? false,
        isIndirectCheckout = draftData?['isIndirectCheckout'] as bool? ?? false,
        indirectStoreInfo = null;

  @override
  State<CheckoutPages> createState() => _CheckoutPagesState();
}

class _CheckoutPagesState extends State<CheckoutPages>
    with ControllerDisposalMixin {
  final _formKey = GlobalKey<FormState>();

  // Listener function reference for proper cleanup
  late final VoidCallback _postageListener;

  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _customerPhone2Controller;
  late final TextEditingController _customerReceiverController;
  late final TextEditingController _shippingAddressController;
  late final TextEditingController _shippingPhoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _deliveryDateController;
  late final TextEditingController _emailController;
  late final TextEditingController _customerAddressController;
  late final TextEditingController _spgCodeController;
  late final TextEditingController _postageController;
  bool _shippingSameAsCustomer = false;
  bool _showSecondPhone = false;

  // Region selection for shipping address
  String? _selectedProvinceName;
  String? _selectedCityName;
  String? _selectedDistrictName;

  // Selected approvers from approval_sales
  ApprovalSalesUserModel? _selectedSpv;
  ApprovalSalesUserModel? _selectedRsm;

  // Payment related variables
  String _paymentType = 'full'; // 'full' or 'partial'
  final List<PaymentMethod> _paymentMethods = [];
  double _totalPaid = 0.0;

  /// Helper method to recalculate total paid from payment methods
  /// This ensures _totalPaid is always in sync with _paymentMethods
  void _recalculateTotalPaid() {
    _totalPaid = _paymentMethods.fold(0.0, (sum, p) => sum + p.amount);
  }

  // Cache for selected items to use in bottomNavigationBar
  // This allows bottomNavigationBar to rebuild when setState is called
  List<CartEntity> _cachedSelectedItems = [];

  @override
  void initState() {
    super.initState();
    _customerNameController = registerController();
    _customerPhoneController = registerController();
    _customerPhone2Controller = registerController();
    _emailController = registerController();
    _customerReceiverController = registerController();
    _shippingAddressController = registerController();
    _shippingPhoneController = registerController();
    _notesController = registerController();
    _deliveryDateController = registerController();
    _customerAddressController = registerController();
    _spgCodeController = registerController();
    _postageController = registerController();

    // Add listener to postage controller to auto-update UI
    _postageListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    _postageController.addListener(_postageListener);

    // Load from draft if available, otherwise use widget parameters
    if (widget.draftData != null) {
      _loadFromDraft(widget.draftData!);
    } else if (widget.isIndirectCheckout && widget.indirectStoreInfo != null) {
      // Indirect checkout mode - auto-fill from store info
      final storeInfo = widget.indirectStoreInfo!;
      _customerNameController.text = storeInfo.alphaName;
      _customerPhoneController.text = storeInfo.longAddressNumber;
      _customerAddressController.text = storeInfo.address;
      // For indirect, shipping same as customer is default
      _shippingSameAsCustomer = true;
      _shippingAddressController.text = storeInfo.address;
      _customerReceiverController.text = storeInfo.alphaName;
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
    _postageController.text = draft['postage'] as String? ?? '';
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
        paymentDate: payment['paymentDate'] as String?,
        note: payment['note'] as String?,
      ));
    }
    // Recalculate total paid after loading payment methods from draft
    _recalculateTotalPaid();

    // Cart items will be handled separately
    // We'll restore bonus take away states after cart is loaded
    _restoreCartItemsFromDraft(draft);
  }

  // Restore cart items from draft data
  Future<void> _restoreCartItemsFromDraft(Map<String, dynamic> draft) async {
    try {
      final itemsData = draft['selectedItems'] as List<dynamic>? ?? [];

      // Clear current cart first
      context.read<CartBloc>().add(ClearCart());

      // Wait a bit for cart to clear
      await Future.delayed(const Duration(milliseconds: 100));

      // Add each item back to cart with restored bonus take away data
      for (int i = 0; i < itemsData.length; i++) {
        final itemData = itemsData[i];

        final item = itemData as Map<String, dynamic>;
        final productData = item['product'] as Map<String, dynamic>;

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
            pricelist: (bonusMap['pricelist'] as num?)?.toDouble() ?? 0.0,
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
        if (mounted) {
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
        }

        // After adding to cart, update bonus take away if needed
        if (bonusTakeAway != null && bonusTakeAway.isNotEmpty) {
          // Wait a bit for cart to be updated
          await Future.delayed(const Duration(milliseconds: 50));

          if (mounted) {
            context.read<CartBloc>().add(UpdateBonusTakeAway(
                  productId: product.id,
                  netPrice: item['netPrice'] as double,
                  bonusTakeAway: bonusTakeAway,
                ));
          }
        }

        // Add delay between items to ensure proper processing
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Wait a bit more for all items to be processed
      await Future.delayed(const Duration(milliseconds: 200));

      // Trigger rebuild to update bottomNavigationBar
      if (mounted) {
        setState(() {
          // This will trigger a rebuild of the entire widget
          // including bottomNavigationBar which depends on _cachedSelectedItems
        });
      }
    } catch (e) {
      //
      throw Exception('Failed to restore cart items from draft: $e');
    }
  }

  /// Save draft checkout using SaveDraftUseCase
  Future<void> _saveDraft(List<CartEntity> selectedItems) async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
        "Harap isi semua kolom yang wajib diisi dan perbaiki error",
        ToastType.error,
      );
      return;
    }

    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        CustomToast.showToast(
          'User ID tidak tersedia. Silakan login ulang.',
          ToastType.error,
        );
        return;
      }

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
        'postage': _postageController.text,
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
                  'paymentDate': payment.paymentDate,
                  'note': payment.note,
                })
            .toList(),
        'paymentType': _paymentType,
        'totalPaid': _totalPaid,

        // Totals
        'grandTotal': _calculateGrandTotal(selectedItems),

        // Settings
        'isTakeAway': widget.isTakeAway,
        'isExistingCustomer': widget.isExistingCustomer,

        // Metadata
        'savedAt':
            widget.draftData?['savedAt'] ?? DateTime.now().toIso8601String(),
        'version': '2.0', // Version for backward compatibility
      };

      // Use SaveDraftUseCase
      final saveDraftUseCase = locator<SaveDraftUseCase>();
      final result = await saveDraftUseCase.call(
        SaveDraftParams(
          draftData: draft,
          userId: userId,
        ),
      );

      if (result.isSuccess) {
        CustomToast.showToast('Draft berhasil disimpan', ToastType.success);

        // Clear all items from cart after saving to draft
        if (mounted) {
          context.read<CartBloc>().add(ClearCart());

          // Navigate to draft checkout page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DraftCheckoutPage(),
            ),
          );
        }
      } else {
        CustomToast.showToast(
          result.errorMessage ?? 'Gagal menyimpan draft',
          ToastType.error,
        );
      }
    } catch (e) {
      CustomToast.showToast('Gagal menyimpan draft: $e', ToastType.error);
    }
  }

  /// Show validation dialog for indirect checkout
  Future<void> _showIndirectValidationDialog(
      List<CartEntity> selectedItems, bool isDark) async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
        "Harap isi semua kolom yang wajib diisi",
        ToastType.error,
      );
      return;
    }

    // Validate required fields for indirect
    if (_customerNameController.text.isEmpty ||
        _customerPhoneController.text.isEmpty ||
        _customerAddressController.text.isEmpty ||
        _deliveryDateController.text.isEmpty) {
      CustomToast.showToast(
        "Harap lengkapi semua data wajib",
        ToastType.error,
      );
      return;
    }

    // Calculate total
    final grandTotal = _calculateGrandTotal(selectedItems);

    // Show validation popup
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Konfirmasi Data Pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pastikan data berikut sudah benar:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Info Toko Section
                _buildValidationSection(
                  context,
                  isDark,
                  'Informasi Toko',
                  Icons.store,
                  [
                    _buildValidationItem(
                        'Nama Toko', _customerNameController.text),
                    _buildValidationItem(
                        'Telepon', _customerPhoneController.text),
                    _buildValidationItem(
                        'Alamat', _customerAddressController.text),
                    if (_spgCodeController.text.isNotEmpty)
                      _buildValidationItem('Kode SC', _spgCodeController.text),
                  ],
                ),
                const SizedBox(height: 12),
                // Info Pengiriman Section
                _buildValidationSection(
                  context,
                  isDark,
                  'Informasi Pengiriman',
                  Icons.local_shipping,
                  [
                    _buildValidationItem(
                        'Penerima',
                        _shippingSameAsCustomer
                            ? _customerNameController.text
                            : _customerReceiverController.text),
                    _buildValidationItem(
                        'Alamat',
                        _shippingSameAsCustomer
                            ? _customerAddressController.text
                            : _shippingAddressController.text),
                    if (!_shippingSameAsCustomer &&
                        _shippingPhoneController.text.isNotEmpty)
                      _buildValidationItem(
                          'Telepon', _shippingPhoneController.text),
                    _buildValidationItem(
                        'Tanggal Kirim', _deliveryDateController.text),
                    if (_emailController.text.isNotEmpty)
                      _buildValidationItem('Email', _emailController.text),
                    if (_notesController.text.isNotEmpty)
                      _buildValidationItem('Catatan', _notesController.text),
                  ],
                ),
                const SizedBox(height: 12),
                // Order Summary Section
                _buildValidationSection(
                  context,
                  isDark,
                  'Ringkasan Pesanan',
                  Icons.shopping_cart,
                  [
                    _buildValidationItem(
                        'Jumlah Item', '${selectedItems.length} produk'),
                    _buildValidationItem(
                        'Total', FormatHelper.formatCurrency(grandTotal)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Konfirmasi & Buat Surat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );

    // If confirmed, proceed to submit
    if (confirmed == true && mounted) {
      await _submitOrder(selectedItems, isDark);
    }
  }

  Widget _buildValidationSection(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    List<Widget> items,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.2)
              : AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.primaryDark : AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items,
        ],
      ),
    );
  }

  Widget _buildValidationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Submit order using CheckoutUseCase with proper error handling
  Future<void> _submitOrder(List<CartEntity> selectedItems, bool isDark) async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.showToast(
        "Harap isi semua kolom yang wajib diisi dan perbaiki error",
        ToastType.error,
      );
      return;
    }

    try {
      // Show loading dialog
      CustomLoading.showLoadingDialog(
        context,
        message: 'Membuat surat pesanan...',
      );

      // Get current user ID
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) {
        if (mounted) {
          CustomLoading.hideLoadingDialog(context);
          CustomToast.showToast(
            'User ID tidak tersedia. Silakan login ulang.',
            ToastType.error,
          );
        }
        return;
      }

      // Parse postage from currency format
      double? postage;
      if (_postageController.text.isNotEmpty) {
        postage = FormatHelper.parseCurrencyToDouble(_postageController.text);
      }

      // Use CheckoutUseCase
      final checkoutUseCase = locator<CheckoutUseCase>();
      // Use primaryPhone as customerPhone for validation
      // Phone will be uploaded separately via uploadPhoneNumbers, but we need it for order letter validation
      final primaryPhone = _customerPhoneController.text.trim();
      if (primaryPhone.isEmpty) {
        if (mounted) {
          CustomLoading.hideLoadingDialog(context);
          CustomToast.showToast(
            'Nomor telepon wajib diisi',
            ToastType.error,
          );
        }
        return;
      }

      // Validate approver selection
      if (_selectedSpv == null) {
        if (mounted) {
          CustomLoading.hideLoadingDialog(context);
          CustomToast.showToast(
            'Silakan pilih Supervisor',
            ToastType.error,
          );
        }
        return;
      }

      // Check if RSM is required (any item has disc3 > 0)
      // discountPercentages[2] is disc3 (RSM)
      final requiresRsmApproval = selectedItems.any(
        (item) =>
            item.discountPercentages.length > 2 &&
            item.discountPercentages[2] > 0,
      );
      if (requiresRsmApproval && _selectedRsm == null) {
        if (mounted) {
          CustomLoading.hideLoadingDialog(context);
          CustomToast.showToast(
            'Silakan pilih RSM',
            ToastType.error,
          );
        }
        return;
      }

      final shipToName = widget.isTakeAway
          ? _customerNameController.text
          : _customerReceiverController.text;

      // Build address with region
      String addressShipTo = widget.isTakeAway
          ? _customerAddressController.text
          : _shippingAddressController.text;

      // Append region to address if available
      if (!widget.isTakeAway) {
        final regionParts = <String>[];
        if (_selectedDistrictName != null &&
            _selectedDistrictName!.isNotEmpty) {
          regionParts.add('Kec. $_selectedDistrictName');
        }
        if (_selectedCityName != null && _selectedCityName!.isNotEmpty) {
          regionParts.add(_selectedCityName!);
        }
        if (_selectedProvinceName != null &&
            _selectedProvinceName!.isNotEmpty) {
          regionParts.add(_selectedProvinceName!);
        }
        if (regionParts.isNotEmpty) {
          addressShipTo = '$addressShipTo\n${regionParts.join(', ')}';
        }
      }

      final requestDate = widget.isTakeAway
          ? DateTime.now().toIso8601String().split('T')[0]
          : _deliveryDateController.text;

      final result = await checkoutUseCase.call(
        CheckoutParams(
          cartItems: selectedItems,
          customerName: _customerNameController.text,
          customerPhone: primaryPhone, // Use primary phone for validation
          email: _emailController.text,
          customerAddress: _customerAddressController.text,
          shipToName: shipToName,
          addressShipTo: addressShipTo,
          requestDate: requestDate,
          note: _notesController.text,
          spgCode: _spgCodeController.text,
          isTakeAway: widget.isTakeAway,
          postage: postage,
          primaryPhone: primaryPhone,
          secondaryPhone: _showSecondPhone &&
                  _customerPhone2Controller.text.trim().isNotEmpty
              ? _customerPhone2Controller.text.trim()
              : null,
          paymentMethods: _convertPaymentMethodsToApiFormat(),
          creatorId: currentUserId,
          isIndirectCheckout: widget.isIndirectCheckout,
          selectedSpvId: _selectedSpv?.id,
          selectedSpvName: _selectedSpv?.displayName,
          selectedRsmId: _selectedRsm?.id,
          selectedRsmName: _selectedRsm?.displayName,
        ),
      );

      if (mounted) {
        CustomLoading.hideLoadingDialog(context);

        if (result.isSuccess) {
          // Show success message
          CustomToast.showToast(
            'Surat pesanan berhasil dibuat!\nNo. SP: ${result.noSp}',
            ToastType.success,
          );

          // Show warning if payment upload failed
          if (result.warning != null) {
            CustomToast.showToast(result.warning!, ToastType.warning);
          }

          // Clear entire cart after successful checkout
          context.read<CartBloc>().add(ClearCart());

          // Clear all drafts after successful checkout
          context.read<CartBloc>().add(ClearDraftsAfterCheckout());

          // Navigate to approval monitoring page to see the new order
          context.go(RoutePaths.approvalMonitoring);
        } else {
          // Show error message
          CustomToast.showToast(
            result.errorMessage ?? 'Gagal membuat surat pesanan',
            ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomLoading.hideLoadingDialog(context);
        CustomToast.showToast(
          'Gagal membuat surat pesanan: $e',
          ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _postageController.removeListener(_postageListener);
    super.dispose();
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
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        AppColors.surfaceDark,
                        AppColors.surfaceDark.withValues(alpha: 0.95),
                      ]
                    : [
                        AppColors.primaryLight,
                        AppColors.primaryLight.withValues(alpha: 0.85),
                      ],
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.shopping_cart_checkout_rounded,
                  size: 18,
                  color: isDark ? AppColors.primaryDark : Colors.white,
                ),
              ),
              const SizedBox(width: AppPadding.p10),
              Text(
                'Checkout',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : Colors.white,
                    ),
              ),
            ],
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
              tooltip: 'Lihat Draft',
              icon: Icon(
                Icons.folder_open_rounded,
                color: isDark ? AppColors.textPrimaryDark : Colors.white,
              ),
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoaded) {
              final selectedItems = state.selectedItems;
              final grandTotal = _calculateGrandTotal(selectedItems);

              // Update cached values for use in bottomNavigationBar
              // This ensures bottomNavigationBar has access to latest cart data
              _cachedSelectedItems = selectedItems;

              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // Header Summary Card
                      CheckoutHeaderSummary(
                        selectedItems: selectedItems,
                        grandTotal: grandTotal,
                        isDark: isDark,
                        isExistingCustomer: widget.isExistingCustomer,
                      ),

                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 16,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),

                      // Customer Info Section
                      CustomerInfoSection(
                        formKey: _formKey,
                        nameController: _customerNameController,
                        spgCodeController: _spgCodeController,
                        phoneController: _customerPhoneController,
                        phone2Controller: _customerPhone2Controller,
                        emailController: _emailController,
                        addressController: _customerAddressController,
                        showSecondPhone: _showSecondPhone,
                        isDark: isDark,
                        onToggleSecondPhone: () {
                          setState(() {
                            _showSecondPhone = !_showSecondPhone;
                            if (!_showSecondPhone) {
                              _customerPhone2Controller.clear();
                            }
                          });
                        },
                        phoneValidator: _validatePhoneNumber,
                        isIndirectCheckout: widget.isIndirectCheckout,
                      ),

                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 16,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),

                      // Shipping Info Section (only show if not take away)
                      if (!widget.isTakeAway) ...[
                        ShippingInfoSection(
                          receiverController: _customerReceiverController,
                          shippingAddressController: _shippingAddressController,
                          customerAddressController: _customerAddressController,
                          deliveryDateController: _deliveryDateController,
                          postageController: _postageController,
                          notesController: _notesController,
                          emailController: _emailController,
                          shippingPhoneController: _shippingPhoneController,
                          isTakeAway: widget.isTakeAway,
                          shippingSameAsCustomer: _shippingSameAsCustomer,
                          isDark: isDark,
                          formKey: _formKey,
                          isIndirectCheckout: widget.isIndirectCheckout,
                          onSameAddressChanged: (val) {
                            setState(() {
                              _shippingSameAsCustomer = val ?? false;
                              if (_shippingSameAsCustomer) {
                                // Fill with customer/store info
                                _shippingAddressController.text =
                                    _customerAddressController.text;
                                _customerReceiverController.text =
                                    _customerNameController.text;
                              } else if (widget.isIndirectCheckout) {
                                // For indirect: clear fields when unchecking
                                _customerReceiverController.clear();
                                _shippingAddressController.clear();
                                _shippingPhoneController.clear();
                                _emailController.clear();
                              }
                            });
                          },
                          onSelectDeliveryDate: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              _deliveryDateController.text =
                                  FormatHelper.formatSimpleDate(picked);
                              _formKey.currentState?.validate();
                            }
                          },
                          onRegionChanged: (province, city, district) {
                            setState(() {
                              _selectedProvinceName = province?.name;
                              _selectedCityName = city?.name;
                              _selectedDistrictName = district?.name;
                            });
                          },
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                      ],

                      // Order Summary Section
                      OrderSummarySection(
                        selectedItems: selectedItems,
                        grandTotal: grandTotal,
                        isDark: isDark,
                      ),

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
                          selectedItems.any(
                              (item) => item.product.bonus.isNotEmpty)) ...[
                        BonusTakeAwaySection(
                          selectedItems: selectedItems,
                          isDark: isDark,
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                      ],

                      // Approver Selection Section
                      Builder(
                        builder: (context) {
                          // Check if any item requires RSM approval (disc3 > 0)
                          // discountPercentages[2] is disc3 (RSM)
                          final requiresRsmApproval = selectedItems.any(
                            (item) =>
                                item.discountPercentages.length > 2 &&
                                item.discountPercentages[2] > 0,
                          );
                          return ApproverSelectionSection(
                            isDark: isDark,
                            requiresRsmApproval: requiresRsmApproval,
                            initialSpv: _selectedSpv,
                            initialRsm: _selectedRsm,
                            onSpvSelected: (user) {
                              setState(() {
                                _selectedSpv = user;
                              });
                            },
                            onRsmSelected: (user) {
                              setState(() {
                                _selectedRsm = user;
                              });
                            },
                          );
                        },
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveSpacing(
                          context,
                          mobile: 16,
                          tablet: 20,
                          desktop: 24,
                        ),
                      ),

                      // Payment Section (only show for direct checkout)
                      if (!widget.isIndirectCheckout) ...[
                        PaymentSection(
                          selectedItems: selectedItems,
                          grandTotal: grandTotal,
                          isDark: isDark,
                          paymentType: _paymentType,
                          paymentMethods: _paymentMethods,
                          totalPaid: _totalPaid,
                          onPaymentTypeChanged: (type) {
                            setState(() {
                              // Only clear payment methods if switching between different types
                              // This prevents data loss if user accidentally clicks the same type
                              if (_paymentType != type) {
                                _paymentType = type;
                                _paymentMethods.clear();
                                _totalPaid = 0.0;
                              }
                            });
                          },
                          onAddPaymentMethod: () =>
                              _showPaymentMethodDialog(grandTotal, isDark),
                          onViewReceipt: (path) =>
                              _showReceiptImage(path, isDark),
                          onRemovePayment: _removePaymentMethod,
                        ),
                        SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(
                            context,
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),
                        ),
                      ],

                      // Space for bottom button
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            }
            return const LoadingState();
          },
        ),
        // Use Builder instead of BlocBuilder to ensure rebuild when setState is called
        bottomNavigationBar: Builder(
          builder: (context) {
            // Use cached values from state, recalculate grandTotal with current postage
            final selectedItems = _cachedSelectedItems;
            final grandTotal = _calculateGrandTotal(selectedItems);

            // If no items, show nothing
            if (selectedItems.isEmpty) {
              return const SizedBox.shrink();
            }

            return PaymentBottomBar(
              selectedItems: selectedItems,
              grandTotal: grandTotal,
              isDark: isDark,
              paymentMethods: _paymentMethods,
              paymentType: _paymentType,
              isIndirectCheckout: widget.isIndirectCheckout,
              onSubmitOrder: () => widget.isIndirectCheckout
                  ? _showIndirectValidationDialog(selectedItems, isDark)
                  : _submitOrder(selectedItems, isDark),
              onSaveDraft: () => _saveDraft(selectedItems),
            );
          },
        ),
      ),
    );
  }

  /// Calculate grand total including postage
  double _calculateGrandTotal(List<CartEntity> selectedItems) {
    final itemsTotal = selectedItems.fold(
        0.0, (sum, item) => sum + (item.netPrice * item.quantity));

    // Parse postage from currency format
    double postage = 0.0;
    if (_postageController.text.isNotEmpty) {
      postage = FormatHelper.parseCurrencyToDouble(_postageController.text);
    }

    return itemsTotal + postage;
  }

  List<Map<String, dynamic>> _convertPaymentMethodsToApiFormat() {
    return _paymentMethods.map((payment) {
      // Get payment category based on methodType
      final paymentCategory = _getPaymentCategoryFromMethod(payment.methodType);

      return {
        'payment_method': paymentCategory,
        'payment_bank': payment.methodName,
        'payment_number': payment.reference ?? '',
        'payment_amount': payment.amount,
        'note': payment.note, // Use actual note only, no auto-generation
        'receipt_image_path': payment.receiptImagePath,
        'payment_date': payment.paymentDate,
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

  void _removePaymentMethod(int index) {
    setState(() {
      _paymentMethods.removeAt(index);
      // Recalculate total paid after removing payment method
      _recalculateTotalPaid();
    });
  }

  void _showPaymentMethodDialog(double grandTotal, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => PaymentMethodDialog(
        grandTotal: grandTotal,
        isDark: isDark,
        existingPayments: _paymentMethods,
        onPaymentAdded: (payment) {
          setState(() {
            _paymentMethods.add(payment);
            // Recalculate total paid after adding payment method
            _recalculateTotalPaid();
          });
          // Force rebuild by calling setState again after a microtask
          Future.microtask(() {
            if (mounted) {
              setState(() {});
            }
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
                    const Icon(
                      Icons.receipt,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: AppPadding.p8),
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
                                  ? AppColors.borderDark
                                  : AppColors.borderLight, // 30% - Border
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error, // Status color
                                size: 48,
                              ),
                              const SizedBox(height: AppPadding.p8),
                              Text(
                                'Gagal memuat gambar',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.error, // Status color
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
}
