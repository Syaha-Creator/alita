import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/sales_mode.dart';
import '../../../../core/services/app_analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../core/utils/discount_formatter.dart';
import '../../../../core/utils/number_input_formatter.dart';
import '../../../../core/utils/store_display_utils.dart';
import '../../../../core/utils/store_discount_calculator.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/go_router_pop_scope.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../cart/data/cart_indirect_meta.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../indirect/data/models/assigned_store.dart';
import '../../../indirect/logic/indirect_session_provider.dart';
import '../../../indirect/logic/sales_mode_provider.dart';
import '../../data/models/pricelist_custom_line.dart';
import '../../data/models/product.dart';
import '../../logic/pricelist_custom_line_builder.dart';
import '../../logic/product_detail_utils.dart';
import '../../logic/product_provider.dart';
import '../widgets/bonus_editor_modal.dart';
import '../widgets/discount_modal.dart';
import '../widgets/program_bulanan_card.dart';

/// Form tambah / ubah satu baris pricelist tanpa SKU (brand dari filter aktif).
class PricelistCustomLinePage extends ConsumerStatefulWidget {
  const PricelistCustomLinePage({
    super.key,
    this.editItem,
    this.cartIndex,
  });

  final CartItem? editItem;
  final int? cartIndex;

  @override
  ConsumerState<PricelistCustomLinePage> createState() =>
      _PricelistCustomLinePageState();
}

