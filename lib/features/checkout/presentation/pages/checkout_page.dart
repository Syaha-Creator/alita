import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/payment_form_content.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../data/checkout_config.dart';
import '../../data/models/approver_model.dart';
import '../../data/services/local_contact_service.dart';
import '../../data/utils/checkout_payload_builder.dart';
import '../../logic/checkout_provider.dart';
import '../widgets/checkout_approval_card.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/contact_picker_bottom_sheet.dart';
import '../widgets/customer_info_section.dart';
import '../widgets/delivery_info_section.dart';
import '../widgets/order_item_tile.dart';
import '../widgets/region_picker_bottom_sheet.dart';
import '../widgets/searchable_dropdown_field.dart';
import '../widgets/shipping_info_section.dart';

/// B2B Checkout / Buat Surat Pesanan
///
/// When [selectedCartItems] is non-null, only these items are shown and
/// submitted; on success only these are removed from the cart (selective checkout).
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key, this.selectedCartItems});

  final List<CartItem>? selectedCartItems;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _postageCtrl = TextEditingController();

  List<CartItem> _effectiveCartItems(WidgetRef ref) =>
      widget.selectedCartItems ?? ref.read(cartProvider);

  double _effectiveTotal(WidgetRef ref) {
    final selected = widget.selectedCartItems;
    if (selected != null) {
      return selected.fold(0.0, (sum, item) => sum + item.totalPrice);
    }
    return ref.read(cartTotalAmountProvider);
  }

  DateTime? _requestDate;
  bool _isTakeAway = false;

  // ── Payment ────────────────────────────────────────────────────
  bool _isLunas = true;
  final _paymentAmountCtrl = TextEditingController();
  String? _paymentMethod;
  String? _paymentBank;
  final _otherChannelCtrl = TextEditingController();
  final _paymentRefCtrl = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  final _paymentNoteCtrl = TextEditingController();
  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  bool _isShippingSameAsCustomer = true;
  bool _showBackupPhone = false;
  bool _shouldSaveCustomerContact = true;
  bool _isFromContactBook = false;
  String? _selectedContactId;
  final Set<String> _checkedTakeAwaySkus = <String>{};
  final Map<String, int> _takeAwayQtys = {};

  double _grandTotal = 0;

  // ── Customer ───────────────────────────────────────────────────
  final _customerNameCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerPhone2Ctrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();

  // ── Region ─────────────────────────────────────────────────────
  String? _selectedProvinsi;
  String? _selectedKota;
  String? _selectedKecamatan;
  final _regionCtrl = TextEditingController();

  // ── Shipping ───────────────────────────────────────────────────
  final _shippingNameCtrl = TextEditingController();
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingAddressCtrl = TextEditingController();
  final _shippingRegionCtrl = TextEditingController();
  String? _shippingProvinsi;
  String? _shippingKota;
  String? _shippingKecamatan;

  // ── Notes ──────────────────────────────────────────────────────
  final _notesController = TextEditingController();
  final _scCodeCtrl = TextEditingController();

  static String _priceFmt(num value) => AppFormatters.currencyIdr(value);

  @override
  void initState() {
    super.initState();
    // Trigger approvers fetch via provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).fetchApprovers();
    });
    _updatePaymentAmountUI();
    _postageCtrl.addListener(() {
      setState(() {});
      if (_isLunas) _updatePaymentAmountUI();
    });
  }

  double get _minimumDp => _grandTotal * 0.3;

  double get _totalAkhir {
    final ongkir = double.tryParse(
          ThousandsSeparatorInputFormatter.digitsOnly(_postageCtrl.text),
        ) ??
        0;
    return _grandTotal + ongkir;
  }

  void _updatePaymentAmountUI() {
    if (_isLunas) {
      _paymentAmountCtrl.text = AppFormatters.currencyIdrNoSymbol(_totalAkhir);
    } else {
      _paymentAmountCtrl.clear();
    }
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerPhone2Ctrl.dispose();
    _customerAddressCtrl.dispose();
    _regionCtrl.dispose();
    _shippingNameCtrl.dispose();
    _shippingPhoneCtrl.dispose();
    _shippingAddressCtrl.dispose();
    _shippingRegionCtrl.dispose();
    _notesController.dispose();
    _scCodeCtrl.dispose();
    _paymentAmountCtrl.dispose();
    _paymentRefCtrl.dispose();
    _otherChannelCtrl.dispose();
    _paymentNoteCtrl.dispose();
    _postageCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final List<CartItem> cartItems =
        widget.selectedCartItems ?? ref.watch(cartProvider);
    final totalAmount = _effectiveTotal(ref);
    final checkoutState = ref.watch(checkoutProvider);

    if (_grandTotal != totalAmount) {
      _grandTotal = totalAmount;
      if (_isLunas) _updatePaymentAmountUI();
    }

    // Listen for submission results from provider
    ref.listen<CheckoutState>(checkoutProvider, (prev, next) {
      if (!context.mounted) return;
      // Dismiss loading overlay when submission completes
      if (prev?.isSubmitting == true && !next.isSubmitting) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      if (next.submitSuccess && next.successNoSp != null) {
        ref.read(checkoutProvider.notifier).clearSubmitResult();
        AppFeedback.show(
          context,
          message: 'Surat Pesanan ${next.successNoSp} Berhasil Dibuat!',
          type: AppFeedbackType.success,
          floating: true,
          duration: const Duration(seconds: 3),
        );
        context.pushReplacement('/success');
      }
      if (next.submitError != null && prev?.submitError != next.submitError) {
        _showSubmitErrorDialog(next.submitError!);
      }
    });

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Buat Surat Pesanan'), elevation: 0),
        body: EmptyStateView(
          icon: Icons.shopping_cart_outlined,
          title: 'Keranjang kosong',
          subtitle: 'Tambahkan produk terlebih dahulu',
          action: ActionButtonBar(
            fullWidth: false,
            mainAxisSize: MainAxisSize.min,
            height: 44,
            borderRadius: 14,
            primaryLabel: 'Kembali ke Beranda',
            onPrimaryPressed: () => context.go('/'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Surat Pesanan'),
        elevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card 1: Customer Info + Shipping ──────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomerInfoSection(
                        customerNameCtrl: _customerNameCtrl,
                        customerEmailCtrl: _customerEmailCtrl,
                        customerPhoneCtrl: _customerPhoneCtrl,
                        customerPhone2Ctrl: _customerPhone2Ctrl,
                        showBackupPhone: _showBackupPhone,
                        onToggleBackupPhone: () =>
                            setState(() => _showBackupPhone = true),
                        isFromContactBook: _isFromContactBook,
                        shouldSaveCustomerContact: _shouldSaveCustomerContact,
                        onToggleSaveContact: (v) =>
                            setState(() => _shouldSaveCustomerContact = v),
                        selectedContactId: _selectedContactId,
                        onContactFieldCleared: () => setState(() {
                          _selectedContactId = null;
                          _isFromContactBook = false;
                        }),
                        onPickContact: _pickContact,
                      ),
                      ShippingInfoSection(
                        customerAddressCtrl: _customerAddressCtrl,
                        regionCtrl: _regionCtrl,
                        isShippingSameAsCustomer: _isShippingSameAsCustomer,
                        onToggleSameAddress: (v) =>
                            setState(() => _isShippingSameAsCustomer = v),
                        onPickCustomerRegion: () => _pickRegion(isShipping: false),
                        shippingNameCtrl: _shippingNameCtrl,
                        shippingPhoneCtrl: _shippingPhoneCtrl,
                        shippingAddressCtrl: _shippingAddressCtrl,
                        shippingRegionCtrl: _shippingRegionCtrl,
                        onPickShippingRegion: () => _pickRegion(isShipping: true),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 2: Delivery Info ─────────────────────────
                _buildSectionCard(
                  title: 'Informasi Pengiriman',
                  child: DeliveryInfoSection(
                    requestDate: _requestDate,
                    onPickRequestDate: _pickRequestDate,
                    isTakeAway: _isTakeAway,
                    onTakeAwayChanged: (v) => setState(() => _isTakeAway = v),
                    postageCtrl: _postageCtrl,
                    notesController: _notesController,
                    scCodeCtrl: _scCodeCtrl,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 3: Approval ──────────────────────────────
                CheckoutApprovalCard(
                  isLoading: checkoutState.isLoadingApprovers,
                  hasError: checkoutState.approversError != null &&
                      checkoutState.approvers.isEmpty,
                  errorMessage: checkoutState.approversError,
                  onRetry: () =>
                      ref.read(checkoutProvider.notifier).fetchApprovers(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchableDropdownField<Approver>(
                        label: 'Supervisor (SPV)',
                        hint: 'Pilih SPV',
                        selectedValue: checkoutState.selectedSpv,
                        items: checkoutState.approvers,
                        itemAsString: (a) => a.displayLabel,
                        onChanged: (v) =>
                            ref.read(checkoutProvider.notifier).selectSpv(v),
                      ),
                      if (_requiresManagerApproval(cartItems)) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const FormFieldLabel('Manager'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Diskon 3 terdeteksi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SearchableDropdownField<Approver>(
                          label: 'Manager',
                          hint: 'Pilih Manager',
                          selectedValue: checkoutState.selectedManager,
                          items: checkoutState.approvers,
                          itemAsString: (a) => a.displayLabel,
                          onChanged: (v) => ref
                              .read(checkoutProvider.notifier)
                              .selectManager(v),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 4: Order Summary ─────────────────────────
                _buildSectionCard(
                  title: 'Ringkasan Pesanan',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return RepaintBoundary(
                            child: OrderItemTile(
                              item: cartItems[index],
                              priceFmt: _priceFmt,
                              isBonusTakeAwayChecked: (b) =>
                                  _isBonusTakeAwayChecked(index, b),
                              currentTakeAwayQty: (b) =>
                                  _currentTakeAwayQty(index, b),
                              onTakeAwayToggled: (b, checked) =>
                                  _toggleBonusTakeAway(index, b, checked),
                              onTakeAwayQtyChanged: (b, qty) =>
                                  _setTakeAwayQty(index, b, qty),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 5: Payment Info ──────────────────────────
                _buildSectionCard(
                  title: 'Informasi Pembayaran',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaymentFormContent(
                        leftModeLabel: 'Lunas',
                        rightModeLabel: 'Down Payment (DP)',
                        isLeftModeSelected: _isLunas,
                        onTapLeftMode: () => setState(() {
                          _isLunas = true;
                          _updatePaymentAmountUI();
                        }),
                        onTapRightMode: () => setState(() {
                          _isLunas = false;
                          _updatePaymentAmountUI();
                        }),
                        amountLabel: 'Nominal Pembayaran *',
                        amountController: _paymentAmountCtrl,
                        amountReadOnly: _isLunas,
                        amountFilled: _isLunas,
                        amountSuffixIcon: _isLunas
                            ? const Tooltip(
                                message: 'Nominal otomatis = Total Pesanan',
                                child: Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: AppColors.textTertiary,
                                ),
                              )
                            : null,
                        amountFocusedBorderSide: BorderSide(
                          color:
                              _isLunas ? AppColors.border : AppColors.primary,
                          width: _isLunas ? 1 : 2,
                        ),
                        amountStatusWidget: !_isLunas
                            ? Text(
                                'Minimal DP (30%): ${_priceFmt(_minimumDp)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              )
                            : const Text(
                                'Nominal mengikuti Total Pesanan (Subtotal + Ongkir)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                        paymentMethods: CheckoutConfig.paymentMethods,
                        paymentMethod: _paymentMethod,
                        paymentChannel: _paymentBank,
                        customChannelController: _otherChannelCtrl,
                        paymentChannelsMap: CheckoutConfig.paymentChannelsMap,
                        onPaymentMethodChanged: (val) => setState(() {
                          _paymentMethod = val;
                          _paymentBank = null;
                          if (val != 'Lainnya') _otherChannelCtrl.clear();
                        }),
                        onPaymentChannelChanged: (val) => setState(() {
                          _paymentBank = val;
                          if (val != 'Lainnya') _otherChannelCtrl.clear();
                        }),
                        referenceLabel: 'No. Referensi / Resi',
                        referenceController: _paymentRefCtrl,
                        dateLabel: 'Tanggal Bayar *',
                        paymentDate: _paymentDate,
                        onPickDate: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _paymentDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (!mounted) return;
                          if (picked != null) {
                            setState(() => _paymentDate = picked);
                          }
                        },
                        inlineReferenceAndDate: true,
                        showPaymentNote: true,
                        paymentNoteController: _paymentNoteCtrl,
                        receiptImage: _receiptImage,
                        onPickOrEditReceipt: _showImageSourceBottomSheet,
                        onRemoveReceipt: () =>
                            setState(() => _receiptImage = null),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CheckoutBottomBar(
        totalFormatted: _priceFmt(_totalAkhir),
        showRetryBanner: checkoutState.retryDetails.isNotEmpty,
        retryNoSp: checkoutState.retryNoSp,
        failedCount: checkoutState.retryDetails.length,
        failedLabels: checkoutState.retryDetails.map((e) => e.label).toList(),
        onRetry: () => ref
            .read(checkoutProvider.notifier)
            .retryFailedDetails(selectedCartItems: widget.selectedCartItems),
        onSubmit: () => _handleCreateOrder(context),
        submitButtonEnabled:
            checkoutState.retryDetails.isEmpty && !checkoutState.isSubmitting,
      ),
    );
  }

  // ─────────────────────────── Helpers ──────────────────────────

  bool _requiresManagerApproval(List<CartItem> cartItems) {
    return cartItems.any((item) => item.discount3 > 0);
  }

  Future<void> _pickRequestDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Permintaan Kirim',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _requestDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() => _receiptImage = File(picked.path));
        _formKey.currentState?.validate();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceBottomSheet() {
    ImageSourceSheet.show(
      context: context,
      title: 'Upload Bukti Pembayaran',
      onCamera: () => _pickImage(ImageSource.camera),
      onGallery: () => _pickImage(ImageSource.gallery),
    );
  }

  Future<void> _pickRegion({required bool isShipping}) async {
    final result = await showModalBottomSheet<RegionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RegionPickerBottomSheet(),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (isShipping) {
        _shippingProvinsi = result.provinsi;
        _shippingKota = result.kota;
        _shippingKecamatan = result.kecamatan;
        _shippingRegionCtrl.text =
            'Kec. ${result.kecamatan}, ${result.kota}, ${result.provinsi}';
      } else {
        _selectedProvinsi = result.provinsi;
        _selectedKota = result.kota;
        _selectedKecamatan = result.kecamatan;
        _regionCtrl.text =
            'Kec. ${result.kecamatan}, ${result.kota}, ${result.provinsi}';
      }
    });
  }

  Future<void> _pickContact() async {
    final contacts = await LocalContactService.getContacts();
    if (!mounted) return;
    if (contacts.isEmpty) {
      AppFeedback.plain(context, 'Belum ada kontak tersimpan.');
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ContactPickerBottomSheet(contacts: contacts),
    );

    if (!mounted) return;
    if (selected != null) {
      final phone2 = (selected['phone2'] as String?) ?? '';
      final selectedId = selected['id']?.toString();
      setState(() {
        _customerNameCtrl.text = selected['name'] ?? '';
        _customerPhoneCtrl.text = selected['phone'] ?? '';
        _customerPhone2Ctrl.text = phone2;
        _customerEmailCtrl.text = selected['email'] ?? '';
        _customerAddressCtrl.text =
            selected['alamat_detail'] ?? selected['address'] ?? '';

        _selectedProvinsi = selected['provinsi'] as String?;
        _selectedKota = selected['kota'] as String?;
        _selectedKecamatan = selected['kecamatan'] as String?;

        if (_selectedKecamatan != null ||
            _selectedKota != null ||
            _selectedProvinsi != null) {
          _regionCtrl.text = [
            if (_selectedKecamatan != null) 'Kec. $_selectedKecamatan',
            if (_selectedKota != null) _selectedKota!,
            if (_selectedProvinsi != null) _selectedProvinsi!,
          ].join(', ');
        }

        _showBackupPhone = phone2.isNotEmpty;
        _isFromContactBook = true;
        _shouldSaveCustomerContact = false;
        _selectedContactId = selectedId;
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _handleCreateOrder(BuildContext context) async {
    if (!_validateForm()) return;

    _showLoadingOverlay(context);

    final cartItems = _effectiveCartItems(ref);
    final profile = ref.read(profileProvider).valueOrNull;

    final headerPayload = CheckoutPayloadBuilder.buildHeaderPayload(
      workPlaceId: null,
      customerAddress: _customerAddressCtrl.text,
      selectedKecamatan: _selectedKecamatan,
      selectedKota: _selectedKota,
      selectedProvinsi: _selectedProvinsi,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      customerName: _customerNameCtrl.text,
      shippingName: _shippingNameCtrl.text,
      shippingAddress: _shippingAddressCtrl.text,
      shippingKecamatan: _shippingKecamatan,
      shippingKota: _shippingKota,
      shippingProvinsi: _shippingProvinsi,
      postageText: _postageCtrl.text,
      creatorId: profile?.id ?? 0,
      divisions: profile?.divisions ?? const [],
      cartItems: cartItems,
      grandTotal: _grandTotal,
      requestDate: _requestDate,
      customerPhone: _customerPhoneCtrl.text,
      customerEmail: _customerEmailCtrl.text,
      note: _notesController.text,
      salesCode: _scCodeCtrl.text,
      isTakeAway: _isTakeAway,
    );

    final contactsPayload = CheckoutPayloadBuilder.buildContactsPayload(
      primaryPhone: _customerPhoneCtrl.text,
      includeBackupPhone: _showBackupPhone,
      backupPhone: _customerPhone2Ctrl.text,
    );

    final paymentPayload = CheckoutPayloadBuilder.buildPaymentPayload(
      isLunas: _isLunas,
      totalAkhir: _totalAkhir,
      paymentAmountText: _paymentAmountCtrl.text,
      paymentMethod: _paymentMethod,
      paymentBank: _paymentBank,
      otherChannelText: _otherChannelCtrl.text,
      paymentRefText: _paymentRefCtrl.text,
      paymentDate: _paymentDate,
      paymentNoteText: _paymentNoteCtrl.text,
      userId: profile?.id ?? 0,
    );

    final newCustomerContact =
        CheckoutPayloadBuilder.buildNewCustomerContactPayload(
      customerName: _customerNameCtrl.text,
      customerPhone: _customerPhoneCtrl.text,
      customerEmail: _customerEmailCtrl.text,
      customerAddress: _customerAddressCtrl.text,
      regionText: _regionCtrl.text,
      selectedKecamatan: _selectedKecamatan,
      selectedKota: _selectedKota,
      selectedProvinsi: _selectedProvinsi,
      customerPhone2: _customerPhone2Ctrl.text,
    );
    if (_selectedContactId != null) {
      newCustomerContact['id'] = _selectedContactId;
    }

    unawaited(ref.read(checkoutProvider.notifier).submitOrder(
          cartItems: cartItems,
          headerPayload: headerPayload,
          contactsPayload: contactsPayload,
          paymentPayload: paymentPayload,
          receiptImage: _receiptImage,
          globalIsTakeAway: _isTakeAway,
          isBonusTakeAwayChecked: _isBonusTakeAwayChecked,
          currentTakeAwayQty: _currentTakeAwayQty,
          selectedContactId: _selectedContactId,
          shouldSaveCustomerContact: _shouldSaveCustomerContact,
          newCustomerContact: newCustomerContact,
          selectedCartItems: widget.selectedCartItems,
        ));
  }

  void _showSubmitErrorDialog(String message) {
    if (!mounted) return;
    final hasRetryDetails = ref.read(checkoutProvider).retryDetails.isNotEmpty;
    showAdaptiveAlert(
      context: context,
      title: hasRetryDetails ? 'Sebagian Barang Gagal' : 'Gagal Memproses',
      content: message,
      actions: [
        AdaptiveAction(
          label: hasRetryDetails ? 'Mengerti' : 'Tutup',
          isDefault: true,
          popResult: true,
        ),
      ],
    );
    ref.read(checkoutProvider.notifier).clearSubmitResult();
  }

  // ── Validation ────────────────────────────────────────────────

  bool _validateForm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.show(
        context,
        message: 'Harap lengkapi semua field yang wajib.',
        type: AppFeedbackType.error,
        floating: true,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
    if (!_isTakeAway && _requestDate == null) {
      AppFeedback.show(context,
          message: 'Pilih Tanggal Permintaan Kirim.',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    if (_selectedProvinsi == null ||
        _selectedKota == null ||
        _selectedKecamatan == null) {
      AppFeedback.show(context,
          message: 'Pilih wilayah pelanggan.',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    if (!_isShippingSameAsCustomer &&
        (_shippingProvinsi == null ||
            _shippingKota == null ||
            _shippingKecamatan == null)) {
      AppFeedback.show(context,
          message: 'Pilih wilayah penerima.',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    final checkoutState = ref.read(checkoutProvider);
    if (checkoutState.selectedSpv == null) {
      AppFeedback.show(context,
          message: 'Pilih Supervisor (SPV).',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    final cartItems = _effectiveCartItems(ref);
    if (_requiresManagerApproval(cartItems) &&
        checkoutState.selectedManager == null) {
      AppFeedback.show(context,
          message: 'Pesanan ini memerlukan persetujuan Manager.',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    if (_receiptImage == null) {
      AppFeedback.show(context,
          message: 'Upload Bukti Pembayaran wajib diisi.',
          type: AppFeedbackType.error,
          floating: true,
          duration: const Duration(seconds: 3));
      return false;
    }
    if (!_isLunas) {
      final inputDp = double.tryParse(
            ThousandsSeparatorInputFormatter.digitsOnly(
                _paymentAmountCtrl.text),
          ) ??
          0;
      if (inputDp < _minimumDp) {
        AppFeedback.show(context,
            message: 'Nominal DP minimal ${_priceFmt(_minimumDp)}.',
            type: AppFeedbackType.error,
            floating: true,
            duration: const Duration(seconds: 3));
        return false;
      }
    }
    return true;
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(AppColors.accent),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Menyimpan Pesanan...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Mohon tidak menutup aplikasi',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
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

  // ── Reusable widgets ──────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return SectionCard(
      title: title,
      trailing: trailing,
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      child: child,
    );
  }

  // ── TakeAway helpers (per-bundle: key = itemIndex + bonus) ─────

  String _bonusTakeAwayKey(int itemIndex, CartBonusSnapshot bonus) =>
      '${itemIndex}_${bonus.sku.isNotEmpty ? bonus.sku : bonus.name}';

  bool _isBonusTakeAwayChecked(int itemIndex, CartBonusSnapshot bonus) {
    return _checkedTakeAwaySkus.contains(_bonusTakeAwayKey(itemIndex, bonus));
  }

  void _toggleBonusTakeAway(
      int itemIndex, CartBonusSnapshot bonus, bool checked) {
    final key = _bonusTakeAwayKey(itemIndex, bonus);
    setState(() {
      if (checked) {
        _checkedTakeAwaySkus.add(key);
        _takeAwayQtys[key] = (_takeAwayQtys[key] ?? 0).clamp(1, bonus.qty);
      } else {
        _checkedTakeAwaySkus.remove(key);
        _takeAwayQtys[key] = 0;
      }
    });
  }

  int _currentTakeAwayQty(int itemIndex, CartBonusSnapshot bonus) {
    final raw = _takeAwayQtys[_bonusTakeAwayKey(itemIndex, bonus)] ?? 0;
    return raw.clamp(0, bonus.qty);
  }

  void _setTakeAwayQty(int itemIndex, CartBonusSnapshot bonus, int value) {
    final key = _bonusTakeAwayKey(itemIndex, bonus);
    final clamped = value.clamp(0, bonus.qty);
    setState(() {
      _takeAwayQtys[key] = clamped;
      if (clamped <= 0) {
        _checkedTakeAwaySkus.remove(key);
      } else {
        _checkedTakeAwaySkus.add(key);
      }
    });
  }
}
