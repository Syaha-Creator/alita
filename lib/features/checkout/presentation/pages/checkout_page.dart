import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../data/models/payment_entry.dart';
import '../../data/services/local_contact_service.dart';
import '../../data/utils/checkout_payload_builder.dart';
import '../../logic/bonus_takeaway_state.dart';
import '../../logic/checkout_form_validator.dart';
import '../../logic/checkout_provider.dart';
import '../../logic/quotation_save_handler.dart';
import '../widgets/active_draft_banner.dart';
import '../widgets/checkout_approval_card.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/checkout_payment_card.dart';
import '../widgets/contact_picker_bottom_sheet.dart';
import '../widgets/customer_info_section.dart';
import '../widgets/delivery_info_section.dart';
import '../widgets/checkout_approver_content.dart';
import '../widgets/checkout_order_summary.dart';
import '../widgets/checkout_payment_info_section.dart';
import '../widgets/region_picker_bottom_sheet.dart';
import '../widgets/shipping_info_section.dart';
import '../../../quotation/data/quotation_model.dart';
import '../../../quotation/logic/quotation_list_provider.dart';
// activeDraftProvider is exported from quotation_list_provider.dart

/// B2B Checkout / Buat Surat Pesanan
///
/// When [selectedCartItems] is non-null, only these items are shown and
/// submitted; on success only these are removed from the cart (selective checkout).
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({
    super.key,
    this.selectedCartItems,
    this.restoredQuotation,
  });

  final List<CartItem>? selectedCartItems;

  /// When non-null, the checkout was opened from a saved quotation draft.
  /// Customer info will be pre-filled from this model.
  final QuotationModel? restoredQuotation;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _postageCtrl = TextEditingController();

  // Section keys for scroll-to-error
  final _customerSectionKey = GlobalKey();
  final _deliverySectionKey = GlobalKey();
  final _approvalSectionKey = GlobalKey();
  final _paymentSectionKey = GlobalKey();

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

  // ── Payment (multi-payment) ─────────────────────────────────────
  bool _isLunas = true;
  final List<PaymentEntry> _payments = [];
  final ImagePicker _picker = ImagePicker();

  bool get _isMultiPayment => _payments.length > 1;

  double get _totalPaid =>
      _payments.fold(0.0, (sum, e) => sum + e.parsedAmount);

  /// Auto-determined payment status when multi-payment.
  bool get _effectiveIsLunas =>
      _isMultiPayment ? _totalPaid >= _totalAkhir : _isLunas;

  bool _isShippingSameAsCustomer = true;
  bool _showBackupPhone = false;
  bool _shouldSaveCustomerContact = true;
  bool _isFromContactBook = false;
  String? _selectedContactId;
  final _takeAway = BonusTakeAwayState();

  double _grandTotal = 0;
  DateTime? _lastPerfReportAt;

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
    _payments.add(PaymentEntry());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).fetchApprovers();
    });
    _updatePaymentAmountUI();
    _postageCtrl.addListener(() {
      setState(() {});
      if (!_isMultiPayment && _isLunas) _updatePaymentAmountUI();
    });
    _prefillFromQuotation();
  }

  void _prefillFromQuotation() {
    final q = widget.restoredQuotation ?? ref.read(activeDraftProvider);
    if (q == null) return;

    // ── Customer ──
    _customerNameCtrl.text = q.customerName;
    _customerEmailCtrl.text = q.customerEmail;
    _customerPhoneCtrl.text = q.customerPhone;
    if (q.customerPhone2.isNotEmpty) {
      _customerPhone2Ctrl.text = q.customerPhone2;
      _showBackupPhone = true;
    }
    _customerAddressCtrl.text = q.customerAddress;

    // ── Region ──
    if (q.regionProvinsi.isNotEmpty) _selectedProvinsi = q.regionProvinsi;
    if (q.regionKota.isNotEmpty) _selectedKota = q.regionKota;
    if (q.regionKecamatan.isNotEmpty) _selectedKecamatan = q.regionKecamatan;
    if (q.regionText.isNotEmpty) _regionCtrl.text = q.regionText;

    // ── Shipping ──
    _isShippingSameAsCustomer = q.isShippingSameAsCustomer;
    if (!q.isShippingSameAsCustomer) {
      _shippingNameCtrl.text = q.shippingName;
      _shippingPhoneCtrl.text = q.shippingPhone;
      _shippingAddressCtrl.text = q.shippingAddress;
      if (q.shippingRegionProvinsi.isNotEmpty) {
        _shippingProvinsi = q.shippingRegionProvinsi;
      }
      if (q.shippingRegionKota.isNotEmpty) {
        _shippingKota = q.shippingRegionKota;
      }
      if (q.shippingRegionKecamatan.isNotEmpty) {
        _shippingKecamatan = q.shippingRegionKecamatan;
      }
      if (q.shippingRegionText.isNotEmpty) {
        _shippingRegionCtrl.text = q.shippingRegionText;
      }
    }

    // ── Delivery ──
    final rawDate = q.requestDate;
    if (rawDate != null) {
      _requestDate = DateTime.tryParse(rawDate);
    }
    _isTakeAway = q.isTakeAway;
    if (q.postage.isNotEmpty) _postageCtrl.text = q.postage;
    if (q.scCode.isNotEmpty) _scCodeCtrl.text = q.scCode;

    // ── Notes ──
    _notesController.text = q.notes;
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
    if (_payments.isEmpty) return;
    if (!_isMultiPayment && _isLunas) {
      _payments.first.amountCtrl.text =
          AppFormatters.currencyIdrNoSymbol(_totalAkhir);
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
    for (final p in _payments) {
      p.dispose();
    }
    _postageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final buildSw = Stopwatch()..start();
    final List<CartItem> cartItems =
        widget.selectedCartItems ?? ref.watch(cartProvider);
    final totalAmount = _effectiveTotal(ref);
    final checkoutState = ref.watch(checkoutProvider);
    final totalBonusRows = cartItems.fold<int>(
      0,
      (sum, item) => sum + item.bonusSnapshots.length,
    );

    if (_grandTotal != totalAmount) {
      _grandTotal = totalAmount;
      if (_isLunas) _updatePaymentAmountUI();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      buildSw.stop();
      _reportCheckoutListPerformance(
        itemCount: cartItems.length,
        bonusRows: totalBonusRows,
        paymentCount: _payments.length,
        frameBuildMs: buildSw.elapsedMilliseconds,
      );
    });

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

        // Mark the source quotation as converted (if any).
        final sourceDraft =
            widget.restoredQuotation ?? ref.read(activeDraftProvider);
        if (sourceDraft != null) {
          ref.read(quotationListProvider.notifier).update(
                sourceDraft.copyWith(status: QuotationStatus.converted),
              );
        }
        ref.read(activeDraftProvider.notifier).state = null;

        AppFeedback.show(
          context,
          message: 'Surat Pesanan ${next.successNoSp} Berhasil Dibuat!',
          type: AppFeedbackType.success,
          floating: true,
          duration: const Duration(seconds: 3),
        );
        context.pushReplacement('/success');
      }
      final submitError = next.submitError;
      if (submitError != null && prev?.submitError != submitError) {
        _showSubmitErrorDialog(submitError);
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
        actions: [
          IconButton(
            tooltip: 'Simpan Penawaran (PDF)',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => _handleSaveQuotation(context, cartItems),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Active Draft Banner ───────────────────────────
                if (ref.watch(activeDraftProvider) case final draft?)
                  ActiveDraftBanner(
                    name: draft.customerName,
                    onClear: () {
                      ref.read(activeDraftProvider.notifier).state = null;
                    },
                  ),

                // ── Card 1: Customer Info + Shipping ──────────────
                Container(
                  key: _customerSectionKey,
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
                  key: _deliverySectionKey,
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
                  key: _approvalSectionKey,
                  isLoading: checkoutState.isLoadingApprovers,
                  hasError: checkoutState.approversError != null &&
                      checkoutState.approvers.isEmpty,
                  errorMessage: checkoutState.approversError,
                  onRetry: () =>
                      ref.read(checkoutProvider.notifier).fetchApprovers(),
                  child: CheckoutApproverContent(
                    approvers: checkoutState.approvers,
                    selectedSpv: checkoutState.selectedSpv,
                    selectedManager: checkoutState.selectedManager,
                    requiresManager: _requiresManagerApproval(cartItems),
                    onSpvChanged: (v) =>
                        ref.read(checkoutProvider.notifier).selectSpv(v),
                    onManagerChanged: (v) =>
                        ref.read(checkoutProvider.notifier).selectManager(v),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 4: Order Summary ─────────────────────────
                _buildSectionCard(
                  title: 'Ringkasan Pesanan',
                  child: CheckoutOrderSummary(
                    cartItems: cartItems,
                    priceFmt: _priceFmt,
                    isBonusTakeAwayChecked: _isBonusTakeAwayChecked,
                    currentTakeAwayQty: _currentTakeAwayQty,
                    onTakeAwayToggled: _toggleBonusTakeAway,
                    onTakeAwayQtyChanged: _setTakeAwayQty,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card 5: Payment Info ──────────────────────────
                _buildSectionCard(
                  key: _paymentSectionKey,
                  title: 'Informasi Pembayaran',
                  trailing: _buildAddPaymentChip(),
                  child: CheckoutPaymentInfoSection(
                    paymentCount: _payments.length,
                    isMultiPayment: _isMultiPayment,
                    paymentCardBuilder: (_, i) => _buildPaymentCard(i),
                    paymentSummary: _buildPaymentSummary(),
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

  void _reportCheckoutListPerformance({
    required int itemCount,
    required int bonusRows,
    required int paymentCount,
    required int frameBuildMs,
  }) {
    if (itemCount < 12) return;
    final now = DateTime.now();
    final last = _lastPerfReportAt;
    if (last != null && now.difference(last).inSeconds < 6) return;
    _lastPerfReportAt = now;
    AppTelemetry.event(
      'checkout_long_list_frame',
      data: {
        'items': itemCount,
        'bonus_rows': bonusRows,
        'payments': paymentCount,
        'build_ms': frameBuildMs,
      },
      tag: 'CheckoutPerf',
    );
  }

  // ─────────────────────────── Helpers ──────────────────────────

  bool _requiresManagerApproval(List<CartItem> cartItems) {
    return cartItems.any((item) => item.discount3 > 0);
  }

  Future<void> _pickRequestDate() async {
    final now = DateTime.now();
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: _requestDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Permintaan Kirim',
    );
    if (!mounted) return;
    if (picked != null) setState(() => _requestDate = picked);
  }

  Future<void> _pickImage(ImageSource source, int paymentIndex) async {
    final sw = Stopwatch()..start();
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (!mounted) return;
      if (picked != null) {
        setState(() => _payments[paymentIndex].receiptImage = File(picked.path));
        sw.stop();
        AppTelemetry.event(
          'checkout_receipt_selected',
          data: {
            'source': source.name,
            'duration_ms': sw.elapsedMilliseconds,
          },
          tag: 'CheckoutUpload',
        );
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'Checkout: image pick');
      sw.stop();
      AppTelemetry.error(
        'checkout_receipt_pick_failed',
        data: {
          'source': source.name,
          'duration_ms': sw.elapsedMilliseconds,
          'error_type': e.runtimeType.toString(),
        },
        tag: 'CheckoutUpload',
      );
      if (!mounted) return;
      AppFeedback.show(
        context,
        message: 'Gagal mengambil gambar. Periksa izin kamera/galeri.',
        type: AppFeedbackType.warning,
        floating: true,
      );
    }
  }

  void _showImageSourceBottomSheet(int paymentIndex) {
    ImageSourceSheet.show(
      context: context,
      title: 'Upload Bukti Pembayaran',
      onCamera: () => _pickImage(ImageSource.camera, paymentIndex),
      onGallery: () => _pickImage(ImageSource.gallery, paymentIndex),
    );
  }

  void _addPayment() {
    setState(() {
      _payments.add(PaymentEntry());
      if (_isMultiPayment) {
        // Switch first payment to editable (no longer auto-fill)
        final first = _payments.first;
        if (first.amountCtrl.text.isNotEmpty && _isLunas) {
          first.amountCtrl.clear();
        }
      }
    });
  }

  void _removePayment(int index) {
    if (_payments.length <= 1) return;
    setState(() {
      _payments[index].dispose();
      _payments.removeAt(index);
      // Back to single → restore Lunas/DP behavior
      if (!_isMultiPayment && _isLunas) {
        _updatePaymentAmountUI();
      }
    });
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

        final kec = _selectedKecamatan;
        final kota = _selectedKota;
        final prov = _selectedProvinsi;
        if (kec != null || kota != null || prov != null) {
          _regionCtrl.text = [
            if (kec != null) 'Kec. $kec',
            if (kota != null) kota,
            if (prov != null) prov,
          ].join(', ');
        }

        _showBackupPhone = phone2.isNotEmpty;
        _isFromContactBook = true;
        _shouldSaveCustomerContact = false;
        _selectedContactId = selectedId;
      });
    }
  }

  // ── Save Quotation (delegated to extracted handler) ─────────

  Future<void> _handleSaveQuotation(
      BuildContext context, List<CartItem> cartItems) async {
    await QuotationSaveHandler.save(
      context: context,
      ref: ref,
      cartItems: cartItems,
      selectedCartItems: widget.selectedCartItems,
      existingDraft:
          widget.restoredQuotation ?? ref.read(activeDraftProvider),
      popBackToHistory: widget.restoredQuotation != null,
      customerName: _customerNameCtrl.text.trim(),
      customerEmail: _customerEmailCtrl.text.trim(),
      customerPhone: _customerPhoneCtrl.text.trim(),
      customerPhone2: _customerPhone2Ctrl.text.trim(),
      customerAddress: _customerAddressCtrl.text.trim(),
      regionProvinsi: _selectedProvinsi,
      regionKota: _selectedKota,
      regionKecamatan: _selectedKecamatan,
      regionText: _regionCtrl.text.trim(),
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      shippingName: _shippingNameCtrl.text.trim(),
      shippingPhone: _shippingPhoneCtrl.text.trim(),
      shippingAddress: _shippingAddressCtrl.text.trim(),
      shippingRegionProvinsi: _shippingProvinsi,
      shippingRegionKota: _shippingKota,
      shippingRegionKecamatan: _shippingKecamatan,
      shippingRegionText: _shippingRegionCtrl.text.trim(),
      requestDate: _requestDate,
      isTakeAway: _isTakeAway,
      postage: _postageCtrl.text.trim(),
      scCode: _scCodeCtrl.text.trim(),
      grandTotal: _grandTotal,
      totalAkhir: _totalAkhir,
      notes: _notesController.text.trim(),
    );
  }

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _handleCreateOrder(BuildContext context) async {
    if (ifOfflineShowFeedback(
      context,
      isOffline: ref.read(isOfflineProvider),
    )) {
      return;
    }
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

    final userId = profile?.id ?? 0;
    final paymentPayloads = <Map<String, dynamic>>[];
    final receiptImages = <File?>[];

    if (!_isMultiPayment) {
      // Single payment — use original builder for backward compatibility
      paymentPayloads.add(CheckoutPayloadBuilder.buildPaymentPayload(
        isLunas: _isLunas,
        totalAkhir: _totalAkhir,
        paymentAmountText: _payments.first.amountCtrl.text,
        paymentMethod: _payments.first.method,
        paymentBank: _payments.first.bank,
        otherChannelText: _payments.first.otherChannelCtrl.text,
        paymentRefText: _payments.first.refCtrl.text,
        paymentDate: _payments.first.date,
        paymentNoteText: _payments.first.noteCtrl.text,
        userId: userId,
      ));
      receiptImages.add(_payments.first.receiptImage);
    } else {
      for (final p in _payments) {
        paymentPayloads.add(CheckoutPayloadBuilder.buildPaymentEntryPayload(
          amountText: p.amountCtrl.text,
          method: p.method,
          bank: p.bank,
          otherChannelText: p.otherChannelCtrl.text,
          refText: p.refCtrl.text,
          date: p.date,
          noteText: p.noteCtrl.text,
          userId: userId,
        ));
        receiptImages.add(p.receiptImage);
      }
    }

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
          paymentPayloads: paymentPayloads,
          receiptImages: receiptImages,
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
    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      final (:key, :label) = _findFirstFormError();
      _showErrorAndScroll('Lengkapi field wajib di bagian $label.', key);
      return false;
    }

    if (_selectedProvinsi == null ||
        _selectedKota == null ||
        _selectedKecamatan == null) {
      _showErrorAndScroll('Pilih wilayah pelanggan.', _customerSectionKey);
      return false;
    }
    if (!_isShippingSameAsCustomer &&
        (_shippingProvinsi == null ||
            _shippingKota == null ||
            _shippingKecamatan == null)) {
      _showErrorAndScroll('Pilih wilayah penerima.', _customerSectionKey);
      return false;
    }
    final checkoutState = ref.read(checkoutProvider);
    if (checkoutState.selectedSpv == null) {
      _showErrorAndScroll('Pilih Supervisor (SPV).', _approvalSectionKey);
      return false;
    }
    final cartItems = _effectiveCartItems(ref);
    if (_requiresManagerApproval(cartItems) &&
        checkoutState.selectedManager == null) {
      _showErrorAndScroll(
          'Pesanan ini memerlukan persetujuan Manager.', _approvalSectionKey);
      return false;
    }
    for (int i = 0; i < _payments.length; i++) {
      final p = _payments[i];
      if (p.receiptImage == null) {
        final label = _isMultiPayment
            ? 'Bukti Pembayaran ${i + 1} wajib diupload.'
            : 'Upload Bukti Pembayaran wajib diisi.';
        _showErrorAndScroll(label, _paymentSectionKey);
        return false;
      }
    }
    if (!_effectiveIsLunas) {
      if (_totalPaid < _minimumDp) {
        _showErrorAndScroll(
            'Total pembayaran minimal ${_priceFmt(_minimumDp)} (30% DP).',
            _paymentSectionKey);
        return false;
      }
    }
    return true;
  }

  ({GlobalKey key, String label}) _findFirstFormError() {
    final checkoutState = ref.read(checkoutProvider);
    return CheckoutFormValidator.findFirstFormError(
      customerName: _customerNameCtrl.text,
      customerEmail: _customerEmailCtrl.text,
      customerPhone: _customerPhoneCtrl.text,
      customerAddress: _customerAddressCtrl.text,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      shippingName: _shippingNameCtrl.text,
      shippingPhone: _shippingPhoneCtrl.text,
      shippingAddress: _shippingAddressCtrl.text,
      isTakeAway: _isTakeAway,
      requestDate: _requestDate,
      hasSelectedSpv: checkoutState.selectedSpv != null,
      requiresManager: _requiresManagerApproval(_effectiveCartItems(ref)),
      hasSelectedManager: checkoutState.selectedManager != null,
      payments: _payments,
      customerSectionKey: _customerSectionKey,
      deliverySectionKey: _deliverySectionKey,
      approvalSectionKey: _approvalSectionKey,
      paymentSectionKey: _paymentSectionKey,
    );
  }

  void _showErrorAndScroll(String message, GlobalKey sectionKey) {
    AppFeedback.show(
      context,
      message: message,
      type: AppFeedbackType.error,
      floating: true,
      duration: const Duration(seconds: 3),
    );
    final ctx = sectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _showLoadingOverlay(BuildContext context) {
    LoadingOverlay.show(
      context,
      title: 'Menyimpan Pesanan...',
      subtitle: 'Mohon tidak menutup aplikasi',
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────

  Widget _buildSectionCard({
    Key? key,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return SectionCard(
      key: key,
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

  // ── Payment card builders (delegated to extracted widgets) ───

  Widget _buildPaymentCard(int index) {
    final entry = _payments[index];
    return CheckoutPaymentCard(
      index: index,
      entry: entry,
      isMultiPayment: _isMultiPayment,
      isLunas: _isLunas,
      totalAkhir: _totalAkhir,
      minimumDp: _minimumDp,
      onRemove: () => _removePayment(index),
      onMethodChanged: (val) => setState(() {
        entry.method = val;
        entry.bank = null;
        if (val != 'Lainnya') entry.otherChannelCtrl.clear();
      }),
      onChannelChanged: (val) => setState(() {
        entry.bank = val;
        if (val != 'Lainnya') entry.otherChannelCtrl.clear();
      }),
      onPickDate: () async {
        final picked = await showAdaptiveDatePicker(
          context: context,
          initialDate: entry.date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          helpText: 'Pilih Tanggal Bayar',
        );
        if (!mounted) return;
        if (picked != null) setState(() => entry.date = picked);
      },
      onPickReceipt: () => _showImageSourceBottomSheet(index),
      onRemoveReceipt: () => setState(() => entry.receiptImage = null),
      onLunasTap: () => setState(() {
        _isLunas = true;
        _updatePaymentAmountUI();
      }),
      onDpTap: () => setState(() {
        _isLunas = false;
        _payments.first.amountCtrl.clear();
      }),
      onAmountChanged: (_) => setState(() {}),
    );
  }

  Widget _buildAddPaymentChip() => AddPaymentChip(onTap: _addPayment);

  Widget _buildPaymentSummary() => CheckoutPaymentSummary(
        totalAkhir: _totalAkhir,
        totalPaid: _totalPaid,
      );

  // ── TakeAway helpers (delegated to BonusTakeAwayState) ─────

  bool _isBonusTakeAwayChecked(int itemIndex, CartBonusSnapshot bonus) =>
      _takeAway.isChecked(itemIndex, bonus);

  int _currentTakeAwayQty(int itemIndex, CartBonusSnapshot bonus) =>
      _takeAway.currentQty(itemIndex, bonus);

  void _toggleBonusTakeAway(
      int itemIndex, CartBonusSnapshot bonus, bool checked) {
    setState(() => _takeAway.toggle(itemIndex, bonus, checked));
  }

  void _setTakeAwayQty(int itemIndex, CartBonusSnapshot bonus, int value) {
    setState(() => _takeAway.setQty(itemIndex, bonus, value));
  }
}
