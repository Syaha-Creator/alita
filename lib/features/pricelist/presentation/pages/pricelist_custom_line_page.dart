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
import '../../../../core/widgets/action_button_bar.dart';
import '../../../../core/widgets/app_choice_chip.dart';
import '../../../../core/widgets/checkout_input_decoration.dart';
import '../../../../core/widgets/form_field_label.dart';
import '../../../../core/widgets/label_value_row.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../cart/data/cart_indirect_meta.dart';
import '../../../cart/data/cart_item.dart';
import '../../../cart/logic/cart_provider.dart';
import '../../../indirect/logic/indirect_session_provider.dart';
import '../../../indirect/logic/sales_mode_provider.dart';
import '../../data/models/pricelist_custom_line.dart';
import '../../data/models/product.dart';
import '../../logic/pricelist_custom_line_builder.dart';
import '../../logic/product_detail_utils.dart';
import '../../logic/product_provider.dart';
import '../widgets/bonus_editor_modal.dart';
import '../widgets/discount_modal.dart';

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
      final pl = switch (t ?? PricelistCustomComponentType.mattress) {
        PricelistCustomComponentType.mattress => p.plKasur,
        PricelistCustomComponentType.divan => p.plDivan,
        PricelistCustomComponentType.headboard => p.plHeadboard,
        PricelistCustomComponentType.sorong => p.plSorong,
      };
      // eupKasur di snapshot menyimpan EUP SETELAH diskon program diterapkan.
      // Untuk menampilkan EUP asli di field, kita reverse-cascade menggunakan
      // string `p.program` yang menyimpan persentase diskon program.
      final eupAfterProg = switch (t ?? PricelistCustomComponentType.mattress) {
        PricelistCustomComponentType.mattress => p.eupKasur,
        PricelistCustomComponentType.divan => p.eupDivan,
        PricelistCustomComponentType.headboard => p.eupHeadboard,
        PricelistCustomComponentType.sorong => p.eupSorong,
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
          return CartBonusSnapshot(name: name, qty: qty, sku: sku);
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

  /// Daftar persentase program diskon yang diisi user (non-zero).
  List<double> _currentProgramDiscounts() {
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

  Product _snapshotForDiscountModal(String channel, String brand) {
    final pl = _parseMoney(_plCtrl);
    final eu = _parseMoney(_eupCtrl);
    // Modal memakai EUP-setelah-program sebagai basis sehingga limit diskon
    // penjualan dihitung terhadap harga yang sudah dipotong program.
    final eupForModal = _eupAfterProgram(eu > 0 ? eu : 1);
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

  /// Dasar diskon penjualan: EUP → diskon program → diskon toko (indirect).
  ///
  /// Urutan cascade:
  ///   1. `unitEup` (EUP asli — input user)
  ///   2. Diskon Program (indirect, bila ada)
  ///   3. Diskon Toko (indirect, bila ada)
  double _plDiscountBaseTotal(
    double unitEup,
    List<double> storeDiscounts,
    bool indirect,
  ) {
    if (unitEup <= 0) return 0;
    var base = unitEup;
    if (indirect) {
      // Terapkan diskon program terlebih dahulu.
      final progs = _currentProgramDiscounts();
      if (progs.isNotEmpty) {
        base = StoreDiscountCalculator.cascade(base, progs);
      }
      // Kemudian terapkan diskon toko.
      if (storeDiscounts.isNotEmpty) {
        base = StoreDiscountCalculator.cascade(base, storeDiscounts);
      }
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
    final brand = ref.read(selectedBrandProvider);
    final channel = ref.read(selectedChannelProvider);
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
    final eu = _parseMoney(_eupCtrl);

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
    if (eu <= 0) {
      AppFeedback.show(
        context,
        message: 'EUP harus lebih dari 0.',
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
      indirectMeta = CartIndirectMeta(
        addressNumber: store.addressNumber,
        alphaName: StoreDisplayUtils.assignedStoreRowLabel(
          alphaName: store.alphaName,
          catcode27: store.catcode27,
        ),
        address: store.address,
        phone: '',
        storeDiscounts: List<double>.from(session.storeDiscounts),
        discountDisplay: session.storeDiscounts.isNotEmpty
            ? StoreDiscountCalculator.formatDisplay(session.storeDiscounts)
            : session.discountDisplay,
      );
    }

    final lineId = widget.editItem != null
        ? widget.editItem!.product.id
        : PricelistCustomLineBuilder.newCartLineId();

    // EUP yang disimpan ke snapshot adalah EUP SETELAH diskon program,
    // agar cascade diskon toko + penjualan di checkout terhitung benar.
    final eupForSnapshot = _eupAfterProgram(eu);
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

    var cartItem = PricelistCustomLineBuilder.buildCartItem(
      productSnapshot: snapshot,
      quantity: _qty,
      appliedDiscountFractions: _appliedDiscounts,
      indirectMeta: indirectMeta,
      bonusSnapshots: _bonusSnapshotsForCart(),
      pricelistArea: ref.read(effectiveAreaProvider),
      isBonusCustomized: _bonusCustomized,
    );

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
    final eu = _parseMoney(_eupCtrl);
    if (eu <= 0) {
      AppFeedback.show(
        context,
        message: 'Isi EUP terlebih dahulu untuk dasar perhitungan diskon.',
        type: AppFeedbackType.warning,
        floating: true,
      );
      return;
    }
    final snap = _snapshotForDiscountModal(channel, brand);
    final session = ref.read(indirectSessionProvider);
    final indirect = ref.read(salesModeProvider) == SalesMode.indirect;
    final storeDiscounts = indirect && session.hasDiscounts
        ? session.storeDiscounts
        : const <double>[];
    final plBase = _plDiscountBaseTotal(eu, storeDiscounts, indirect);

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
    final brand = ref.watch(selectedBrandProvider);
    final channel = ref.watch(selectedChannelProvider);
    final salesMode = ref.watch(salesModeProvider);
    final indirectSession = ref.watch(indirectSessionProvider);
    final storeDiscounts =
        salesMode == SalesMode.indirect && indirectSession.hasDiscounts
            ? indirectSession.storeDiscounts
            : const <double>[];

    final unitEup =
        brand != null && channel != null ? _parseMoney(_eupCtrl) : 0.0;
    final useIndirectStoreNet =
        salesMode == SalesMode.indirect && storeDiscounts.isNotEmpty;
    final plBase =
        _plDiscountBaseTotal(unitEup, storeDiscounts, useIndirectStoreNet);

    final modalSnap = brand != null && channel != null
        ? _snapshotForDiscountModal(channel, brand)
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

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.editItem != null
              ? 'Ubah baris custom'
              : 'Baris custom pricelist',
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppLayoutTokens.space16,
            AppLayoutTokens.space8,
            AppLayoutTokens.space16,
            AppLayoutTokens.space20 + bottomInset,
          ),
          children: [
            if (brand == null || channel == null)
              SectionCard(
                title: 'Filter',
                child: Text(
                  'Channel atau brand belum dipilih. Buka beranda dan lengkapi filter terlebih dahulu.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else ...[
              SectionCard(
                title: 'Konteks filter',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LabelValueRow(
                      label: 'Brand',
                      value: brand,
                      labelStyle:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                      valueStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space8),
                    LabelValueRow(
                      label: 'Channel',
                      value: channel,
                      labelStyle:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                      valueStyle:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space16),
              SectionCard(
                title: 'Detail barang',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const FormFieldLabel('Nama produk'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: CheckoutInputDecoration.form(
                        hintText: 'Contoh: Comforta Super Fit',
                      ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    const FormFieldLabel('Ukuran (desc 2)'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    TextField(
                      controller: _ukuranCtrl,
                      decoration: CheckoutInputDecoration.form(
                        hintText: 'Contoh: 160 × 200',
                      ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    const FormFieldLabel('Jenis baris (checkout)'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    Wrap(
                      spacing: AppLayoutTokens.space8,
                      runSpacing: AppLayoutTokens.space8,
                      children: PricelistCustomComponentType.values.map((t) {
                        return AppChoiceChip(
                          label: t.shortLabel,
                          selected: _type == t,
                          onSelected: (_) => setState(() {
                            _type = t;
                            targetTotalEup = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    const FormFieldLabel('Harga pricelist (per unit)'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    TextField(
                      controller: _plCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: CheckoutInputDecoration.form(
                        hintText: '0',
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    const FormFieldLabel('Harga Customer'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    TextField(
                      controller: _eupCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      decoration: CheckoutInputDecoration.form(
                        hintText: '0',
                        prefixText: 'Rp ',
                      ),
                      onChanged: (_) => setState(() {
                        targetTotalEup = null;
                      }),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    const FormFieldLabel('Kuantitas'),
                    const SizedBox(height: AppLayoutTokens.space8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: QuantityStepper(
                        quantity: _qty,
                        onDecrement: () {
                          if (_qty > 1) setState(() => _qty--);
                        },
                        onIncrement: () => setState(() => _qty++),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Rincian Harga (hanya indirect dengan store discounts) ──
              // Berisi: input diskon program (opsional) + info diskon toko +
              // cascade harga EUP → setelah prog → setelah toko.
              if (useIndirectStoreNet) ...[
                const SizedBox(height: AppLayoutTokens.space16),
                SectionCard(
                  title: 'Rincian Harga',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Input Diskon Program ──────────────────────────
                      const FormFieldLabel('Diskon Program (opsional)'),
                      const SizedBox(height: 4),
                      Text(
                        'Diterapkan sebelum diskon toko. Kosongkan jika tidak ada.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                              height: 1.3,
                            ),
                      ),
                      const SizedBox(height: AppLayoutTokens.space8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _prog1Ctrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: CheckoutInputDecoration.form(
                                hintText: '0',
                                labelText: 'Tingkat 1',
                                suffixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
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
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: CheckoutInputDecoration.form(
                                hintText: '0',
                                labelText: 'Tingkat 2',
                                suffixIcon: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
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
                      const SizedBox(height: AppLayoutTokens.space16),
                      // ── Info Diskon Toko ──────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppLayoutTokens.space12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppLayoutTokens.radius10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diskon Toko',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: AppLayoutTokens.space6),
                            Text(
                              StoreDiscountCalculator.formatDisplay(
                                  storeDiscounts),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // ── Cascade harga EUP → prog → store ─────────────
                      if (unitEup > 0) ...[
                        const SizedBox(height: AppLayoutTokens.space12),
                        Builder(builder: (context) {
                          final progs = _currentProgramDiscounts();
                          final eupAfterProg = _eupAfterProgram(unitEup);
                          final hasProgram = progs.isNotEmpty;
                          final productLabel = _nameCtrl.text.trim().isEmpty
                              ? 'Produk'
                              : _nameCtrl.text.trim();
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
                                // Baris final: setelah prog + toko
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Setelah prog+toko:  ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    Text(
                                      AppFormatters.currencyIdr(plBase / _qty),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Tanpa program: tampilan asli (EUP coret → setelah toko)
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
                                          AppFormatters.currencyIdr(
                                              plBase / _qty),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
                title: 'Diskon penjualan',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Diskon tambahan & total jual mengikuti halaman detail produk: '
                      'atur persentase/nominal per tingkat, atau edit total akhir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space12),
                    Material(
                      color: AppColors.accent.withValues(alpha: 0.05),
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
                            vertical: AppLayoutTokens.space10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color: AppColors.accent,
                                size: 22,
                              ),
                              const SizedBox(width: AppLayoutTokens.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Diskon tambahan',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _appliedDiscounts.isEmpty
                                          ? 'Belum ada diskon diterapkan'
                                          : _appliedDiscounts
                                              .where((d) => d > 0)
                                              .map(
                                                (d) => DiscountFormatter
                                                    .percentLabel(
                                                  d * 100,
                                                ),
                                              )
                                              .join(' + '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppLayoutTokens.space12,
                        horizontal: AppLayoutTokens.space16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppLayoutTokens.radius10),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Total akhir',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: AppLayoutTokens.space12),
                          const Text(
                            'Rp ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
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
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.w700,
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
                          if (targetTotalEup != null)
                            Tooltip(
                              message: 'Hapus semua diskon tambahan',
                              child: GestureDetector(
                                onTap: plBase > 0
                                    ? () => _resetDiscounts(plBase)
                                    : null,
                                child: const Icon(
                                  Icons.refresh,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppLayoutTokens.space16),
              SectionCard(
                title: 'Bonus spesial',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tambah bonus dari daftar aksesori (sama seperti di halaman detail produk). '
                      'Bonus ikut ke keranjang & checkout.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: AppLayoutTokens.space12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _customBonuses.isEmpty
                                ? 'Belum ada bonus'
                                : '${_customBonuses.length} bonus dipilih',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
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
                          icon: const Icon(Icons.card_giftcard_outlined,
                              size: 20),
                          label: const Text('Atur bonus'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppLayoutTokens.space20),
            ActionButtonBar(
              primaryLabel: widget.editItem != null
                  ? 'Simpan perubahan'
                  : 'Tambah ke keranjang',
              onPrimaryPressed:
                  (brand == null || channel == null) ? null : () => _submit(),
              secondaryLabel: 'Batal',
              onSecondaryPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
