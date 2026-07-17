import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/store_discount_calculator.dart';
import '../../pricelist/data/models/pricelist_custom_line.dart';
import '../../pricelist/data/models/product.dart';
import '../../pricelist/logic/product_detail_utils.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

List<double> _parseDoubleList(dynamic value) {
  if (value == null) return [];
  if (value is! List) return [];
  return value.map((e) => _parseDouble(e)).toList();
}

bool _parseBoolDefaultFalse(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().toLowerCase();
  return s == 'true' || s == '1';
}

@freezed
class CartBonusSnapshot with _$CartBonusSnapshot {
  const factory CartBonusSnapshot({
    @Default('') String name,
    @JsonKey(fromJson: _parseInt) @Default(0) int qty,
    @Default('') String sku,
    /// Pricelist harga aksesori/bonus (dari pl_accessories atau plBonus1..8).
    /// Digunakan sebagai fallback di checkout jika BonusPriceResolver tidak menemukan.
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double plPrice,
  }) = _CartBonusSnapshot;

  factory CartBonusSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CartBonusSnapshotFromJson(json);
}

@freezed
class CartItem with _$CartItem {
  const CartItem._();

  /// SKU sentinel untuk opsi custom di konfigurator (sama string di [CartItemBuilder]).
  static const customItemSku = 'CUSTOM';

  /// True jika baris ini dari mode indirect (toko assign + diskon toko API).
  bool get isIndirectSale =>
      indirectStoreAddressNumber != null && indirectStoreAddressNumber! > 0;

  /// Voucher FOC 100% hanya untuk indirect; di direct flag disembunyikan & diabaikan.
  bool get isFocVoucherActive => isIndirectSale && isFocVoucher;

  /// True jika program bulanan diisi dengan nilai valid.
  bool get hasProgramBulanan =>
      programBulananType.isNotEmpty &&
      (programBulananType == 'percent'
          ? programBulananDiscount > 0
          : programBulananNominal > 0);

  const factory CartItem({
    required Product product,
    Product? masterProduct,
    @JsonKey(fromJson: _parseInt) @Default(1) int quantity,
    @Default('') String kasurSku,
    @Default('') String divanSku,
    @Default('') String sandaranSku,
    @Default('') String sorongSku,
    @Default('') String divanKain,
    @Default('') String divanWarna,
    @Default('') String sandaranKain,
    @Default('') String sandaranWarna,
    @Default('') String sorongKain,
    @Default('') String sorongWarna,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupKasur,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupDivan,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupHeadboard,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double originalEupSorong,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount1,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount2,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount3,
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double discount4,
    @Default(<CartBonusSnapshot>[]) List<CartBonusSnapshot> bonusSnapshots,
    /// Indirect: `address_number` toko (kunci merge baris + diskon).
    @JsonKey(fromJson: _parseIntNullable) int? indirectStoreAddressNumber,
    @Default('') String indirectStoreAlphaName,
    @Default('') String indirectStoreAddress,
    @Default('') String indirectStorePhone,
    @JsonKey(fromJson: _parseDoubleList)
    @Default(<double>[])
    List<double> indirectStoreDiscounts,
    @Default('') String indirectStoreDiscountDisplay,
    /// Kode diskon toko dari API (`disc_name`), dikirim sebagai `code_standart`
    /// di baris `order_letter_discounts` indirect. Hanya relevan jika [isIndirectSale].
    @Default('') String indirectStoreDiscountCode,
    /// Voucher FOC 100%: total baris di keranjang = 0; order letter memakai
    /// harga customer = pricelist & net = 0 + baris diskon bertanda FOC.
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isFocVoucher,
    /// Snapshot area pricelist saat item ditambahkan ke keranjang (untuk field
    /// `pricelist_area` di `order_letter_details`).
    @Default('') String pricelistArea,
    /// True jika bonus item telah diubah dari bundle default produk (via "Tukar Bonus").
    /// Ketika true, approval RSM wajib dipilih meskipun tidak ada diskon penjualan
    /// tambahan — untuk validasi checkout.
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isBonusCustomized,
    /// True jika ukuran item dipilih sebagai "Custom" (bukan dari list ukuran baku).
    /// Untuk indirect, wajib pilih ASM approval di checkout.
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isCustomSize,
    /// True jika toko tujuan indirect ditandai sebagai customer baru oleh API (search_type).
    /// Order ke customer baru wajib mendapat persetujuan ASM meskipun tanpa diskon tambahan.
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isNewCustomerStore,
    /// Nilai asli `search_type` toko assign — dikirim sebagai `customer_type` di order_letters.
    @Default('') String indirectCustomerType,

    // ── Program Bulanan (indirect only) ──────────────────────────────────────
    /// Tipe diskon program bulanan: '' = tidak diisi, 'percent' = %, 'nominal' = Rp.
    @Default('') String programBulananType,
    /// Nilai persentase program bulanan (0–100). Hanya relevan jika [programBulananType] == 'percent'.
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double programBulananDiscount,
    /// Nilai nominal program bulanan dalam Rp. Hanya relevan jika [programBulananType] == 'nominal'.
    @JsonKey(fromJson: _parseDouble) @Default(0.0) double programBulananNominal,

    // ── Harga 0 (custom pricelist) ────────────────────────────────────────────
    /// Bila true, item ini dihitung dengan net_price = 0 tanpa diskon tambahan.
    /// Dipakai untuk item komponen yang harganya ditanggung oleh item lain dalam
    /// satu bundle / paket toko (bukan FOC, bukan Bonus).
    @JsonKey(fromJson: _parseBoolDefaultFalse) @Default(false) bool isZeroPrice,
  }) = _CartItem;

