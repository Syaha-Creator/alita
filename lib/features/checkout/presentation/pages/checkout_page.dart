import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/user_facing_error.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/order_letter_date_utils.dart';
import '../../../../core/utils/network_guard.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/go_router_pop_scope.dart';
import '../../../../core/widgets/image_source_sheet.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../auth/logic/auth_provider.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../data/models/payment_entry.dart';
import '../../data/models/region_result.dart';
import '../../data/models/store_model.dart';
import '../../data/models/address_book_contact.dart';
import '../../logic/address_book_provider.dart';
import '../../data/utils/checkout_address_lines.dart';
import '../../data/utils/checkout_payload_builder.dart';
import '../../data/utils/checkout_channel_resolver.dart';
import '../../data/utils/indirect_approval_rules.dart';
import '../../logic/bonus_takeaway_state.dart';
import '../../logic/checkout_form_validator.dart';
import '../../logic/checkout_provider.dart';
import '../../logic/store_provider.dart';
import '../../logic/quotation_save_handler.dart';
import '../order_success_route_args.dart';
import '../widgets/active_draft_banner.dart';
import '../widgets/checkout_approval_card.dart';
import '../widgets/checkout_bottom_bar.dart';
import '../widgets/checkout_customer_shipping_card.dart';
import '../widgets/checkout_empty_state.dart';
import '../widgets/checkout_payment_card.dart';
import '../widgets/contact_picker_bottom_sheet.dart';
import '../widgets/delivery_info_section.dart';
import '../widgets/checkout_approver_content.dart';
import '../widgets/checkout_order_summary.dart';
import '../widgets/checkout_payment_info_section.dart';
import '../widgets/checkout_direct_payment_mode_panel.dart';
import '../widgets/region_picker_bottom_sheet.dart';
import '../widgets/searchable_store_bottom_sheet.dart';
import '../../logic/checkout_performance_reporter.dart';
import '../../../quotation/data/quotation_model.dart';
import '../../../quotation/logic/quotation_list_provider.dart';
import '../../../pricelist/logic/product_provider.dart';
import '../../../cart/logic/cart_item_price_refresh.dart';
import '../../../history/data/models/order_history.dart';
import '../../../history/logic/edit_order_context_provider.dart';
import '../../../history/presentation/order_detail_route_args.dart';
import '../../../indirect/logic/indirect_session_provider.dart';
import '../../data/models/approver_model.dart';
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
      _sessionLineItems ?? ref.read(cartProvider);

  double _effectiveTotal(WidgetRef ref) {
    final items = _effectiveCartItems(ref);
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Tanggal SP (`order_date`): default hari ini; boleh mundur dalam bulan berjalan.
  DateTime _orderDate = OrderLetterDateUtils.today();
  DateTime? _requestDate;

  /// Per index baris checkout: `true` = bawa sendiri (take away).
  List<bool> _lineTakeAway = [];

  // ── Payment (multi-payment) ─────────────────────────────────────
  bool _isLunas = true;
  /// Direct (S1): default manual form; user may opt into Paper.id.
  bool _directUsePaperPayment = false;
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
  bool _showReceiverBackupPhone = false;

  /// True jika field nama/HP pelanggan sedang berisi data hasil pilih dari
  /// [ContactPickerBottomSheet] (buku kontak server, `/address_books`) —
  /// dipakai untuk auto-clear indikator saat user mengedit manual lagi.
  bool _isFromContactBook = false;

  /// Guard sinkron untuk mencegah double-tap pada tombol "Buat Surat Pesanan".
  /// Diset true sebelum submitOrder dipanggil, dikosongkan saat overlay tutup.
  bool _submitInFlight = false;

  /// Edit mode: pastikan prefill approver dari OrderHistory hanya jalan sekali
  /// setelah daftar approver selesai di-fetch.
  bool _didPrefillApproversForEdit = false;

  /// Edit mode: pastikan amount pembayaran kekurangan hanya di-prefill sekali,
  /// supaya perubahan input user tidak ditimpa.
  bool _didPrefillShortageAmount = false;
  final _takeAway = BonusTakeAwayState();

  double _grandTotal = 0;

  /// Salinan baris checkout dari penawaran (bisa di-refresh harga tanpa mengubah route).
  List<CartItem>? _sessionLineItems;

  bool _priceRefreshBusy = false;

  // ── Customer ───────────────────────────────────────────────────
  final _customerNameCtrl = TextEditingController();
  final _customerEmailCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerPhone2Ctrl = TextEditingController();
  final _customerAddressLine1Ctrl = TextEditingController();
  final _customerAddressLine2Ctrl = TextEditingController();
  final _customerAddressLine3Ctrl = TextEditingController();
  bool _showCustomerAddressLine3 = false;

  // ── Region ─────────────────────────────────────────────────────
  String? _selectedProvinsi;
  String? _selectedKota;
  String? _selectedKecamatan;
  String? _selectedKelurahan;
  String? _selectedKodepos;

  // ── Receiver mode (indirect only) ──────────────────────────────
  /// True = pilih dari daftar cabang/gudang (store API); False = isi manual.
  bool _isReceiverBranchMode = true;
  StoreModel? _selectedReceiverStore;

  // ── Shipping ───────────────────────────────────────────────────
  final _shippingNameCtrl = TextEditingController();
  final _shippingPhoneCtrl = TextEditingController();
  final _shippingPhone2Ctrl = TextEditingController();
  final _shippingAddressLine1Ctrl = TextEditingController();
  final _shippingAddressLine2Ctrl = TextEditingController();
  final _shippingAddressLine3Ctrl = TextEditingController();
  bool _showShippingAddressLine3 = false;
  String? _shippingProvinsi;
  String? _shippingKota;
  String? _shippingKecamatan;
  String? _shippingKelurahan;
  String? _shippingKodepos;

  /// Indirect + alamat penerima beda.
  final _shippingEmailCtrl = TextEditingController();

  // ── Notes ──────────────────────────────────────────────────────
  final _notesController = TextEditingController();
  final _scCodeCtrl = TextEditingController();

  /// Indirect: No. PO untuk field `no_po` pada POST `/order_letters`.
  final _noPoCtrl = TextEditingController();

  String get _customerAddressCombined => CheckoutAddressLines.join(
        _customerAddressLine1Ctrl.text,
        _customerAddressLine2Ctrl.text,
        _customerAddressLine3Ctrl.text,
      );

  String get _shippingAddressCombined => CheckoutAddressLines.join(
        _shippingAddressLine1Ctrl.text,
        _shippingAddressLine2Ctrl.text,
        _shippingAddressLine3Ctrl.text,
      );

  String get _customerRegionText {
    final parts = [
      if ((_selectedKelurahan ?? '').trim().isNotEmpty)
        _selectedKelurahan!.trim(),
      if ((_selectedKecamatan ?? '').trim().isNotEmpty)
        'Kec. ${_selectedKecamatan!.trim()}',
      if ((_selectedKota ?? '').trim().isNotEmpty) _selectedKota!.trim(),
      if ((_selectedProvinsi ?? '').trim().isNotEmpty)
        _selectedProvinsi!.trim(),
      if ((_selectedKodepos ?? '').trim().isNotEmpty)
        _selectedKodepos!.trim(),
    ];
    return parts.join(', ');
  }

  String get _shippingRegionText {
    final parts = [
      if ((_shippingKelurahan ?? '').trim().isNotEmpty)
        _shippingKelurahan!.trim(),
      if ((_shippingKecamatan ?? '').trim().isNotEmpty)
        'Kec. ${_shippingKecamatan!.trim()}',
      if ((_shippingKota ?? '').trim().isNotEmpty) _shippingKota!.trim(),
      if ((_shippingProvinsi ?? '').trim().isNotEmpty)
        _shippingProvinsi!.trim(),
      if ((_shippingKodepos ?? '').trim().isNotEmpty)
        _shippingKodepos!.trim(),
    ];
    return parts.join(', ');
  }

  void _applyCustomerAddressLines(String raw) {
    final split = CheckoutAddressLines.split(raw);
    _customerAddressLine1Ctrl.text = split.line1;
    _customerAddressLine2Ctrl.text = split.line2;
    _customerAddressLine3Ctrl.text = split.line3;
    _showCustomerAddressLine3 = split.line3.isNotEmpty;
  }

  void _applyShippingAddressLines(String raw) {
    final split = CheckoutAddressLines.split(raw);
    _shippingAddressLine1Ctrl.text = split.line1;
    _shippingAddressLine2Ctrl.text = split.line2;
    _shippingAddressLine3Ctrl.text = split.line3;
    _showShippingAddressLine3 = split.line3.isNotEmpty;
  }

  static String _priceFmt(num value) => AppFormatters.currencyIdr(value);

  @override
  void initState() {
    super.initState();
    if (widget.selectedCartItems != null) {
      _sessionLineItems = List<CartItem>.from(widget.selectedCartItems!);
    }
    _payments.add(PaymentEntry());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncQuotationFieldsForIndirectIfNeeded();
      final notifier = ref.read(checkoutProvider.notifier);
      notifier.fetchApprovers();
      notifier.fetchAttendanceWorkPlace();
      AppAnalyticsService.logBeginCheckout(value: _effectiveTotal(ref));
      _prefillIndirectSalesCodeFromAuthIfEmpty();
      _prefillIndirectCheckoutFromAssignedStore();
      _prefillEditOrderPostageIfNeeded();
    });
    _updatePaymentAmountUI();
    _postageCtrl.addListener(() {
      setState(() {});
      if (!_isMultiPayment && _isLunas) _updatePaymentAmountUI();
    });
    _prefillFromQuotation();
  }

  /// Indirect: email di field pelanggan sering salah tempat pada draft lama —
  /// kosongkan; jika kirim ke alamat lain, pindahkan ke email penerima.
  void _syncQuotationFieldsForIndirectIfNeeded() {
    if (!mounted) return;
    final indirect = _effectiveCartItems(ref).any((e) => e.isIndirectSale);
    if (!indirect) return;

    final email = _customerEmailCtrl.text.trim();
    if (!_isShippingSameAsCustomer && email.isNotEmpty) {
      _shippingEmailCtrl.text = email;
    }
    _customerEmailCtrl.clear();
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
    _applyCustomerAddressLines(q.customerAddress);

    // ── Region ──
    if (q.regionProvinsi.isNotEmpty) _selectedProvinsi = q.regionProvinsi;
    if (q.regionKota.isNotEmpty) _selectedKota = q.regionKota;
    if (q.regionKecamatan.isNotEmpty) _selectedKecamatan = q.regionKecamatan;

    // ── Shipping ──
    _isShippingSameAsCustomer = q.isShippingSameAsCustomer;
    if (!q.isShippingSameAsCustomer) {
      _shippingNameCtrl.text = q.shippingName;
      _shippingPhoneCtrl.text = q.shippingPhone;
      if (q.shippingPhone2.isNotEmpty) {
        _shippingPhone2Ctrl.text = q.shippingPhone2;
        _showReceiverBackupPhone = true;
      }
      _applyShippingAddressLines(q.shippingAddress);
      if (q.shippingRegionProvinsi.isNotEmpty) {
        _shippingProvinsi = q.shippingRegionProvinsi;
      }
      if (q.shippingRegionKota.isNotEmpty) {
        _shippingKota = q.shippingRegionKota;
      }
      if (q.shippingRegionKecamatan.isNotEmpty) {
        _shippingKecamatan = q.shippingRegionKecamatan;
      }
    }

    // ── Delivery ──
    final rawOrderDate = q.orderDate;
    if (rawOrderDate != null && rawOrderDate.isNotEmpty) {
      final parsed = DateTime.tryParse(rawOrderDate);
      if (parsed != null) {
        _orderDate = OrderLetterDateUtils.clampToValidOrderLetterDate(parsed);
      }
    }
    final rawDate = q.requestDate;
    if (rawDate != null) {
      _requestDate = DateTime.tryParse(rawDate);
    }
    final qlen = q.items.length;
    _lineTakeAway = q.lineTakeAway.length == qlen
        ? List<bool>.from(q.lineTakeAway)
        : List<bool>.filled(qlen, q.isTakeAway);
    _shippingEmailCtrl.text = q.receiverEmail;
    _noPoCtrl.text = q.indirectNoPo;
    _takeAway.applyPersistedSnapshot(
      checkedKeys: q.bonusTakeAwayCheckedKeys,
      qtyByKey: q.bonusTakeAwayQtyByKey,
    );
    if (q.postage.isNotEmpty) _postageCtrl.text = q.postage;
    if (q.scCode.isNotEmpty) {
      _scCodeCtrl.text = ThousandsSeparatorInputFormatter.digitsOnly(q.scCode);
    }

    // ── Notes ──
    _notesController.text = q.notes;
  }

  /// SC Code order mengikuti sales code akun (`address_number`) jika masih kosong
  /// (mis. setelah draft kuotasi tanpa SC).
  /// Edit mode: salin ongkir dari order lama ke [_postageCtrl] agar
  /// `_totalAkhir` & perhitungan selisih konsisten dengan backend (yang
  /// memakai `editOrder.postage` saat patch totals).
  void _prefillEditOrderPostageIfNeeded() {
    if (!mounted) return;
    final editOrder = ref.read(editOrderContextProvider);
    if (editOrder == null) return;
    if (editOrder.postage <= 0) return;
    if (_postageCtrl.text.trim().isNotEmpty) return;
    _postageCtrl.text = editOrder.postage.toStringAsFixed(0);
  }

  void _prefillIndirectSalesCodeFromAuthIfEmpty() {
    if (!mounted) return;
    final items = _effectiveCartItems(ref);
    if (!items.any((e) => e.isIndirectSale)) return;
    if (_scCodeCtrl.text.trim().isNotEmpty) return;
    final raw = ref.read(authProvider).addressNumber?.trim();
    if (raw == null || raw.isEmpty || raw.toLowerCase() == 'null') return;
    final digits = ThousandsSeparatorInputFormatter.digitsOnly(raw);
    if (digits.isEmpty) return;
    setState(() => _scCodeCtrl.text = digits);
  }

  /// Isi nama & alamat toko dari [indirectSessionProvider.selectedStore]
  /// (`alpha_name` + `address` dari API `address_number_by_sales_code`).
  /// Fallback: snapshot keranjang indirect. `/all_stores` tidak dipakai di sini
  /// (master cabang/gudang saja).
  void _prefillIndirectCheckoutFromAssignedStore() {
    if (!mounted || widget.restoredQuotation != null) return;
    final items = _effectiveCartItems(ref);
    final indirect = items.where((e) => e.isIndirectSale).toList();
    if (indirect.isEmpty) return;

    final first = indirect.first;
    final sessionStore = ref.read(indirectSessionProvider).selectedStore;

    final nameFromSession = sessionStore?.alphaName.trim() ?? '';
    final addrFromSession = sessionStore?.address.trim() ?? '';
    final nameFromCart = first.indirectStoreAlphaName.trim();
    final addrFromCart = first.indirectStoreAddress.trim();

    var setShippingSame = false;
    setState(() {
      if (_customerNameCtrl.text.trim().isEmpty) {
        final name =
            nameFromSession.isNotEmpty ? nameFromSession : nameFromCart;
        if (name.isNotEmpty) {
          _customerNameCtrl.text = name;
        }
      }
      if (_customerAddressCombined.isEmpty) {
        final addr =
            addrFromSession.isNotEmpty ? addrFromSession : addrFromCart;
        if (addr.isNotEmpty) {
          _applyCustomerAddressLines(addr);
          setShippingSame = true;
        }
      }
      if (setShippingSame) _isShippingSameAsCustomer = true;
    });

    _prefillIndirectSalesCodeFromAuthIfEmpty();
  }

  /// DP minimal 30% dihitung dari Total Akhir (subtotal + ongkir), bukan
  /// subtotal barang saja — supaya konsisten dengan `extended_amount` yang
  /// benar-benar ditagih ke customer (lihat PDF invoice & order_letters).
  double get _minimumDp => _totalAkhir * 0.3;

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
      final editOrder = ref.read(editOrderContextProvider);
      if (editOrder != null) {
        // Edit mode:
        // - Ada kekurangan → prefill dengan sisa tagihan.
        // - Lunas/overpaid → kosongkan field (pembayaran opsional).
        final s = _computeEditSelisih(editOrder);
        if (s.isShortage) {
          _payments.first.amountCtrl.text =
              AppFormatters.currencyIdrNoSymbol(s.sisaTagihan);
        } else {
          _payments.first.amountCtrl.clear();
        }
      } else {
        // Non-edit: prefill dengan total akhir seperti biasa.
        _payments.first.amountCtrl.text =
            AppFormatters.currencyIdrNoSymbol(_totalAkhir);
      }
    }
  }

  /// Nomor untuk field `phone` di header SP (dan PDF kolom "Telepon" indirect):
  /// selalu **kontak penerima** — ke toko jika kirim ke alamat toko, atau HP penerima
  /// jika alamat berbeda. Jangan disamakan dengan pola direct (HP pemesan di kolom yang sama).
  String _indirectContactPhoneForOrder() => _isShippingSameAsCustomer
      ? _customerPhoneCtrl.text.trim()
      : _shippingPhoneCtrl.text.trim();

  /// Email untuk field `email` di header SP (dan PDF kolom "Email" indirect):
  /// sama seperti [_indirectContactPhoneForOrder] — kontak **penerima** (toko atau penerima lain).
  String _indirectContactEmailForOrder() => _isShippingSameAsCustomer
      ? _customerEmailCtrl.text.trim()
      : _shippingEmailCtrl.text.trim();

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerPhone2Ctrl.dispose();
    _customerAddressLine1Ctrl.dispose();
    _customerAddressLine2Ctrl.dispose();
    _customerAddressLine3Ctrl.dispose();
    _shippingNameCtrl.dispose();
    _shippingPhoneCtrl.dispose();
    _shippingPhone2Ctrl.dispose();
    _shippingAddressLine1Ctrl.dispose();
    _shippingAddressLine2Ctrl.dispose();
    _shippingAddressLine3Ctrl.dispose();
    _shippingEmailCtrl.dispose();
    _notesController.dispose();
    _scCodeCtrl.dispose();
    _noPoCtrl.dispose();
    for (final p in _payments) {
      p.dispose();
    }
    _postageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _lineTakeAwayAt(int i) =>
      i >= 0 && i < _lineTakeAway.length ? _lineTakeAway[i] : false;

  /// Samakan panjang [_lineTakeAway] dengan jumlah baris checkout (isi baru = `false`, kelebihan dipotong).
  ///
  /// Tanpa `setState`: dipanggil di awal [build] dan sebelum validasi/submit/simpan draft supaya
  /// `_headerAllLinesTakeAway`, `_anyLineNeedsFactoryDelivery`, dan payload tidak pernah membaca
  /// mismatch satu frame seperti sebelumnya (post-frame sync).
  void _syncLineTakeAwayToItemCount(int itemCount) {
    if (itemCount < 0) return;
    if (_lineTakeAway.length == itemCount) return;
    if (_lineTakeAway.length < itemCount) {
      _lineTakeAway = [
        ..._lineTakeAway,
        ...List.filled(itemCount - _lineTakeAway.length, false),
      ];
    } else {
      _lineTakeAway = _lineTakeAway.sublist(0, itemCount);
    }
  }

  bool _anyLineNeedsFactoryDelivery(List<CartItem> items) {
    if (items.isEmpty) return false;
    if (_lineTakeAway.length != items.length) return true;
    return _lineTakeAway.any((v) => !v);
  }

  bool _headerAllLinesTakeAway(List<CartItem> items) {
    if (items.isEmpty || _lineTakeAway.length != items.length) return false;
    return _lineTakeAway.every((v) => v);
  }

  void _setLineTakeAway(int index, bool bawaSendiri) {
    setState(() {
      while (_lineTakeAway.length <= index) {
        _lineTakeAway.add(false);
      }
      _lineTakeAway[index] = bawaSendiri;
    });
  }

  // ─────────────────────────── Build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final buildSw = Stopwatch()..start();
    final List<CartItem> cartItems =
        _sessionLineItems ?? ref.watch(cartProvider);
    _syncLineTakeAwayToItemCount(cartItems.length);
    final totalAmount = _effectiveTotal(ref);
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
      CheckoutPerformanceReporter.reportIfNeeded(
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
        _submitInFlight = false;
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }
      if (next.submitSuccess && next.successNoSp != null) {
        final successNoSp = next.successNoSp!;
        final paperInvoiceUrl = next.successPaperInvoiceUrl;
        final expectPaper = next.successExpectPaperPayment;
        final successOrderLetterId = next.successOrderLetterId;
        final successPaperAmount = next.successPaperPaymentAmount;
        final successPaperCreator = next.successPaperCreatorId;
        ref.read(checkoutProvider.notifier).clearSubmitResult();

        final editCtx = ref.read(editOrderContextProvider);
        if (editCtx != null) {
          // Edit mode: kembali ke order detail dengan data segar.
          ref.read(editOrderContextProvider.notifier).state = null;
          AppFeedback.show(
            context,
            message:
                'Perubahan item pesanan SP $successNoSp berhasil diperbarui!',
            type: AppFeedbackType.success,
            floating: true,
            duration: const Duration(seconds: 3),
          );
          if (context.mounted) {
            // Pop ke order detail sebelumnya (provider sudah di-invalidate).
            // Hindari context.go yang menghapus seluruh stack.
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                '/order_detail',
                extra: OrderDetailRouteArgs(order: editCtx),
              );
            }
          }
          return;
        }

        // Normal mode: mark quotation converted + navigate to /success
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
          message: 'Surat Pesanan $successNoSp Berhasil Dibuat!',
          type: AppFeedbackType.success,
          floating: true,
          duration: const Duration(seconds: 3),
        );
        context.pushReplacement(
          '/success',
          extra: OrderSuccessRouteArgs(
            noSp: successNoSp,
            paperInvoiceUrl: paperInvoiceUrl,
            expectPaperPayment: expectPaper,
            orderLetterId: successOrderLetterId,
            paperPaymentAmount: successPaperAmount,
            paperCreatorId: successPaperCreator,
          ),
        );
      }
      final submitError = next.submitError;
      if (submitError != null && prev?.submitError != submitError) {
        _showSubmitErrorDialog(submitError);
      }
    });

    if (cartItems.isEmpty) {
      return const CheckoutEmptyState();
    }

    final editOrder = ref.watch(editOrderContextProvider);
    final isEditMode = editOrder != null;

    // Edit mode: jika order asli adalah SO (indirect) tapi item belum memiliki
    // indirectStoreAddressNumber yang valid, tetap anggap indirect.
    final isIndirectCheckout = cartItems.any((e) => e.isIndirectSale) ||
        (isEditMode && (editOrder.channel?.trim().toUpperCase() ?? '') == 'SO');

    final checkoutChannel = CheckoutChannelResolver.resolve(
      divisions: ref.watch(profileProvider).valueOrNull?.divisions ?? const [],
      userAddressNumber: ref.watch(authProvider).addressNumber,
    );
    // MM: always manual form. Direct S1: section shown; default manual, opt-in Paper.
    // TODO(paper-shortage): edit Direct shortage — Paper vs legacy form TBD.
    final showPaymentSection = !isIndirectCheckout &&
        CheckoutChannelResolver.showsCheckoutPaymentSection(checkoutChannel);
    final canOptInPaper = !isIndirectCheckout &&
        CheckoutChannelResolver.canOptInPaperIdPayment(checkoutChannel);
    final usePaperMode = canOptInPaper && _directUsePaperPayment;
    // Edit mode: begitu daftar approver selesai fetch, prefill SPV/Manager dari
    // order yang sedang di-edit supaya user tidak perlu memilih ulang.
    ref.listen<List<Approver>>(
      checkoutProvider.select((s) => s.approvers),
      (_, approvers) {
        if (!isEditMode || _didPrefillApproversForEdit) return;
        if (approvers.isEmpty) return;
        _prefillApproversFromEditOrder(editOrder, approvers);
        _didPrefillApproversForEdit = true;
      },
    );

    // Edit mode + shortage: isi amount pembayaran pertama dengan nominal
    // kekurangan — hanya sekali, agar user bebas mengubah jika perlu.
    // TODO(paper-shortage): Direct shortage via Paper — pending backend.
    if (isEditMode && !_didPrefillShortageAmount) {
      if (showPaymentSection && !usePaperMode) {
        final summary = _computeEditSelisih(editOrder);
        if (summary.isShortage) {
          _didPrefillShortageAmount = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_payments.isEmpty) return;
            _payments.first.amountCtrl.text =
                AppFormatters.currencyIdrNoSymbol(summary.sisaTagihan);
            setState(() {});
          });
        }
      }
    }

    final checkoutState = ref.watch(
      checkoutProvider.select(
        (s) => (
          retryDetails: s.retryDetails,
          retryDiscountDetails: s.retryDiscountDetails,
          retryNoSp: s.retryNoSp,
          isSubmitting: s.isSubmitting
        ),
      ),
    );

    return GoRouterPopScope(
      fallbackLocation: '/',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          // iOS: biarkan leading bawaan + swipe-back [CupertinoPage] (tanpa override).
          leading: isIOS
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Kembali',
                  onPressed: () => GoRouterPopScope.handlePop(
                    context,
                    fallbackLocation: '/',
                  ),
                ),
          title: Text(isEditMode ? 'Edit Item Pesanan' : 'Buat Surat Pesanan'),
          elevation: 0,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          actions: [
            IconButton(
              tooltip: 'Perbarui harga dari server',
              icon: _priceRefreshBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              onPressed: _priceRefreshBusy
                  ? null
                  : () => unawaited(_refreshPricesFromServer(context)),
            ),
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
                  Consumer(
                    builder: (context, ref, _) {
                      final draftName = ref.watch(
                        activeDraftProvider.select((d) => d?.customerName),
                      );
                      if (draftName == null) return const SizedBox.shrink();
                      return ActiveDraftBanner(
                        name: draftName,
                        onClear: () {
                          ref.read(activeDraftProvider.notifier).state = null;
                        },
                      );
                    },
                  ),

                  // ── Edit Mode Banner ─────────────────────────────
                  if (isEditMode) ...[
                    _buildEditModeBanner(editOrder),
                    const SizedBox(height: 16),
                  ],

                  // ── Card 1: Customer Info + Shipping ──────────────
                  // (Di edit mode, data pelanggan TIDAK diubah — card disembunyikan.)
                  if (!isEditMode)
                    Consumer(
                      builder: (context, ref, _) {
                        final storeAsync = ref.watch(storeListProvider);
                        final allStores = storeAsync.valueOrNull ?? const [];
                        final isRefreshingStores = storeAsync.isLoading;
                        return KeyedSubtree(
                          key: _customerSectionKey,
                          child: CheckoutCustomerShippingCard(
                            customerSectionTitle: isIndirectCheckout
                                ? 'Informasi Toko'
                                : 'Informasi Pelanggan',
                            customerSectionSubtitle:
                                isIndirectCheckout ? null : null,
                            shippingSectionTitle: isIndirectCheckout
                                ? 'Alamat toko & pengiriman'
                                : 'Alamat & Pengiriman',
                            sameAsCustomerLabel: isIndirectCheckout
                                ? 'Kirim ke alamat toko di atas'
                                : 'Kirim ke alamat pelanggan di atas',
                            receiverBlockTitle: isIndirectCheckout
                                ? 'Penerima / gudang / cabang lain'
                                : 'Informasi Penerima (Dropship / Lokasi Lain)',
                            storeContactOptional: false,
                            indirectStoreOnly: isIndirectCheckout,
                            customerNameFieldLabel: isIndirectCheckout
                                ? 'Nama Toko *'
                                : 'Nama Pelanggan *',
                            useStoreAddressLabels: isIndirectCheckout,
                            hideCustomerRegionPicker: isIndirectCheckout,
                            receiverContactOptional: isIndirectCheckout,
                            showIndirectAlternateReceiverEmail:
                                isIndirectCheckout &&
                                    !_isShippingSameAsCustomer,
                            shippingEmailCtrl: _shippingEmailCtrl,
                            customerNameCtrl: _customerNameCtrl,
                            customerEmailCtrl: _customerEmailCtrl,
                            customerPhoneCtrl: _customerPhoneCtrl,
                            customerPhone2Ctrl: _customerPhone2Ctrl,
                            showBackupPhone: _showBackupPhone,
                            onToggleBackupPhone: () =>
                                setState(() => _showBackupPhone = true),
                            isFromContactBook: _isFromContactBook,
                            onContactFieldCleared: () => setState(() {
                              _isFromContactBook = false;
                            }),
                            onPickContact: _pickContact,
                            customerProvinsi: _selectedProvinsi,
                            customerKota: _selectedKota,
                            customerKecamatan: _selectedKecamatan,
                            customerKelurahan: _selectedKelurahan,
                            customerKodepos: _selectedKodepos,
                            onPickCustomerRegion: () =>
                                _pickRegion(isShipping: false),
                            customerAddressLine1Ctrl: _customerAddressLine1Ctrl,
                            customerAddressLine2Ctrl: _customerAddressLine2Ctrl,
                            customerAddressLine3Ctrl: _customerAddressLine3Ctrl,
                            showCustomerAddressLine3: _showCustomerAddressLine3,
                            onShowCustomerAddressLine3: () => setState(
                                () => _showCustomerAddressLine3 = true),
                            isShippingSameAsCustomer: _isShippingSameAsCustomer,
                            onToggleSameAddress: (v) =>
                                setState(() => _isShippingSameAsCustomer = v),
                            shippingNameCtrl: _shippingNameCtrl,
                            shippingPhoneCtrl: _shippingPhoneCtrl,
                            shippingPhone2Ctrl: _shippingPhone2Ctrl,
                            showReceiverBackupPhone: _showReceiverBackupPhone,
                            onToggleReceiverBackupPhone: () =>
                                setState(() => _showReceiverBackupPhone = true),
                            shippingProvinsi: _shippingProvinsi,
                            shippingKota: _shippingKota,
                            shippingKecamatan: _shippingKecamatan,
                            shippingKelurahan: _shippingKelurahan,
                            shippingKodepos: _shippingKodepos,
                            onPickShippingRegion: () =>
                                _pickRegion(isShipping: true),
                            shippingAddressLine1Ctrl: _shippingAddressLine1Ctrl,
                            shippingAddressLine2Ctrl: _shippingAddressLine2Ctrl,
                            shippingAddressLine3Ctrl: _shippingAddressLine3Ctrl,
                            showShippingAddressLine3: _showShippingAddressLine3,
                            onShowShippingAddressLine3: () => setState(
                                () => _showShippingAddressLine3 = true),
                            isReceiverBranchMode: isIndirectCheckout
                                ? _isReceiverBranchMode
                                : false,
                            onToggleReceiverBranchMode: isIndirectCheckout
                                ? (v) => setState(() {
                                      _isReceiverBranchMode = v;
                                      _selectedReceiverStore = null;
                                      _isFromReceiverContactBook = false;
                                      _shippingNameCtrl.clear();
                                      _shippingPhoneCtrl.clear();
                                      _shippingPhone2Ctrl.clear();
                                      _shippingAddressLine1Ctrl.clear();
                                      _shippingAddressLine2Ctrl.clear();
                                      _shippingAddressLine3Ctrl.clear();
                                      _showShippingAddressLine3 = false;
                                      _shippingProvinsi = null;
                                      _shippingKota = null;
                                      _shippingKecamatan = null;
                                      _shippingKelurahan = null;
                                      _shippingKodepos = null;
                                    })
                                : null,
                            availableStores: allStores,
                            selectedReceiverStore: _selectedReceiverStore,
                            onReceiverStorePicked: isIndirectCheckout
                                ? _onReceiverStorePicked
                                : null,
                            onPickReceiverContact: isIndirectCheckout
                                ? _pickReceiverContact
                                : null,
                            isFromReceiverContactBook:
                                _isFromReceiverContactBook,
                            onRefreshStores: isIndirectCheckout
                                ? () => ref
                                    .read(storeListProvider.notifier)
                                    .refreshFromNetwork()
                                : null,
                            isRefreshingStores:
                                isIndirectCheckout ? isRefreshingStores : false,
                          ),
                        );
                      },
                    ),

                  if (!isEditMode) const SizedBox(height: 16),

                  // ── Card 2: Delivery Info ─────────────────────────
                  // (Di edit mode, info pengiriman TIDAK diubah — card disembunyikan.)
                  if (!isEditMode)
                    Consumer(
                      builder: (context, ref, _) {
                        final storeData = ref.watch(
                          checkoutProvider.select((s) => (
                                isLoading: s.isLoadingWorkPlace,
                                attendanceName: s.attendanceWorkPlaceName,
                                useAttendance: s.useAttendanceStore,
                                selectedStore: s.selectedStore,
                              )),
                        );
                        return _buildSectionCard(
                          key: _deliverySectionKey,
                          title: 'Informasi Pengiriman',
                          child: DeliveryInfoSection(
                            isLoadingWorkPlace: storeData.isLoading,
                            attendanceWorkPlaceName: storeData.attendanceName,
                            useAttendanceStore: storeData.useAttendance,
                            onToggleUseAttendance: (v) => ref
                                .read(checkoutProvider.notifier)
                                .toggleUseAttendanceStore(v),
                            selectedStore: storeData.selectedStore,
                            onPickStore: () => _pickStore(context),
                            orderDate: _orderDate,
                            onPickOrderDate: _pickOrderDate,
                            requestDate: _requestDate,
                            onPickRequestDate: _pickRequestDate,
                            anyLineNeedsFactoryDelivery:
                                _anyLineNeedsFactoryDelivery(cartItems),
                            postageCtrl: _postageCtrl,
                            notesController: _notesController,
                            scCodeCtrl: _scCodeCtrl,
                            showIndirectNoPo: isIndirectCheckout,
                            showDirectNoPo: !isIndirectCheckout,
                            noPoCtrl: _noPoCtrl,
                          ),
                        );
                      },
                    ),

                  // Gap antara delivery card dan apapun yang ada di bawahnya.
                  if (!isEditMode) const SizedBox(height: 16),

                  // ── Card 3: Approval ──────────────────────────────
                  // Direct: hanya jika SPV/Manager wajib.
                  // Indirect: selalu tampil (tombol + untuk tambah ASM/RSM manual).
                  if (isIndirectCheckout ||
                      _requiresSpvApproval(cartItems) ||
                      _requiresManagerApproval(cartItems)) ...[
                    Consumer(
                      builder: (context, ref, _) {
                        final approvalData = ref.watch(
                          checkoutProvider.select(
                            (s) => (
                              s.isLoadingApprovers,
                              s.approversError,
                              s.approversErrorTitle,
                              s.approvers,
                              s.selectedSpv,
                              s.selectedManager,
                            ),
                          ),
                        );
                        final manualAsm =
                            ref.watch(manualAsmRequestedProvider);
                        final manualRsm =
                            ref.watch(manualRsmRequestedProvider);
                        return CheckoutApprovalCard(
                          key: _approvalSectionKey,
                          isLoading: approvalData.$1,
                          hasError: approvalData.$2 != null &&
                              approvalData.$4.isEmpty,
                          errorTitle: approvalData.$3,
                          errorMessage: approvalData.$2,
                          onRetry: () => ref
                              .read(checkoutProvider.notifier)
                              .fetchApprovers(),
                          child: CheckoutApproverContent(
                            approvers: approvalData.$4,
                            selectedSpv: approvalData.$5,
                            selectedManager: approvalData.$6,
                            requiresSpv: _requiresSpvApproval(cartItems),
                            requiresManager:
                                _requiresManagerApproval(cartItems),
                            manualAsmRequested: manualAsm,
                            manualRsmRequested: manualRsm,
                            isIndirectCheckout: isIndirectCheckout,
                            hasBonusCustomizedItem:
                                _hasBonusCustomizedItem(cartItems),
                            hasCustomSizeItem:
                                cartItems.any((e) => e.isCustomSize),
                            hasFocVoucherItem: _hasFocVoucherItem(cartItems),
                            isCustomerBaru: isIndirectCheckout &&
                                (_isCustomerBaruShippingForApproval() ||
                                    cartItems.any((e) => e.isNewCustomerStore)),
                            isKlausManagerAutoAssigned: ref
                                .read(checkoutProvider.notifier)
                                .isKlausRuleActive,
                            onSpvChanged: (v) => ref
                                .read(checkoutProvider.notifier)
                                .selectSpv(v),
                            onManagerChanged: (v) => ref
                                .read(checkoutProvider.notifier)
                                .selectManager(v),
                            onManualLevelAdded: (level) {
                              switch (level) {
                                case ManualApproverLevel.asm:
                                  ref
                                      .read(
                                          manualAsmRequestedProvider.notifier)
                                      .state = true;
                                case ManualApproverLevel.rsm:
                                  ref
                                      .read(
                                          manualRsmRequestedProvider.notifier)
                                      .state = true;
                              }
                            },
                            onRemoveManualAsm: () {
                              ref
                                  .read(manualAsmRequestedProvider.notifier)
                                  .state = false;
                              ref
                                  .read(checkoutProvider.notifier)
                                  .clearSelectedSpv();
                            },
                            onRemoveManualRsm: () {
                              ref
                                  .read(manualRsmRequestedProvider.notifier)
                                  .state = false;
                              ref
                                  .read(checkoutProvider.notifier)
                                  .clearSelectedManager();
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Card 4a: Selisih Total (edit mode + direct only) ─
                  if (isEditMode && !isIndirectCheckout) ...[
                    _buildSelisihCard(editOrder),
                    const SizedBox(height: 16),
                  ],

                  // ── Card 4b: Item Sebelumnya (edit mode only) ─────
                  if (isEditMode) ...[
                    _buildPreviousItemsCard(editOrder),
                    const SizedBox(height: 16),
                  ],

                  // ── Card 4: Order Summary ─────────────────────────
                  _buildSectionCard(
                    title: isEditMode
                        ? 'Ringkasan Pesanan Baru'
                        : 'Ringkasan Pesanan',
                    child: CheckoutOrderSummary(
                      cartItems: cartItems,
                      priceFmt: _priceFmt,
                      isBonusTakeAwayChecked: _isBonusTakeAwayChecked,
                      currentTakeAwayQty: _currentTakeAwayQty,
                      onTakeAwayToggled: _toggleBonusTakeAway,
                      onTakeAwayQtyChanged: _setTakeAwayQty,
                      lineTakeAway: _lineTakeAwayAt,
                      onLineTakeAwayChanged: _setLineTakeAway,
                    ),
                  ),

                  // ── Card 5: Payment Info ──────────────────────────
                  // MM                    : selalu tampil (non-edit).
                  // Direct (S1)           : tampil; default manual, opt-in Paper.
                  // MM/Direct edit + shortage : tampil ("Tambah Pembayaran").
                  // Indirect              : selalu disembunyikan.
                  // TODO(paper-shortage): Direct edit shortage path TBD w/ backend.
                  if (showPaymentSection &&
                      (!isEditMode ||
                          _computeEditSelisih(editOrder).isShortage)) ...[
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      key: _paymentSectionKey,
                      title: isEditMode
                          ? 'Tambah Pembayaran (Opsional)'
                          : 'Informasi Pembayaran',
                      trailing: (isEditMode || usePaperMode)
                          ? null
                          : _buildAddPaymentChip(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (canOptInPaper && !isEditMode) ...[
                            CheckoutDirectPaymentModePanel(
                              usePaper: usePaperMode,
                              onSelectPaper: () => setState(
                                () => _directUsePaperPayment = true,
                              ),
                              onSelectManual: () => setState(
                                () => _directUsePaperPayment = false,
                              ),
                            ),
                            if (!usePaperMode)
                              const SizedBox(height: 12),
                          ],
                          if (!usePaperMode)
                            CheckoutPaymentInfoSection(
                              paymentCount: _payments.length,
                              isMultiPayment: _isMultiPayment,
                              paymentCardBuilder: (_, i) =>
                                  _buildPaymentCard(i),
                              paymentSummary: _buildPaymentSummary(),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CheckoutBottomBar(
          totalFormatted: _priceFmt(_totalAkhir),
          showRetryBanner: checkoutState.retryDetails.isNotEmpty ||
              checkoutState.retryDiscountDetails.isNotEmpty,
          retryNoSp: checkoutState.retryNoSp,
          failedCount: checkoutState.retryDetails.isNotEmpty
              ? checkoutState.retryDetails.length
              : checkoutState.retryDiscountDetails.length,
          failedLabels: checkoutState.retryDetails.isNotEmpty
              ? checkoutState.retryDetails.map((e) => e.label).toList()
              : checkoutState.retryDiscountDetails
                  .map((e) => e.pending.label)
                  .toList(),
          isDiscountRetry: checkoutState.retryDetails.isEmpty &&
              checkoutState.retryDiscountDetails.isNotEmpty,
          onRetry: () => ref
              .read(checkoutProvider.notifier)
              .retryFailedDetails(selectedCartItems: widget.selectedCartItems),
          onSubmit: isEditMode
              ? () => _handleEditOrder(context, editOrder)
              : () => _handleCreateOrder(context),
          submitButtonEnabled: checkoutState.retryDetails.isEmpty &&
              checkoutState.retryDiscountDetails.isEmpty &&
              !checkoutState.isSubmitting,
          submitLabel: isEditMode ? 'Simpan Perubahan' : 'Buat Surat Pesanan',
        ),
      ),
    );
  }

  // ─────────────────────────── Helpers ──────────────────────────

  /// Edit mode: ambil SPV (level 2) dan Manager (level 3) dari
  /// order_letter_discounts yang lama, lalu cocokkan dengan daftar [approvers]
  /// agar dropdown sudah terisi otomatis.
  void _prefillApproversFromEditOrder(
    OrderHistory order,
    List<Approver> approvers,
  ) {
    String? level2IdStr;
    String? level3IdStr;
    for (final d in order.details) {
      for (final disc in d.discounts) {
        final lvl = disc.approverLevel.toLowerCase();
        final id = disc.approverId;
        if (id == null || id.isEmpty) continue;
        // Level 2: SPV (direct) / ASM (indirect).
        if (level2IdStr == null &&
            (lvl.startsWith('spv') || lvl.startsWith('asm'))) {
          level2IdStr = id;
        }
        // Level 3: Manager / RSM / GM.
        if (level3IdStr == null &&
            (lvl.startsWith('manager') ||
                lvl.startsWith('rsm') ||
                lvl.startsWith('gm'))) {
          level3IdStr = id;
        }
      }
    }

    final notifier = ref.read(checkoutProvider.notifier);
    Approver? findById(String? idStr) {
      if (idStr == null) return null;
      final id = int.tryParse(idStr);
      if (id == null) return null;
      for (final a in approvers) {
        if (a.id == id) return a;
      }
      return null;
    }

    final spv = findById(level2IdStr);
    final manager = findById(level3IdStr);
    if (spv != null) notifier.selectSpv(spv);
    if (manager != null) notifier.selectManager(manager);
  }

  bool _requiresManagerApproval(List<CartItem> cartItems) {
    if (ref.read(checkoutProvider.notifier).isKlausRuleActive) return true;
    if (cartItems.any((e) => e.isIndirectSale)) {
      return IndirectApprovalRules.requiresRsm(
        cartItems: cartItems,
        isKlausRuleActive: false,
      );
    }
    return cartItems.any(
      (item) => item.discount3 > 0 || item.isBonusCustomized,
    );
  }

  /// True jika shipping tujuan berbeda dari alamat customer ("Customer Baru")
  /// — dipakai untuk menentukan wajib-tidaknya persetujuan ASM (indirect).
  /// Lihat [IndirectApprovalRules.isCustomerBaruShipping] untuk alasan edit
  /// mode di-derive dari data order, bukan dari toggle UI.
  bool _isCustomerBaruShippingForApproval() {
    return IndirectApprovalRules.isCustomerBaruShipping(
      editOrder: ref.read(editOrderContextProvider),
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      isReceiverBranchMode: _isReceiverBranchMode,
    );
  }

  /// True jika cart memerlukan pemilihan ASM (indirect) / SPV (direct).
  ///
  /// Indirect — ASM wajib untuk: Customer Baru, toko new_customer, FOC,
  /// area Medan, ukuran custom. **Diskon tambahan (d1–d3) hanya ke RSM.**
  /// Direct: SPV selalu wajib.
  bool _requiresSpvApproval(List<CartItem> cartItems) {
    final isIndirect = cartItems.any((e) => e.isIndirectSale);
    if (isIndirect) {
      return IndirectApprovalRules.requiresAsm(
        isCustomerBaruShipping: _isCustomerBaruShippingForApproval(),
        hasNewCustomerStoreItem:
            IndirectApprovalRules.cartHasNewCustomerStore(cartItems),
        hasFocVoucherItem: IndirectApprovalRules.cartHasFocVoucher(cartItems),
        hasMedanPricelistItem:
            IndirectApprovalRules.cartHasMedanArea(cartItems),
        hasCustomSizeItem: IndirectApprovalRules.cartHasCustomSize(cartItems),
      );
    }
    return true;
  }

  bool _hasFocVoucherItem(List<CartItem> cartItems) =>
      cartItems.any((item) => item.isFocVoucherActive);

  /// True jika ada item di cart yang bonusnya diubah dari bundle default produk.
  /// Dipakai untuk menampilkan badge peringatan di approval section.
  bool _hasBonusCustomizedItem(List<CartItem> cartItems) {
    return cartItems.any((item) => item.isBonusCustomized);
  }

  Future<void> _pickOrderDate() async {
    final now = DateTime.now();
    final first = OrderLetterDateUtils.firstDayOfMonth(reference: now);
    final last = OrderLetterDateUtils.today(reference: now);
    final initial = OrderLetterDateUtils.clampToValidOrderLetterDate(
      _orderDate,
      reference: now,
    );
    final picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pilih Tanggal Surat Pesanan',
    );
    if (!mounted) return;
    if (picked != null) {
      setState(
        () => _orderDate = OrderLetterDateUtils.dateOnly(picked),
      );
    }
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
        setState(
            () => _payments[paymentIndex].receiptImage = File(picked.path));
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
        _shippingKelurahan = result.kelurahan;
        _shippingKodepos =
            result.kodepos.trim().isEmpty ? null : result.kodepos.trim();
      } else {
        _selectedProvinsi = result.provinsi;
        _selectedKota = result.kota;
        _selectedKecamatan = result.kecamatan;
        _selectedKelurahan = result.kelurahan;
        _selectedKodepos =
            result.kodepos.trim().isEmpty ? null : result.kodepos.trim();
      }
    });
  }

  Future<void> _pickStore(BuildContext context) async {
    final store = await SearchableStoreBottomSheet.show(context);
    if (!mounted || store == null) return;
    ref.read(checkoutProvider.notifier).updateStore(store);
  }

  /// Indirect receiver mode — state tambahan untuk contact book.
  bool _isFromReceiverContactBook = false;

  /// Indirect: saat user memilih toko sebagai penerima (mode cabang/gudang),
  /// auto-fill semua field penerima dari data toko yang dipilih.
  void _onReceiverStorePicked(StoreModel store) {
    setState(() {
      _selectedReceiverStore = store;
      _shippingNameCtrl.text = store.name;
      _shippingPhoneCtrl.text = store.phone;
      _applyShippingAddressLines(store.address);
      _shippingProvinsi =
          store.state.trim().isEmpty ? null : store.state.trim();
      _shippingKota = store.city.trim().isEmpty ? null : store.city.trim();
      _shippingKecamatan = store.area.trim().isEmpty ? null : store.area.trim();
    });
  }

  /// Loads the area-filtered contact list from the server address book
  /// (`/address_books`) and opens the picker sheet. Returns `null` if the
  /// user cancels, the area has no contacts, or the fetch fails.
  Future<AddressBookContact?> _showAddressBookPicker() async {
    List<AddressBookContact> contacts;
    try {
      contacts = await ref.read(addressBookContactsProvider.future);
    } catch (e, st) {
      Log.error(e, st, reason: 'Checkout: fetch address book contacts');
      if (!mounted) return null;
      AppFeedback.show(
        context,
        message: userFacingErrorMessage(e),
        type: AppFeedbackType.warning,
        floating: true,
      );
      return null;
    }
    if (!mounted) return null;

    return showModalBottomSheet<AddressBookContact>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ContactPickerBottomSheet(contacts: contacts),
    );
  }

  /// Pelanggan (direct) / toko (indirect): isi nama & HP dari buku kontak
  /// server. Endpoint ini hanya punya nama + HP — alamat/wilayah tetap diisi
  /// manual.
  Future<void> _pickContact() async {
    final selected = await _showAddressBookPicker();
    if (!mounted || selected == null) return;
    setState(() {
      _customerNameCtrl.text = selected.name;
      _customerPhoneCtrl.text = selected.phone;
      _isFromContactBook = true;
    });
  }

  /// Indirect: pilih kontak dari buku kontak untuk mengisi field penerima
  /// (Customer Baru mode — bukan Cabang/Gudang). Hanya nama + HP tersedia.
  Future<void> _pickReceiverContact() async {
    final selected = await _showAddressBookPicker();
    if (!mounted || selected == null) return;
    setState(() {
      _shippingNameCtrl.text = selected.name;
      _shippingPhoneCtrl.text = selected.phone;
      _isFromReceiverContactBook = true;
    });
  }

  // ── Save Quotation (delegated to extracted handler) ─────────

  Future<void> _handleSaveQuotation(
      BuildContext context, List<CartItem> cartItems) async {
    _syncLineTakeAwayToItemCount(cartItems.length);
    final isIndirect = cartItems.any((e) => e.isIndirectSale);
    await QuotationSaveHandler.save(
      context: context,
      cartItems: cartItems,
      selectedCartItems: widget.selectedCartItems,
      existingDraft: widget.restoredQuotation ?? ref.read(activeDraftProvider),
      popBackToHistory: widget.restoredQuotation != null,
      customerName: _customerNameCtrl.text.trim(),
      customerEmail: isIndirect
          ? _indirectContactEmailForOrder().trim()
          : _customerEmailCtrl.text.trim(),
      customerPhone: isIndirect
          ? _indirectContactPhoneForOrder().trim()
          : _customerPhoneCtrl.text.trim(),
      customerPhone2: isIndirect
          ? (_isShippingSameAsCustomer
              ? _customerPhone2Ctrl.text.trim()
              : _shippingPhone2Ctrl.text.trim())
          : _customerPhone2Ctrl.text.trim(),
      customerAddress: _customerAddressCombined,
      regionProvinsi: _selectedProvinsi,
      regionKota: _selectedKota,
      regionKecamatan: _selectedKecamatan,
      regionText: _customerRegionText,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      shippingName: _shippingNameCtrl.text.trim(),
      shippingPhone: _shippingPhoneCtrl.text.trim(),
      shippingPhone2:
          _isShippingSameAsCustomer ? '' : _shippingPhone2Ctrl.text.trim(),
      shippingAddress: _shippingAddressCombined,
      shippingRegionProvinsi: _shippingProvinsi,
      shippingRegionKota: _shippingKota,
      shippingRegionKecamatan: _shippingKecamatan,
      shippingRegionText: _shippingRegionText,
      orderDate: _orderDate,
      requestDate: _requestDate,
      lineTakeAway: List<bool>.generate(
        cartItems.length,
        (i) => _lineTakeAwayAt(i),
      ),
      receiverEmail: _shippingEmailCtrl.text.trim(),
      indirectNoPo: _noPoCtrl.text.trim(),
      bonusTakeAwayCheckedKeys: _takeAway.bonusCheckedKeysSnapshot,
      bonusTakeAwayQtyByKey: _takeAway.bonusQtySnapshot,
      postage: _postageCtrl.text.trim(),
      scCode: _scCodeCtrl.text.trim(),
      workPlaceName: ref.read(checkoutProvider.notifier).effectiveWorkPlaceName,
      grandTotal: _grandTotal,
      totalAkhir: _totalAkhir,
      notes: _notesController.text.trim(),
    );
  }

  // ── Submit ────────────────────────────────────────────────────

  Future<void> _handleCreateOrder(BuildContext context) async {
    if (_submitInFlight) return;
    if (ifOfflineShowFeedback(
      context,
      isOffline: ref.read(isOfflineProvider),
    )) {
      return;
    }
    if (!_validateForm()) return;
    _submitInFlight = true;

    _showLoadingOverlay(context);

    final cartItems = _effectiveCartItems(ref);
    _syncLineTakeAwayToItemCount(cartItems.length);
    final profile = ref.read(profileProvider).valueOrNull;
    final isIndirect = cartItems.any((e) => e.isIndirectSale);

    // Indirect tanpa trigger approval otomatis DAN tanpa slot ASM/RSM manual
    // → auto-approve. Kalau sales menambah ASM/RSM via +, jangan auto-approve.
    final manualAsm = ref.read(manualAsmRequestedProvider);
    final manualRsm = ref.read(manualRsmRequestedProvider);
    final autoApprove = isIndirect &&
        !_requiresSpvApproval(cartItems) &&
        !_requiresManagerApproval(cartItems) &&
        !manualAsm &&
        !manualRsm;

    final headerPayload = CheckoutPayloadBuilder.buildHeaderPayload(
      workPlaceId: null,
      customerAddress: _customerAddressCombined,
      selectedKecamatan: _selectedKecamatan,
      selectedKota: _selectedKota,
      selectedProvinsi: _selectedProvinsi,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      customerName: _customerNameCtrl.text,
      shippingName: _shippingNameCtrl.text,
      shippingAddress: _shippingAddressCombined,
      shippingKecamatan: _shippingKecamatan,
      shippingKota: _shippingKota,
      shippingProvinsi: _shippingProvinsi,
      postageText: _postageCtrl.text,
      creatorId: profile?.id ?? 0,
      divisions: profile?.divisions ?? const [],
      cartItems: cartItems,
      grandTotal: _grandTotal,
      orderDate: OrderLetterDateUtils.dateOnly(_orderDate),
      requestDate: _requestDate,
      customerPhone: isIndirect
          ? _indirectContactPhoneForOrder()
          : _customerPhoneCtrl.text,
      customerEmail: isIndirect
          ? _indirectContactEmailForOrder()
          : _customerEmailCtrl.text,
      note: _notesController.text,
      salesCode: _scCodeCtrl.text,
      headerAllLinesTakeAway: _headerAllLinesTakeAway(cartItems),
      useCustomerAddressDetailOnly: isIndirect,
      isIndirectOrder: isIndirect,
      indirectNoPoText: _noPoCtrl.text,
      indirectCustomerMaster: isIndirect
          ? cartItems
              .where((e) => e.isIndirectSale)
              .firstOrNull
              ?.indirectStoreAddressNumber
          : null,
      // ship_to_code = customer_master saat pengiriman ke toko yang sama
      // (bukan Cabang/Gudang, bukan Customer Baru).
      indirectShipToCode: isIndirect && _isShippingSameAsCustomer
          ? cartItems
              .where((e) => e.isIndirectSale)
              .firstOrNull
              ?.indirectStoreAddressNumber
          : null,
      autoApprove: autoApprove,
      userAddressNumber: ref.read(authProvider).addressNumber,
      soldtoAddress1: _customerAddressLine1Ctrl.text,
      soldtoAddress2: _customerAddressLine2Ctrl.text,
      soldtoAddress3: _customerAddressLine3Ctrl.text,
      shiptoAddress1: _shippingAddressLine1Ctrl.text,
      shiptoAddress2: _shippingAddressLine2Ctrl.text,
      shiptoAddress3: _shippingAddressLine3Ctrl.text,
      soldtoPostalCode: _selectedKodepos ?? '',
      shiptoPostalCode: _shippingKodepos ?? '',
    );

    final contactsPayload =
        CheckoutPayloadBuilder.buildOrderLetterContactsPayload(
      isIndirectOrder: isIndirect,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      customerPrimaryPhone: _customerPhoneCtrl.text,
      customerBackupPhone: _customerPhone2Ctrl.text,
      includeCustomerBackupPhone: _showBackupPhone,
      shippingPrimaryPhone: _shippingPhoneCtrl.text,
      shippingBackupPhone: _shippingPhone2Ctrl.text,
      includeShippingBackupPhone:
          !_isShippingSameAsCustomer && _showReceiverBackupPhone,
    );

    final userId = profile?.id ?? 0;
    final paymentPayloads = <Map<String, dynamic>>[];
    final receiptImages = <File?>[];

    final checkoutChannel = CheckoutChannelResolver.resolve(
      divisions: profile?.divisions ?? const [],
      userAddressNumber: ref.read(authProvider).addressNumber,
    );
    final canOptInPaper = !isIndirect &&
        CheckoutChannelResolver.canOptInPaperIdPayment(checkoutChannel);
    final usePaperPayment = canOptInPaper && _directUsePaperPayment;
    final useManualPayment = !isIndirect &&
        CheckoutChannelResolver.showsCheckoutPaymentSection(checkoutChannel) &&
        !usePaperPayment;

    if (useManualPayment) {
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
    }

    unawaited(ref.read(checkoutProvider.notifier).submitOrder(
          cartItems: cartItems,
          headerPayload: headerPayload,
          contactsPayload: contactsPayload,
          paymentPayloads: paymentPayloads,
          receiptImages: receiptImages,
          lineIsTakeAway: _lineTakeAwayAt,
          isBonusTakeAwayChecked: _isBonusTakeAwayChecked,
          currentTakeAwayQty: _currentTakeAwayQty,
          selectedCartItems: widget.selectedCartItems,
          requiresApproval: !autoApprove,
          requiresSpvApproval:
              _requiresSpvApproval(cartItems) || manualAsm,
          requiresManagerApproval:
              _requiresManagerApproval(cartItems) || manualRsm,
          usePaperPayment: usePaperPayment,
          paperPaymentAmount: _totalAkhir,
          paperCreatorId: userId,
        ));
  }

  Future<void> _handleEditOrder(
    BuildContext context,
    OrderHistory? editOrder,
  ) async {
    if (_submitInFlight) return;
    if (editOrder == null) return;
    if (ifOfflineShowFeedback(context,
        isOffline: ref.read(isOfflineProvider))) {
      return;
    }
    if (!_validateForm()) return;
    _submitInFlight = true;

    _showLoadingOverlay(context);

    final cartItems = _effectiveCartItems(ref);
    _syncLineTakeAwayToItemCount(cartItems.length);
    final isIndirect = cartItems.any((e) => e.isIndirectSale);

    // Mirror create: indirect tanpa trigger + tanpa slot manual → autoApprove.
    final manualAsm = ref.read(manualAsmRequestedProvider);
    final manualRsm = ref.read(manualRsmRequestedProvider);
    final autoApprove = isIndirect &&
        !_requiresSpvApproval(cartItems) &&
        !_requiresManagerApproval(cartItems) &&
        !manualAsm &&
        !manualRsm;

    // Kumpulkan payload pembayaran kekurangan (MM + Direct manual).
    // TODO(paper-shortage): Direct shortage via Paper — pending backend.
    final shortagePayloads = <Map<String, dynamic>>[];
    final shortageReceipts = <File?>[];
    final editChannel = CheckoutChannelResolver.resolve(
      divisions: ref.read(profileProvider).valueOrNull?.divisions ?? const [],
      userAddressNumber: ref.read(authProvider).addressNumber,
    );
    final useManualShortagePayment = !isIndirect &&
        CheckoutChannelResolver.showsCheckoutPaymentSection(editChannel);
    if (useManualShortagePayment) {
      final s = _computeEditSelisih(editOrder);
      if (s.isShortage) {
        final profile = ref.read(profileProvider).valueOrNull;
        final userId = profile?.id ?? 0;
        for (final p in _payments) {
          if (p.parsedAmount <= 0 && p.receiptImage == null) continue;
          shortagePayloads.add(CheckoutPayloadBuilder.buildPaymentEntryPayload(
            amountText: p.amountCtrl.text,
            method: p.method,
            bank: p.bank,
            otherChannelText: p.otherChannelCtrl.text,
            refText: p.refCtrl.text,
            date: p.date,
            noteText: p.noteCtrl.text,
            userId: userId,
          ));
          shortageReceipts.add(p.receiptImage);
        }
      }
    }

    unawaited(ref.read(checkoutProvider.notifier).submitEditOrder(
          editOrder: editOrder,
          cartItems: cartItems,
          lineIsTakeAway: _lineTakeAwayAt,
          isBonusTakeAwayChecked: _isBonusTakeAwayChecked,
          currentTakeAwayQty: _currentTakeAwayQty,
          shortagePaymentPayloads: shortagePayloads,
          shortageReceiptImages: shortageReceipts,
          requiresApproval: !autoApprove,
          requiresSpvApproval:
              _requiresSpvApproval(cartItems) || manualAsm,
          requiresManagerApproval:
              _requiresManagerApproval(cartItems) || manualRsm,
        ));
  }

  void _showSubmitErrorDialog(String message) {
    if (!mounted) return;
    final checkoutState = ref.read(checkoutProvider);
    final hasRetryDetails = checkoutState.retryDetails.isNotEmpty;
    final hasDiscountRetry = checkoutState.retryDiscountDetails.isNotEmpty;
    final hasAnyRetry = hasRetryDetails || hasDiscountRetry;
    final isWorkplaceError = message.contains('Tempat kerja tidak terdeteksi');

    final String title;
    if (hasRetryDetails) {
      title = 'Sebagian Barang Gagal';
    } else if (hasDiscountRetry) {
      title = 'Diskon Gagal Dicatat';
    } else if (isWorkplaceError) {
      title = 'Check-In Diperlukan';
    } else {
      title = 'Gagal Memproses';
    }

    showAdaptiveAlert(
      context: context,
      title: title,
      content: message,
      actions: [
        AdaptiveAction(
          label: hasAnyRetry ? 'Mengerti' : 'Tutup',
          isDefault: true,
          popResult: true,
        ),
      ],
    );
    ref.read(checkoutProvider.notifier).clearSubmitResult();
  }

  // ── Validation ────────────────────────────────────────────────

  bool _validateForm() {
    _syncLineTakeAwayToItemCount(_effectiveCartItems(ref).length);

    final isEditMode = ref.read(editOrderContextProvider) != null;

    // Di edit mode, hanya approval yang wajib divalidasi — field
    // pelanggan/pengiriman/pembayaran tidak diubah (UI-nya juga disembunyikan).
    if (isEditMode) {
      return _validateApprovalOnly();
    }

    final formValid = _formKey.currentState?.validate() ?? false;

    if (!formValid) {
      final (:key, :label) = _findFirstFormError();
      _showErrorAndScroll('Lengkapi field wajib di bagian $label.', key);
      return false;
    }

    final isIndirectCart =
        _effectiveCartItems(ref).any((e) => e.isIndirectSale);
    if (!isIndirectCart &&
        (_selectedProvinsi == null ||
            _selectedKota == null ||
            _selectedKecamatan == null ||
            _selectedKelurahan == null)) {
      _showErrorAndScroll('Pilih wilayah pelanggan.', _customerSectionKey);
      return false;
    }
    if (!_isShippingSameAsCustomer &&
        (_shippingProvinsi == null ||
            _shippingKota == null ||
            _shippingKecamatan == null ||
            _shippingKelurahan == null)) {
      _showErrorAndScroll('Pilih wilayah penerima.', _customerSectionKey);
      return false;
    }
    final checkoutState = ref.read(checkoutProvider);
    if (!checkoutState.useAttendanceStore &&
        checkoutState.selectedStore == null) {
      _showErrorAndScroll(
        'Pilih lokasi toko atau aktifkan lokasi absensi.',
        _deliverySectionKey,
      );
      return false;
    }
    final cartItems = _effectiveCartItems(ref);
    final needAsm = _requiresSpvApproval(cartItems) ||
        ref.read(manualAsmRequestedProvider);
    final needRsm = _requiresManagerApproval(cartItems) ||
        ref.read(manualRsmRequestedProvider);
    if (needAsm && checkoutState.selectedSpv == null) {
      _showErrorAndScroll(
        isIndirectCart
            ? 'Pilih Area Sales Manager (ASM).'
            : 'Pilih Supervisor (SPV).',
        _approvalSectionKey,
      );
      return false;
    }
    if (needRsm && checkoutState.selectedManager == null) {
      _showErrorAndScroll(
        isIndirectCart
            ? 'Pesanan ini memerlukan persetujuan RSM.'
            : 'Pesanan ini memerlukan persetujuan Manager.',
        _approvalSectionKey,
      );
      return false;
    }
    // Manual payment (receipt/DP) for MM + Direct when not opting into Paper.
    final checkoutChannel = CheckoutChannelResolver.resolve(
      divisions: ref.read(profileProvider).valueOrNull?.divisions ?? const [],
      userAddressNumber: ref.read(authProvider).addressNumber,
    );
    final canOptInPaper = !isIndirectCart &&
        CheckoutChannelResolver.canOptInPaperIdPayment(checkoutChannel);
    final usePaperMode = canOptInPaper && _directUsePaperPayment;
    final requireManualPayment = !isIndirectCart &&
        CheckoutChannelResolver.showsCheckoutPaymentSection(checkoutChannel) &&
        !usePaperMode;
    if (requireManualPayment) {
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
    }
    return true;
  }

  /// Edit mode: validasi approval + (jika direct & shortage) pembayaran kekurangan.
  bool _validateApprovalOnly() {
    final checkoutState = ref.read(checkoutProvider);
    final cartItems = _effectiveCartItems(ref);
    final isIndirectCart = cartItems.any((e) => e.isIndirectSale);

    final needAsm = _requiresSpvApproval(cartItems) ||
        ref.read(manualAsmRequestedProvider);
    final needRsm = _requiresManagerApproval(cartItems) ||
        ref.read(manualRsmRequestedProvider);
    if (needAsm && checkoutState.selectedSpv == null) {
      _showErrorAndScroll(
        isIndirectCart
            ? 'Pilih Area Sales Manager (ASM).'
            : 'Pilih Supervisor (SPV).',
        _approvalSectionKey,
      );
      return false;
    }
    if (needRsm && checkoutState.selectedManager == null) {
      _showErrorAndScroll(
        isIndirectCart
            ? 'Pesanan ini memerlukan persetujuan RSM.'
            : 'Pesanan ini memerlukan persetujuan Manager.',
        _approvalSectionKey,
      );
      return false;
    }

    // Direct edit + shortage: pembayaran bersifat OPSIONAL — user bisa bayar
    // sekarang, atau nanti lewat tombol "Tambah Pembayaran" di Detail Pesanan.
    // Tapi jika user MULAI mengisi (ada receipt / amount), form wajib lengkap.
    if (!isIndirectCart) {
      final editOrder = ref.read(editOrderContextProvider);
      if (editOrder != null) {
        final s = _computeEditSelisih(editOrder);
        if (s.isShortage && _payments.isNotEmpty) {
          final p = _payments.first;
          final hasReceipt = p.receiptImage != null;
          final hasAmount = p.parsedAmount > 0;
          final hasMethod = (p.method ?? '').isNotEmpty;
          final userStartedFilling = hasReceipt || hasAmount || hasMethod;
          if (userStartedFilling) {
            if (!hasReceipt) {
              _showErrorAndScroll(
                'Lengkapi bukti pembayaran atau kosongkan form '
                'pembayaran untuk bayar nanti.',
                _paymentSectionKey,
              );
              return false;
            }
            if (!hasMethod) {
              _showErrorAndScroll(
                'Pilih metode pembayaran.',
                _paymentSectionKey,
              );
              return false;
            }
            if (!hasAmount) {
              _showErrorAndScroll(
                'Isi nominal pembayaran.',
                _paymentSectionKey,
              );
              return false;
            }
            if (p.parsedAmount > s.sisaTagihan + 0.5) {
              _showErrorAndScroll(
                'Nominal pembayaran melebihi sisa tagihan '
                '(${_priceFmt(s.sisaTagihan)}).',
                _paymentSectionKey,
              );
              return false;
            }
          }
        }
      }
    }

    return true;
  }

  ({GlobalKey key, String label}) _findFirstFormError() {
    final checkoutState = ref.read(checkoutProvider);
    final isIndirect = _effectiveCartItems(ref).any((e) => e.isIndirectSale);
    final channel = CheckoutChannelResolver.resolve(
      divisions: ref.read(profileProvider).valueOrNull?.divisions ?? const [],
      userAddressNumber: ref.read(authProvider).addressNumber,
    );
    final skipPaymentValidation = isIndirect ||
        (CheckoutChannelResolver.canOptInPaperIdPayment(channel) &&
            _directUsePaperPayment);
    return CheckoutFormValidator.findFirstFormError(
      customerName: _customerNameCtrl.text,
      customerEmail: _customerEmailCtrl.text,
      customerPhone: _customerPhoneCtrl.text,
      customerPhone2: _customerPhone2Ctrl.text,
      customerAddress: _customerAddressCombined,
      isShippingSameAsCustomer: _isShippingSameAsCustomer,
      shippingName: _shippingNameCtrl.text,
      shippingPhone: _shippingPhoneCtrl.text,
      shippingPhone2: _shippingPhone2Ctrl.text,
      shippingAddress: _shippingAddressCombined,
      indirectStoreContactOptional: isIndirect,
      indirectReceiverContactOptional: isIndirect,
      indirectAlternateReceiverEmail: _shippingEmailCtrl.text,
      anyLineNeedsFactoryDelivery:
          _anyLineNeedsFactoryDelivery(_effectiveCartItems(ref)),
      orderDate: _orderDate,
      requestDate: _requestDate,
      requiresSpv: _requiresSpvApproval(_effectiveCartItems(ref)) ||
          ref.read(manualAsmRequestedProvider),
      hasSelectedSpv: checkoutState.selectedSpv != null,
      requiresManager: _requiresManagerApproval(_effectiveCartItems(ref)) ||
          ref.read(manualRsmRequestedProvider),
      hasSelectedManager: checkoutState.selectedManager != null,
      payments: _payments,
      customerSectionKey: _customerSectionKey,
      deliverySectionKey: _deliverySectionKey,
      approvalSectionKey: _approvalSectionKey,
      paymentSectionKey: _paymentSectionKey,
      indirectSkipPaymentValidation: skipPaymentValidation,
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

  void _showLoadingOverlay(
    BuildContext context, {
    String? title,
    String? subtitle,
  }) {
    LoadingOverlay.show(
      context,
      title: title ?? 'Menyimpan Pesanan...',
      subtitle: subtitle ?? 'Mohon tidak menutup aplikasi',
    );
  }

  Future<void> _refreshPricesFromServer(BuildContext context) async {
    if (_priceRefreshBusy || !mounted) return;
    if (ifOfflineShowFeedback(
      context,
      isOffline: ref.read(isOfflineProvider),
    )) {
      return;
    }

    final items = List<CartItem>.from(_effectiveCartItems(ref));
    if (items.isEmpty) return;

    var channel = items.first.product.channel.trim();
    var brand = items.first.product.brand.trim();
    if (channel.isEmpty) {
      channel = ref.read(selectedChannelProvider) ?? '';
    }
    if (brand.isEmpty) {
      brand = ref.read(selectedBrandProvider) ?? '';
    }
    if (channel.isEmpty || brand.isEmpty) {
      AppFeedback.show(
        context,
        message:
            'Channel atau brand tidak diketahui. Pilih filter yang sama di Beranda, lalu coba lagi.',
        type: AppFeedbackType.warning,
      );
      return;
    }

    for (final i in items) {
      final c =
          i.product.channel.trim().isEmpty ? channel : i.product.channel.trim();
      final b = i.product.brand.trim().isEmpty ? brand : i.product.brand.trim();
      if (c != channel || b != brand) {
        AppFeedback.show(
          context,
          message:
              'Barang berasal dari channel/brand berbeda. Periksa keranjang atau checkout per kelompok.',
          type: AppFeedbackType.warning,
        );
        return;
      }
    }

    setState(() => _priceRefreshBusy = true);

    void dismissOverlay() {
      if (!context.mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    }

    try {
      _showLoadingOverlay(
        context,
        title: 'Memperbarui harga…',
        subtitle: 'Mengambil pricelist terbaru',
      );

      final area = ref.read(effectiveAreaProvider);
      final catalog = await fetchFilteredPlProductsForRefresh(
        area: area,
        channel: channel,
        brand: brand,
      );

      if (!context.mounted) return;
      dismissOverlay();

      final result = CartItemPriceRefresh.applyToLines(items, catalog);

      if (_sessionLineItems != null) {
        setState(() => _sessionLineItems = result.items);
      } else {
        await ref.read(cartProvider.notifier).replaceCartItems(result.items);
      }

      if (!context.mounted) return;

      final baseMsg = result.updatedCount > 0
          ? 'Harga diperbarui untuk ${result.updatedCount} baris.'
          : 'Tidak ada perubahan harga dari server.';
      final msg = result.notFoundCount > 0
          ? '$baseMsg ${result.notFoundCount} baris tidak ditemukan di pricelist (cek area & filter).'
          : baseMsg;

      AppFeedback.show(
        context,
        message: msg,
        type: result.updatedCount > 0
            ? AppFeedbackType.success
            : AppFeedbackType.info,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'checkout refresh server prices');
      if (context.mounted) {
        dismissOverlay();
        AppFeedback.show(
          context,
          message: 'Gagal memperbarui harga. ${userFacingErrorMessage(e)}',
          type: AppFeedbackType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _priceRefreshBusy = false);
    }
  }

  // ── Reusable widgets ──────────────────────────────────────────

  /// Banner informatif di atas halaman saat edit mode — menjelaskan bahwa
  /// user hanya mengganti item pesanan, bukan membuat surat pesanan baru.
  Widget _buildEditModeBanner(OrderHistory order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note_rounded,
              color: AppColors.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Item Pesanan ${order.noSp}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pelanggan: ${order.customerName}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hanya daftar item yang diperbarui. Data pelanggan, '
                  'alamat pengiriman, dan pembayaran tetap sama.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hitung ringkasan tagihan di edit mode.
  ///
  /// Polanya sama seperti di `Detail Pesanan`:
  ///   - **Total Tagihan**  = `extended_amount` baru (total cart + ongkir lama)
  ///   - **Total Dibayar**  = jumlah `order_letter_payments` yang sudah ada
  ///   - **Sisa Tagihan**   = Total Tagihan − Total Dibayar
  ///     - `> 0` → user masih punya kekurangan (shortage)
  ///     - `< 0` → kelebihan bayar (overpaid)
  ///     - `= 0` → lunas
  _EditSelisih _computeEditSelisih(OrderHistory order) {
    final totalDibayar = order.payments
        .where((p) => p.countsTowardTotal)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalTagihan = _totalAkhir;
    final sisaTagihan = totalTagihan - totalDibayar;
    return _EditSelisih(
      totalTagihan: totalTagihan,
      totalDibayar: totalDibayar,
      sisaTagihan: sisaTagihan,
    );
  }

  /// Edit mode (direct only): ringkasan tagihan setelah edit — mengikuti pola
  /// tampilan di halaman `Detail Pesanan` (Total Tagihan, Total Dibayar,
  /// Sisa Tagihan).
  Widget _buildSelisihCard(OrderHistory order) {
    final s = _computeEditSelisih(order);

    final Color sisaColor;
    final String sisaLabel;
    final String? sisaHint;
    if (s.isShortage) {
      sisaColor = AppColors.statusPendingListForeground;
      sisaLabel = 'Sisa Tagihan';
      sisaHint = 'Anda dapat menambah pembayaran sekarang di bawah, '
          'atau nanti melalui halaman Detail Pesanan.';
    } else if (s.isOverpaid) {
      sisaColor = AppColors.success;
      sisaLabel = 'Kelebihan Bayar';
      sisaHint = 'Total dibayar melebihi tagihan baru. Koordinasikan '
          'dengan admin untuk refund atau kredit ke pesanan berikutnya.';
    } else {
      sisaColor = AppColors.success;
      sisaLabel = 'Lunas';
      sisaHint = null;
    }

    return _buildSectionCard(
      title: 'Ringkasan Tagihan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _selisihRow(
            'Total Tagihan',
            _priceFmt(s.totalTagihan),
            isBold: true,
          ),
          const SizedBox(height: 6),
          _selisihRow(
            'Total Dibayar',
            _priceFmt(s.totalDibayar),
            isMuted: true,
          ),
          const Divider(height: 22),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sisaColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sisaColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sisaLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sisaColor,
                      ),
                    ),
                    Text(
                      _priceFmt(s.sisaTagihan.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: sisaColor,
                      ),
                    ),
                  ],
                ),
                if (sisaHint != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sisaHint,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selisihRow(
    String label,
    String value, {
    bool strikethrough = false,
    bool isBold = false,
    bool isMuted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isMuted ? AppColors.textTertiary : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold
                ? AppColors.textPrimary
                : (isMuted ? AppColors.textTertiary : AppColors.textSecondary),
            decoration: strikethrough
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// Edit mode: card read-only berisi daftar item lama pada order yang
  /// sedang di-edit, supaya user bisa membandingkan dengan ringkasan baru.
  Widget _buildPreviousItemsCard(OrderHistory order) {
    final details = order.details;
    final totalPrev = details.fold<double>(
      0,
      (sum, d) =>
          sum + (d.extendedPrice > 0 ? d.extendedPrice : d.unitPrice * d.qty),
    );

    return _buildSectionCard(
      title: 'Item Sebelumnya (${details.length})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Daftar item pesanan saat ini — akan diganti dengan item baru '
              'setelah Anda menekan "Simpan Perubahan".',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...details.map((d) => _buildPreviousItemRow(d)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Sebelumnya',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _priceFmt(totalPrev),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousItemRow(OrderDetail d) {
    final name = d.itemDescription.isNotEmpty
        ? d.itemDescription
        : (d.desc1.isNotEmpty ? d.desc1 : d.itemType);
    final lineTotal =
        d.extendedPrice > 0 ? d.extendedPrice : d.unitPrice * d.qty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (d.itemType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tipe: ${d.itemType}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  '${d.qty}x @ ${_priceFmt(d.unitPrice)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _priceFmt(lineTotal),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

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

  int _bonusTakeAwayMaxQty(int itemIndex, CartBonusSnapshot bonus) {
    final items = _effectiveCartItems(ref);
    if (itemIndex < 0 || itemIndex >= items.length) {
      return bonus.qty;
    }
    final itemQty = items[itemIndex].quantity;
    return bonus.qty * (itemQty < 1 ? 1 : itemQty);
  }

  bool _isBonusTakeAwayChecked(int itemIndex, CartBonusSnapshot bonus) =>
      _takeAway.isChecked(itemIndex, bonus);

  int _currentTakeAwayQty(int itemIndex, CartBonusSnapshot bonus) =>
      _takeAway.currentQty(
        itemIndex,
        bonus,
        maxQty: _bonusTakeAwayMaxQty(itemIndex, bonus),
      );

  void _toggleBonusTakeAway(
      int itemIndex, CartBonusSnapshot bonus, bool checked) {
    setState(
      () => _takeAway.toggle(
        itemIndex,
        bonus,
        checked,
        maxQty: _bonusTakeAwayMaxQty(itemIndex, bonus),
      ),
    );
  }

  void _setTakeAwayQty(int itemIndex, CartBonusSnapshot bonus, int value) {
    setState(
      () => _takeAway.setQty(
        itemIndex,
        bonus,
        value,
        maxQty: _bonusTakeAwayMaxQty(itemIndex, bonus),
      ),
    );
  }
}

/// Ringkasan tagihan pada edit mode — mengikuti pola di halaman Detail Pesanan.
class _EditSelisih {
  const _EditSelisih({
    required this.totalTagihan,
    required this.totalDibayar,
    required this.sisaTagihan,
  });

  /// `extended_amount` baru setelah edit (total cart + ongkir lama).
  final double totalTagihan;

  /// Jumlah pembayaran yang sudah ada pada order (tidak ikut berubah saat edit).
  final double totalDibayar;

  /// `totalTagihan − totalDibayar` (positif = kurang bayar, negatif = kelebihan).
  final double sisaTagihan;

  bool get isShortage => sisaTagihan > 0.5;
  bool get isOverpaid => sisaTagihan < -0.5;
  bool get isLunas => !isShortage && !isOverpaid;
}