class _PricelistCustomLinePageState
    extends ConsumerState<PricelistCustomLinePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ukuranCtrl;
  late final TextEditingController _plCtrl;
  late final TextEditingController _eupCtrl;
  late final TextEditingController _targetTotalController;

  // Diskon program berjenjang (indirect only, opsional): 2 tingkat persentase.
  // Diterapkan SEBELUM diskon toko dalam cascade harga.
  late final TextEditingController _prog1Ctrl;
  late final TextEditingController _prog2Ctrl;

  final FocusNode _totalFocusNode = FocusNode();

  PricelistCustomComponentType _type = PricelistCustomComponentType.mattress;
  int _qty = 1;
  List<double> _appliedDiscounts = [];

  /// Total jual per unit hasil edit langsung (sama konsep dengan halaman detail).
  double? targetTotalEup;

  bool _bonusCustomized = false;
  List<Map<String, dynamic>> _customBonuses = [];

  // Toggle aktif/nonaktif diskon program & diskon toko (indirect only).
  bool _useProgramDiscount = true;
  bool _useStoreDiscount = true;

  // Program Bulanan (indirect only) — diskon pra-negosiasi bulanan.
  String _programBulananType = '';
  double _programBulananValue = 0.0;

  // Harga 0: item ini net_price=0 tanpa diskon tambahan.
  bool _isZeroPrice = false;

  bool _isSubmitting = false;

  static final NumberFormat _totalCurrencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  static String _moneyText(double v) {
    if (v <= 0) return '';
    return NumberFormat('#,###', 'id_ID').format(v.round());
  }

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    if (edit != null) {
      final p = edit.product;
      _nameCtrl = TextEditingController(text: p.name.trim());
      _ukuranCtrl = TextEditingController(text: p.ukuran.trim());
      final t = PricelistCustomLineBuilder.componentTypeFromProduct(p);
      if (t != null) _type = t;
      final resolvedType = t ?? PricelistCustomComponentType.mattress;
      final pl = switch (resolvedType) {
        PricelistCustomComponentType.divan => p.plDivan,
        PricelistCustomComponentType.headboard => p.plHeadboard,
        PricelistCustomComponentType.sorong => p.plSorong,
        // mattress + semua tipe non-bundle tersimpan di kasur field
        _ => p.plKasur,
      };
      // eupKasur di snapshot menyimpan EUP SETELAH diskon program diterapkan.
      // Untuk menampilkan EUP asli di field, kita reverse-cascade menggunakan
      // string `p.program` yang menyimpan persentase diskon program.
      final eupAfterProg = switch (resolvedType) {
        PricelistCustomComponentType.divan => p.eupDivan,
        PricelistCustomComponentType.headboard => p.eupHeadboard,
        PricelistCustomComponentType.sorong => p.eupSorong,
        // mattress + semua tipe non-bundle tersimpan di kasur field
        _ => p.eupKasur,
      };
      final existingProgs = _parseProgramString(p.program);
      final eupOriginal = _reverseProgCascade(eupAfterProg, existingProgs);
      _plCtrl = TextEditingController(text: _moneyText(pl));
      _eupCtrl = TextEditingController(text: _moneyText(eupOriginal));
      _prog1Ctrl = TextEditingController(
        text: existingProgs.isNotEmpty
            ? _pctText(existingProgs[0])
            : '',
      );
      _prog2Ctrl = TextEditingController(
        text: existingProgs.length > 1
            ? _pctText(existingProgs[1])
            : '',
      );
      _qty = edit.quantity;
      _appliedDiscounts = [
        edit.discount1 / 100,
        edit.discount2 / 100,
        edit.discount3 / 100,
        edit.discount4 / 100,
      ];
      while (_appliedDiscounts.isNotEmpty && _appliedDiscounts.last == 0) {
        _appliedDiscounts.removeLast();
      }
      if (edit.bonusSnapshots.isNotEmpty) {
        _bonusCustomized = true;
        _customBonuses = edit.bonusSnapshots
            .where((b) => b.name.trim().isNotEmpty)
            .map(
              (b) => <String, dynamic>{
                'name': b.name,
                'qty': b.qty,
                'item_num': b.sku,
                'max_qty': b.qty > 0 ? b.qty * 2 : 2,
              },
            )
            .toList();
      }
      // Restore Program Bulanan jika cart item punya nilai yang valid.
      if (edit.hasProgramBulanan) {
        _programBulananType = edit.programBulananType;
        _programBulananValue = edit.programBulananType == 'percent'
            ? edit.programBulananDiscount
            : edit.programBulananNominal;
      }
      _isZeroPrice = edit.isZeroPrice;
    } else {
      _nameCtrl = TextEditingController();
      _ukuranCtrl = TextEditingController();
      _plCtrl = TextEditingController();
      _eupCtrl = TextEditingController();
      _prog1Ctrl = TextEditingController();
      _prog2Ctrl = TextEditingController();
    }
    _targetTotalController = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ukuranCtrl.dispose();
    _plCtrl.dispose();
    _eupCtrl.dispose();
    _prog1Ctrl.dispose();
    _prog2Ctrl.dispose();
    _targetTotalController.dispose();
    _totalFocusNode.dispose();
    super.dispose();
  }

  List<CartBonusSnapshot> _bonusSnapshotsForCart() {
    return _customBonuses
        .map((b) {
          final name = b['name']?.toString().trim() ?? '';
          if (name.isEmpty) return null;
          final qty = (b['qty'] as num?)?.toInt() ?? 1;
          final sku = b['item_num']?.toString().trim() ?? '';
          final plPrice = (b['pl'] as num?)?.toDouble() ?? 0.0;
          return CartBonusSnapshot(name: name, qty: qty, sku: sku, plPrice: plPrice);
        })
        .whereType<CartBonusSnapshot>()
        .toList();
  }

  double _parseMoney(TextEditingController c) {
    final d = ThousandsSeparatorInputFormatter.digitsOnly(c.text);
    if (d.isEmpty) return 0;
    return double.tryParse(d) ?? 0;
  }

  // ── Program discount helpers ──────────────────────────────────────────────

  /// Parse string program dari Product (e.g. "10%+5%") → daftar persentase.
  static List<double> _parseProgramString(String program) {
    if (program.isEmpty || program == '-') return [];
    return program
        .split('+')
        .map((s) => double.tryParse(
              s.trim().replaceAll('%', '').replaceAll(',', '.'),
            ) ??
            0.0)
        .where((v) => v > 0)
        .toList();
  }

  /// Format persentase untuk TextField (tanpa trailing zero, e.g. "10", "5.5").
  static String _pctText(double v) {
    if (v <= 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString().replaceAll('.', ',');
  }

  /// Reverse cascade: kembalikan EUP asli dari EUP-setelah-program.
  static double _reverseProgCascade(double eupAfterProg, List<double> progs) {
    if (progs.isEmpty) return eupAfterProg;
    var factor = 1.0;
    for (final p in progs) {
      factor *= (1 - p / 100);
    }
    return factor > 0 ? eupAfterProg / factor : eupAfterProg;
  }

  /// Hitung harga setelah diskon Program Bulanan diterapkan di atas [base].
  double _applyProgramBulanan(double base) {
    if (_programBulananType == 'percent' && _programBulananValue > 0) {
      return (base * (1 - _programBulananValue / 100)).clamp(0, double.infinity);
    } else if (_programBulananType == 'nominal' && _programBulananValue > 0) {
      return (base - _programBulananValue).clamp(0, double.infinity);
    }
    return base;
  }

  /// Daftar persentase program diskon yang diisi user (non-zero).
  /// Mengembalikan list kosong jika toggle diskon program dimatikan.
  List<double> _currentProgramDiscounts() {
    if (!_useProgramDiscount) return [];
    double parse(TextEditingController c) =>
        double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0.0;
    final p1 = parse(_prog1Ctrl);
    final p2 = parse(_prog2Ctrl);
    return [if (p1 > 0) p1, if (p2 > 0) p2];
  }

  /// EUP asli (dari _eupCtrl) setelah diskon program diterapkan.
  double _eupAfterProgram(double unitEup) {
    final progs = _currentProgramDiscounts();
    if (progs.isEmpty) return unitEup;
    return StoreDiscountCalculator.cascade(unitEup, progs);
  }

  Product _snapshotForDiscountModal(
    String channel,
    String brand, {
    required double effectiveBasePrice,
  }) {
    final pl = _parseMoney(_plCtrl);
    // Modal memakai harga efektif (setelah program) sebagai basis limit diskon.
    final eupForModal = _eupAfterProgram(effectiveBasePrice > 0 ? effectiveBasePrice : 1);
    return PricelistCustomLineBuilder.buildProductSnapshot(
      lineId: 'temp_discount_modal',
      productName: _nameCtrl.text.trim().isEmpty ? '—' : _nameCtrl.text.trim(),
      ukuran: _ukuranCtrl.text.trim().isEmpty ? '—' : _ukuranCtrl.text.trim(),
      brand: brand,
      channel: channel,
      type: _type,
      unitPricelist: pl > 0 ? pl : 1,
      unitEup: eupForModal,
    );
  }

  /// Dasar diskon penjualan: EUP → diskon program → diskon toko (indirect only).
  ///
  /// Urutan cascade:
  ///   1. `unitEup` (EUP asli — input user)
  ///   2. Diskon Program (SEMUA mode — user-entered cascade %)
  ///   3. Diskon Toko (indirect ONLY — dari master toko)
  double _plDiscountBaseTotal(
    double unitEup,
    List<double> storeDiscounts,
    bool indirect,
  ) {
    if (unitEup <= 0) return 0;
    var base = unitEup;
    // Diskon Program berlaku di semua mode (direct & indirect).
    if (_useProgramDiscount) {
      final progs = _currentProgramDiscounts();
      if (progs.isNotEmpty) {
        base = StoreDiscountCalculator.cascade(base, progs);
      }
    }
    // Diskon Toko hanya untuk indirect.
    if (indirect && _useStoreDiscount && storeDiscounts.isNotEmpty) {
      base = StoreDiscountCalculator.cascade(base, storeDiscounts);
    }
    return base;
  }

  double _totalFinalPerUnit(double plBase) {
    if (plBase <= 0) return 0;
    return ProductDetailUtils.calculateCascadingPrice(
        plBase, _appliedDiscounts);
  }

  void _onTargetTotalChangedRaw(
    String s,
    Product snap,
    double plBase,
  ) {
    final digits = ThousandsSeparatorInputFormatter.digitsOnly(s);
    final v = digits.isEmpty ? null : double.tryParse(digits);
    if (v != null && v > 0 && plBase > 0) {
      final maxLimits = ProductDetailUtils.collectMaxLimits([
        snap.disc1,
        snap.disc2,
        snap.disc3,
        snap.disc4,
        snap.disc5,
        snap.disc6,
        snap.disc7,
        snap.disc8,
      ]);
      final newDiscs = ProductDetailUtils.computeDiscountsFromTargetTotal(
        v,
        plBase,
        maxLimits,
      );
      setState(() {
        targetTotalEup = v;
        _appliedDiscounts = newDiscs;
      });
    } else {
      setState(() {
        targetTotalEup = null;
        _appliedDiscounts = [];
      });
    }
  }

  void _resetDiscounts(double plBase) {
    setState(() {
      targetTotalEup = null;
      _appliedDiscounts = [];
    });
    if (plBase > 0) {
      _targetTotalController.text = _totalCurrencyFormat.format(plBase).trim();
    } else {
      _targetTotalController.clear();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _doSubmit();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _doSubmit() async {
    // For preloaded edit items, fall back to the product's own brand/channel.
    final editProduct = widget.editItem?.product;
    final brand = ref.read(selectedBrandProvider) ??
        (editProduct?.brand.trim().isNotEmpty == true
            ? editProduct!.brand.trim()
            : null);
    final channel = ref.read(selectedChannelProvider) ??
        (editProduct?.channel.trim().isNotEmpty == true
            ? editProduct!.channel.trim()
            : null);
    if (brand == null || channel == null) {
      AppFeedback.show(
        context,
        message:
            'Channel atau brand tidak tersedia. Kembali ke beranda dan pilih filter.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final ukuran = _ukuranCtrl.text.trim();
    final pl = _parseMoney(_plCtrl);

    if (name.isEmpty) {
      AppFeedback.show(
        context,
        message: 'Nama produk wajib diisi.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }
    if (ukuran.isEmpty) {
      AppFeedback.show(
        context,
        message: 'Ukuran wajib diisi.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }
    if (pl <= 0) {
      AppFeedback.show(
        context,
        message: 'Harga pricelist harus lebih dari 0.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }
    if (_qty < 1) {
      AppFeedback.show(
        context,
        message: 'Kuantitas minimal 1.',
        type: AppFeedbackType.error,
        floating: true,
      );
      return;
    }

    final salesMode = ref.read(salesModeProvider);
    CartIndirectMeta? indirectMeta;
    if (salesMode == SalesMode.indirect) {
      final session = ref.read(indirectSessionProvider);
      if (session.isLoadingDiscounts) {
        AppFeedback.show(
          context,
          message: 'Diskon toko sedang dimuat. Tunggu sebentar.',
          type: AppFeedbackType.warning,
          floating: true,
        );
        return;
      }
      if (!session.hasStore) {
        AppFeedback.show(
          context,
          message:
              'Pilih toko assign di katalog terlebih dahulu (strip filter atas).',
          type: AppFeedbackType.warning,
          floating: true,
        );
        return;
      }
      final store = session.selectedStore!;
      // Saat toggle Diskon Toko dimatikan, jangan sertakan diskon toko di
      // indirectMeta — cart item akan tersimpan tanpa diskon toko.
      final effectiveStoreDiscounts = _useStoreDiscount
          ? List<double>.from(session.storeDiscounts)
          : const <double>[];
      indirectMeta = CartIndirectMeta(
        addressNumber: store.addressNumber,
        alphaName: StoreDisplayUtils.assignedStoreRowLabel(
          alphaName: store.alphaName,
          catcode27: store.catcode27,
        ),
        address: store.address,
        phone: '',
        storeDiscounts: effectiveStoreDiscounts,
        discountDisplay: _useStoreDiscount && session.storeDiscounts.isNotEmpty
            ? StoreDiscountCalculator.formatDisplay(session.storeDiscounts)
            : '',
        isNewCustomer: store.isNewCustomer,
        searchType: store.searchType?.trim() ?? '',
        discountCode: session.discountCode,
      );
    }

    final lineId = widget.editItem != null
        ? widget.editItem!.product.id
        : PricelistCustomLineBuilder.newCartLineId();

    // EUP yang disimpan ke snapshot adalah harga pricelist SETELAH diskon program
    // diterapkan. Harga Customer tidak lagi di-input manual — EUP selalu diturunkan
    // dari harga pricelist via cascade diskon program.
    final eupForSnapshot = _eupAfterProgram(pl);
    final progDiscounts = _currentProgramDiscounts();
    final programLabel = progDiscounts.isNotEmpty
        ? StoreDiscountCalculator.formatDisplay(progDiscounts)
        : '-';

    final snapshot = PricelistCustomLineBuilder.buildProductSnapshot(
      lineId: lineId,
      productName: name,
      ukuran: ukuran,
      brand: brand,
      channel: channel,
      type: _type,
      unitPricelist: pl,
      unitEup: eupForSnapshot,
      program: programLabel,
    );

    // Bila harga 0 aktif: hapus semua diskon tambahan — net_price = 0 tanpa approval.
    final effectiveDiscounts = _isZeroPrice ? <double>[] : _appliedDiscounts;

    var cartItem = PricelistCustomLineBuilder.buildCartItem(
      productSnapshot: snapshot,
      quantity: _qty,
      appliedDiscountFractions: effectiveDiscounts,
      indirectMeta: indirectMeta,
      bonusSnapshots: _bonusSnapshotsForCart(),
      pricelistArea: ref.read(effectiveAreaProvider),
      isBonusCustomized: _bonusCustomized,
    );

    // Tandai item harga 0 (net_price = 0 di checkout service).
    if (_isZeroPrice) {
      cartItem = cartItem.copyWith(isZeroPrice: true);
    }

    // Sisipkan Program Bulanan ke cart item (hanya indirect, hanya jika diisi).
    if (_programBulananType.isNotEmpty && _programBulananValue > 0) {
      cartItem = cartItem.copyWith(
        programBulananType: _programBulananType,
        programBulananDiscount:
            _programBulananType == 'percent' ? _programBulananValue : 0.0,
        programBulananNominal:
            _programBulananType == 'nominal' ? _programBulananValue : 0.0,
      );
    }

    final idx = widget.cartIndex;
    if (widget.editItem != null && idx != null) {
      final prevFoc = ref.read(cartProvider)[idx].isFocVoucher;
      cartItem = cartItem.copyWith(isFocVoucher: prevFoc);
      await ref.read(cartProvider.notifier).updateCartItem(
            idx,
            cartItem,
            preserveQuantity: false,
          );
      if (!mounted) return;
      AppFeedback.show(
        context,
        message: 'Baris custom diperbarui',
        type: AppFeedbackType.success,
        floating: true,
      );
    } else {
      await ref.read(cartProvider.notifier).addItem(cartItem);
      await AppAnalyticsService.logAddToCart(lineId, name);
      if (!mounted) return;
      AppFeedback.show(
        context,
        message: '$name ditambahkan ke keranjang',
        type: AppFeedbackType.success,
        floating: true,
      );
    }
    if (!mounted) return;
    context.pop();
  }

  void _openDiscountModal(String channel, String brand) {
    final indirect = ref.read(salesModeProvider) == SalesMode.indirect;
    // Basis selalu dari harga pricelist.
    final basePrice = _parseMoney(_plCtrl);
    if (basePrice <= 0) {
      AppFeedback.show(
        context,
        message: 'Isi harga pricelist terlebih dahulu untuk dasar perhitungan diskon.',
        type: AppFeedbackType.warning,
        floating: true,
      );
      return;
    }
    final snap = _snapshotForDiscountModal(channel, brand,
        effectiveBasePrice: basePrice);
    final session = ref.read(indirectSessionProvider);
    final storeDiscounts = indirect && session.hasDiscounts
        ? session.storeDiscounts
        : const <double>[];
    final plBase = _plDiscountBaseTotal(basePrice, storeDiscounts, indirect);

    showDiscountModalGlobal(
      context,
      snap,
      _appliedDiscounts,
      (newDiscounts) {
        setState(() {
          _appliedDiscounts = newDiscounts;
          targetTotalEup = null;
        });
      },
      additionalDiscountBaseTotal: plBase > 0 ? plBase : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // For preloaded edit items, fall back to the product's own brand/channel
    // if the global filter providers are not set (user came from order history).
    final editProduct = widget.editItem?.product;
    final brand = ref.watch(selectedBrandProvider) ??
        (editProduct?.brand.trim().isNotEmpty == true
            ? editProduct!.brand.trim()
            : null);
    final channel = ref.watch(selectedChannelProvider) ??
        (editProduct?.channel.trim().isNotEmpty == true
            ? editProduct!.channel.trim()
            : null);
    final salesMode = ref.watch(salesModeProvider);
    final indirectSession = ref.watch(indirectSessionProvider);
    final storeDiscounts =
        salesMode == SalesMode.indirect && indirectSession.hasDiscounts
            ? indirectSession.storeDiscounts
            : const <double>[];

    final isIndirectMode = salesMode == SalesMode.indirect;
    // Basis kalkulasi selalu dari harga pricelist (_plCtrl).
    // EUP diturunkan otomatis dari pricelist via cascade diskon.
    final unitEup =
        brand != null && channel != null ? _parseMoney(_plCtrl) : 0.0;
    // Section "Rincian Harga" muncul di semua mode (direct & indirect).
    // Diskon Toko hanya tersedia di indirect dengan store discounts.
    final useIndirectStoreNet = isIndirectMode && storeDiscounts.isNotEmpty;
    final showPriceBreakdown = brand != null && channel != null;
    final plBase =
        _plDiscountBaseTotal(unitEup, storeDiscounts, useIndirectStoreNet);

    final modalSnap = brand != null && channel != null
        ? _snapshotForDiscountModal(channel, brand,
            effectiveBasePrice: unitEup)
        : null;

    if (modalSnap != null && !_totalFocusNode.hasFocus && plBase > 0) {
      final display = targetTotalEup ?? _totalFinalPerUnit(plBase);
      final text = _totalCurrencyFormat.format(display).trim();
      if (_targetTotalController.text != text) {
        _targetTotalController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    final isSubmitEnabled = brand != null && channel != null && !_isSubmitting;
    final isEditMode = widget.editItem != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditMode ? 'Edit Item Manual' : 'Item Manual',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              isIndirectMode ? 'Mode Indirect' : 'Mode Direct',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isIndirectMode
                    ? AppColors.accent.withValues(alpha: 0.85)
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Kembali',
          onPressed: () => GoRouterPopScope.handlePop(
            context,
            fallbackLocation: '/',
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayoutTokens.space16,
              vertical: AppLayoutTokens.space12,
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppLayoutTokens.space12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitEnabled ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor:
                            AppColors.accent.withValues(alpha: 0.4),
                        disabledForegroundColor:
                            AppColors.onPrimary.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppLayoutTokens.radius10),
                        ),
                        elevation: 0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isSubmitting
                            ? const SizedBox(
                                key: ValueKey('loading'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.onPrimary),
                                ),
                              )
                            : Row(
                                key: const ValueKey('label'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditMode
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.shopping_cart_outlined,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditMode
                                        ? 'Simpan Perubahan'
                                        : 'Tambah ke Keranjang',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppLayoutTokens.space16,
            AppLayoutTokens.space8,
            AppLayoutTokens.space16,
            AppLayoutTokens.space16,
          ),
          children: [
            if (brand == null || channel == null)
              Container(
                padding: const EdgeInsets.all(AppLayoutTokens.space16),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
                  border: Border.all(color: AppColors.warningBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.warning),
                    const SizedBox(width: AppLayoutTokens.space8),
                    Expanded(
                      child: Text(
                        'Brand atau channel belum dipilih — kembali ke beranda dan lengkapi filter.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // ── Context strip: Brand • Channel • Mode ────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayoutTokens.space12,
                  vertical: AppLayoutTokens.space10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.style_outlined,
                        size: 15, color: AppColors.textTertiary),
                    const SizedBox(width: AppLayoutTokens.space6),
                    Text(
                      brand,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppLayoutTokens.space8),
                      width: 1,
                      height: 14,
                      color: AppColors.divider,
                    ),
                    const Icon(Icons.storefront_outlined,
                        size: 15, color: AppColors.textTertiary),
                    const SizedBox(width: AppLayoutTokens.space6),
                    Expanded(
                      child: Text(
                        channel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppLayoutTokens.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isIndirectMode
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.textTertiary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius8),
                      ),
                      child: Text(
                        isIndirectMode ? 'Indirect' : 'Direct',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isIndirectMode
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Indirect: tampilkan nama toko assign jika ada
              if (isIndirectMode && indirectSession.hasStore) ...[
                const SizedBox(height: AppLayoutTokens.space6),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        indirectSession.selectedStore!.alphaName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppLayoutTokens.space16),
              SectionCard(
                title: 'Detail Barang',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Nama + Ukuran ────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel('Nama Produk'),
                              const SizedBox(height: AppLayoutTokens.space6),
                              TextField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: CheckoutInputDecoration.form(
                                  hintText: 'mis. Comforta Super Fit',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppLayoutTokens.space10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const FormFieldLabel('Ukuran'),
                              const SizedBox(height: AppLayoutTokens.space6),
                              TextField(
                                controller: _ukuranCtrl,
                                decoration: CheckoutInputDecoration.form(
                                  hintText: 'mis. 160×200',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    // ── Jenis Produk ─────────────────────────────────────
                    const FormFieldLabel('Jenis Produk'),
                    const SizedBox(height: AppLayoutTokens.space10),
                    // Grid 2 kolom — 4 baris rapi
                    ...() {
                      final types = PricelistCustomComponentType.values;
                      final rows = <Widget>[];
                      for (var i = 0; i < types.length; i += 2) {
                        rows.add(
                          Row(
                            children: [
                              Expanded(
                                  child: _TypeTile(
                                type: types[i],
                                selected: _type == types[i],
                                onTap: () => setState(() {
                                  _type = types[i];
                                  targetTotalEup = null;
                                }),
                              )),
                              const SizedBox(width: AppLayoutTokens.space8),
                              if (i + 1 < types.length)
                                Expanded(
                                    child: _TypeTile(
                                  type: types[i + 1],
                                  selected: _type == types[i + 1],
                                  onTap: () => setState(() {
                                    _type = types[i + 1];
                                    targetTotalEup = null;
                                  }),
                                ))
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                        if (i + 2 < types.length) {
                          rows.add(
                              const SizedBox(height: AppLayoutTokens.space8));
                        }
                      }
                      return rows;
                    }(),
                    const SizedBox(height: AppLayoutTokens.space16),
                    // ── Harga Pricelist + Kuantitas (2 kolom) ────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const FormFieldLabel('Harga Pricelist'),
                                  const SizedBox(
                                      width: AppLayoutTokens.space6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'per unit',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppLayoutTokens.space6),
                              TextField(
                                controller: _plCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  ThousandsSeparatorInputFormatter()
                                ],
                                decoration: CheckoutInputDecoration.form(
                                  hintText: '0',
                                  prefixText: 'Rp ',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppLayoutTokens.space16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FormFieldLabel('Qty'),
                            const SizedBox(height: AppLayoutTokens.space6),
                            QuantityStepper(
                              quantity: _qty,
                              onDecrement: () {
                                if (_qty > 1) setState(() => _qty--);
                              },
                              onIncrement: () => setState(() => _qty++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ── Rincian Harga (direct & indirect) ────────────────────
              // Diskon Program: tersedia di semua mode.
              // Diskon Toko: hanya indirect dengan store discounts.
              if (showPriceBreakdown) ...[
                const SizedBox(height: AppLayoutTokens.space16),
                SectionCard(
                  title: 'Rincian Harga',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Toggle: Diskon Program ────────────────────────
                      _ToggleRow(
                        icon: Icons.percent_rounded,
                        iconColor: AppColors.success,
                        title: 'Diskon Program',
                        subtitle: isIndirectMode
                            ? 'Cascade sebelum diskon toko'
                            : 'Diskon bertingkat dari pricelist',
                        value: _useProgramDiscount,
                        onChanged: (v) => setState(() {
                          _useProgramDiscount = v;
                          targetTotalEup = null;
                          _appliedDiscounts = [];
                        }),
                      ),
                      if (_useProgramDiscount) ...[
                        const SizedBox(height: AppLayoutTokens.space10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _prog1Ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: CheckoutInputDecoration.form(
                                  hintText: '0',
                                  labelText: 'Tingkat 1',
                                  suffixIcon: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('%',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ),
                                ),
                                onChanged: (_) => setState(() {
                                  targetTotalEup = null;
                                  _appliedDiscounts = [];
                                }),
                              ),
                            ),
                            const SizedBox(width: AppLayoutTokens.space8),
                            Expanded(
                              child: TextField(
                                controller: _prog2Ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: CheckoutInputDecoration.form(
                                  hintText: '0',
                                  labelText: 'Tingkat 2',
                                  suffixIcon: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('%',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary)),
                                  ),
                                ),
                                onChanged: (_) => setState(() {
                                  targetTotalEup = null;
                                  _appliedDiscounts = [];
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // ── Toggle: Diskon Toko (indirect only) ──────────
                      if (useIndirectStoreNet) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppLayoutTokens.space12),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                        _ToggleRow(
                          icon: Icons.storefront_outlined,
                          iconColor: AppColors.accent,
                          title: 'Diskon Toko',
                          subtitle: storeDiscounts.isNotEmpty
                              ? StoreDiscountCalculator.formatDisplay(
                                  storeDiscounts)
                              : 'Tidak ada diskon toko',
                          value: _useStoreDiscount,
                          onChanged: (v) => setState(() {
                            _useStoreDiscount = v;
                            targetTotalEup = null;
                            _appliedDiscounts = [];
                          }),
                        ),
                      ],
                      // ── Program Bulanan (indirect only) ──────────────
                      if (isIndirectMode) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppLayoutTokens.space12),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                        ProgramBulananCard(
                          type: _programBulananType,
                          value: _programBulananValue,
                          onChanged: (type, value) => setState(() {
                            _programBulananType = type;
                            _programBulananValue = value;
                          }),
                        ),
                      ],
                      // ── Cascade harga EUP → prog → store → PB ────────
                      if (unitEup > 0) ...[
                        const SizedBox(height: AppLayoutTokens.space12),
                        Builder(builder: (context) {
                          final progs = _currentProgramDiscounts();
                          final eupAfterProg = _eupAfterProgram(unitEup);
                          final hasProgram = progs.isNotEmpty;
                          final hasPB = _programBulananType.isNotEmpty &&
                              _programBulananValue > 0;
                          final priceAfterPB =
                              hasPB ? _applyProgramBulanan(plBase) : plBase;
                          final productLabel = _nameCtrl.text.trim().isEmpty
                              ? 'Produk'
                              : _nameCtrl.text.trim();
                          // Label "setelah..." sesuai mode:
                          // - indirect + ada toko → "Setelah prog+toko"
                          // - lainnya (direct atau indirect tanpa toko) → "Setelah diskon prog."
                          final afterLabel = (isIndirectMode && useIndirectStoreNet)
                              ? 'Setelah prog+toko:  '
                              : 'Setelah diskon prog.:  ';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Jika ada program: tampilkan EUP asli → setelah prog
                              if (hasProgram) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        productLabel,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          AppFormatters.currencyIdr(unitEup),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textTertiary,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        Text(
                                          '${StoreDiscountCalculator.formatDisplay(progs)}  →  ${AppFormatters.currencyIdr(eupAfterProg)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Baris setelah prog + toko (label sesuai mode)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      afterLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.currencyIdr(plBase / _qty),
                                      style: TextStyle(
                                        fontSize: hasPB ? 12 : 14,
                                        fontWeight: hasPB
                                            ? FontWeight.w500
                                            : FontWeight.w800,
                                        color: hasPB
                                            ? AppColors.textTertiary
                                            : AppColors.textPrimary,
                                        decoration: hasPB
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Tanpa program discount.
                                // Strikethrough EUP hanya ditampilkan jika ada store
                                // discount yang benar-benar mengubah harga (indirect).
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        productLabel,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        // EUP coret hanya muncul bila ada diskon toko
                                        if (useIndirectStoreNet)
                                          Text(
                                            AppFormatters.currencyIdr(unitEup),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textTertiary,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                        Text(
                                          AppFormatters.currencyIdr(
                                              plBase / _qty),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            decoration: hasPB
                                                ? TextDecoration.lineThrough
                                                : null,
                                            color: hasPB
                                                ? AppColors.textTertiary
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                              // Baris Program Bulanan: harga setelah PB (bila aktif)
                              if (hasPB) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Setelah prog. bulanan:  ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.currencyIdr(
                                          priceAfterPB / _qty),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppLayoutTokens.space16),
              SectionCard(
                title: 'Harga Jual',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Toggle Harga 0 / Gratis ───────────────────────
                    _ToggleRow(
                      icon: Icons.money_off_csred_rounded,
                      iconColor: AppColors.warning,
                      title: 'Harga item ini: 0 (Gratis)',
                      subtitle: _isZeroPrice
                          ? 'Net price = 0 — tidak butuh diskon tambahan'
                          : 'Aktifkan jika harga ditanggung item lain',
                      value: _isZeroPrice,
                      onChanged: (v) => setState(() {
                        _isZeroPrice = v;
                        if (v) {
                          // Reset diskon tambahan & target total saat aktifkan
                          _appliedDiscounts = [];
                          targetTotalEup = null;
                          _targetTotalController.clear();
                        }
                      }),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: AppLayoutTokens.space12),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),
                    // ── Tombol Diskon Tambahan (hidden bila harga 0) ──
                    if (!_isZeroPrice) ...[
                      Material(
                        color: _appliedDiscounts.isNotEmpty
                            ? AppColors.accent.withValues(alpha: 0.07)
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius10),
                        child: InkWell(
                          onTap: plBase > 0 && modalSnap != null
                              ? () => _openDiscountModal(channel, brand)
                              : null,
                          borderRadius:
                              BorderRadius.circular(AppLayoutTokens.radius10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppLayoutTokens.space12,
                              vertical: AppLayoutTokens.space12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        AppLayoutTokens.radius8),
                                  ),
                                  child: const Icon(
                                    Icons.local_offer_outlined,
                                    color: AppColors.accent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppLayoutTokens.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Diskon Tambahan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _appliedDiscounts.isEmpty
                                            ? 'Ketuk untuk tambah diskon'
                                            : _appliedDiscounts
                                                .where((d) => d > 0)
                                                .map((d) =>
                                                    DiscountFormatter
                                                        .percentLabel(d * 100))
                                                .join(' + '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _appliedDiscounts.isNotEmpty
                                              ? AppColors.accent
                                              : AppColors.textTertiary,
                                          fontWeight:
                                              _appliedDiscounts.isNotEmpty
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: plBase > 0
                                      ? AppColors.accent
                                      : AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space12),
                    ],
                    // ── Total akhir ───────────────────────────────────
                    // Mode harga 0: tampilkan badge locked "Rp 0"
                    // Mode normal: field editable
                    if (_isZeroPrice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppLayoutTokens.space14,
                          horizontal: AppLayoutTokens.space16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.06),
                          borderRadius:
                              BorderRadius.circular(AppLayoutTokens.radius10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppLayoutTokens.space8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total akhir',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Rp 0',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Terkunci',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppLayoutTokens.space14,
                          horizontal: AppLayoutTokens.space16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.04),
                          borderRadius:
                              BorderRadius.circular(AppLayoutTokens.radius10),
                          border: Border.all(
                            color: _totalFocusNode.hasFocus
                                ? AppColors.accent
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total akhir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Rp',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppLayoutTokens.space10),
                            Expanded(
                              child: TextField(
                                controller: _targetTotalController,
                                focusNode: _totalFocusNode,
                                keyboardType: TextInputType.number,
                                enabled: plBase > 0 && modalSnap != null,
                                inputFormatters: [
                                  ThousandsSeparatorInputFormatter(
                                    format: (v) =>
                                        _totalCurrencyFormat.format(v).trim(),
                                  ),
                                ],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                  letterSpacing: -0.5,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                onChanged: (s) {
                                  if (modalSnap != null) {
                                    _onTargetTotalChangedRaw(
                                        s, modalSnap, plBase);
                                  }
                                },
                              ),
                            ),
                            if (targetTotalEup != null) ...[
                              const SizedBox(width: AppLayoutTokens.space8),
                              GestureDetector(
                                onTap: plBase > 0
                                    ? () => _resetDiscounts(plBase)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.divider,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space16),
              SectionCard(
                title: 'Bonus',
                child: Material(
                  color: _customBonuses.isNotEmpty
                      ? AppColors.success.withValues(alpha: 0.05)
                      : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(AppLayoutTokens.radius10),
                  child: InkWell(
                    onTap: () {
                      showBonusEditorModal(
                        context,
                        defaultBonuses: const [],
                        isBonusCustomized: _bonusCustomized,
                        customBonuses: _customBonuses,
                        onSave: (next) {
                          setState(() {
                            _customBonuses =
                                List<Map<String, dynamic>>.from(next);
                            _bonusCustomized = _customBonuses.isNotEmpty;
                          });
                        },
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(AppLayoutTokens.radius10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppLayoutTokens.space12,
                        vertical: AppLayoutTokens.space12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppLayoutTokens.radius8),
                            ),
                            child: const Icon(
                              Icons.card_giftcard_outlined,
                              color: AppColors.success,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: AppLayoutTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bonus Spesial',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _customBonuses.isEmpty
                                      ? 'Belum ada bonus — ketuk untuk tambahkan'
                                      : '${_customBonuses.length} bonus dipilih',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _customBonuses.isNotEmpty
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                                    fontWeight: _customBonuses.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppLayoutTokens.space16),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final PricelistCustomComponentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayoutTokens.space12,
          vertical: AppLayoutTokens.space10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius10),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.surface.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                type.icon,
                size: 14,
                color: selected ? AppColors.surface : AppColors.accent,
              ),
            ),
            const SizedBox(width: AppLayoutTokens.space8),
            Expanded(
              child: Text(
                type.shortLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.surface
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  size: 15, color: AppColors.surface),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppLayoutTokens.radius8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: AppLayoutTokens.space10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                ),
            ],
          ),
        ),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