  /// EUP per unit setelah diskon toko (indirect) lalu diskon sales (bertingkat),
  /// lalu Program Bulanan (jika ada). Untuk baris pricelist custom, dipakai
  /// sebagai harga tampilan & subtotal keranjang.
  double get effectiveUnitSellingPrice {
    if (isFocVoucherActive || isZeroPrice) return 0;
    final p = product;
    final unitEup = p.eupKasur +
        p.eupDivan +
        p.eupHeadboard +
        p.eupSorong;
    if (unitEup <= 0) return unitPriceAfterProgramBulanan(p.price);

    var base = unitEup;
    if (isIndirectSale && indirectStoreDiscounts.isNotEmpty) {
      base = StoreDiscountCalculator.cascade(base, indirectStoreDiscounts);
    }

    final fractions = <double>[
      discount1 / 100,
      discount2 / 100,
      discount3 / 100,
      discount4 / 100,
    ];
    final afterSales =
        ProductDetailUtils.calculateCascadingPrice(base, fractions);
    return unitPriceAfterProgramBulanan(afterSales);
  }

  /// Harga per unit untuk tampilan: [base] dikurangi Program Bulanan bila aktif.
  ///
  /// Snapshot lama sempat bake PB ke [product.price]; deteksi itu supaya tidak
  /// potong dua kali di UI.
  double unitPriceAfterProgramBulanan(double base) {
    if (!isIndirectSale || !hasProgramBulanan) return base;

    final eupSum = product.eupKasur +
        product.eupDivan +
        product.eupHeadboard +
        product.eupSorong;
    if (eupSum > 0) {
      final legacyPostPb = _applyProgramBulananTo(eupSum);
      // Legacy cart: price sudah post-PB (selisih ≈ potongan PB dari eup*).
      if ((base - legacyPostPb).abs() <= 1.0) return base;
    }

    return _applyProgramBulananTo(base);
  }

  double _applyProgramBulananTo(double base) {
    if (programBulananType == 'percent' && programBulananDiscount > 0) {
      return (base * (1 - programBulananDiscount / 100))
          .clamp(0, double.infinity);
    }
    if (programBulananType == 'nominal' && programBulananNominal > 0) {
      return (base - programBulananNominal).clamp(0, double.infinity);
    }
    return base;
  }

  double get totalPrice {
    if (isFocVoucherActive || isZeroPrice) return 0.0;
    if (product.isPricelistCustomCartLine) {
      return quantity * effectiveUnitSellingPrice;
    }
    return quantity * unitPriceAfterProgramBulanan(product.price);
  }

  /// Human-friendly name for display in cart / checkout.
  ///
  /// If the product has no kasur ("Tanpa Kasur"), shows the first
  /// present component name (divan / headboard / sorong) + size.
  String get displayName {
    final p = product;
    if (_isPresent(p.kasur)) return p.name;

    String withSize(String base) {
      if (p.ukuran.isEmpty) return base;
      if (base.toLowerCase().contains(p.ukuran.toLowerCase())) return base;
      return '$base ${p.ukuran}';
    }

    if (_isPresent(p.divan)) return withSize(p.divan);
    if (_isPresent(p.headboard)) return withSize(p.headboard);
    if (_isPresent(p.sorong)) return withSize(p.sorong);
    return p.name;
  }

  static bool _isPresent(String field) {
    final v = field.trim().toLowerCase();
    return v.isNotEmpty && !v.startsWith('tanpa');
  }

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
