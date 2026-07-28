import '../../cart/data/cart_item.dart';
import '../../indirect/data/models/assigned_store.dart';
import '../../pricelist/data/models/pricelist_custom_line.dart';
import '../../pricelist/data/models/product.dart';
import '../data/models/order_history.dart';

/// Mengkonversi [OrderHistory.details] kembali ke [CartItem] untuk pre-load
/// keranjang saat user memulai "Edit Item Pesanan".
///
/// ## Strategi: satu CartItem per baris non-bonus
/// Setiap `order_letter_detail` non-bonus menjadi CartItem tersendiri.
/// Bonus rows dilampirkan ke CartItem non-bonus sebelumnya.
///
/// Produk diberi prefix [kPricelistCustomCartLineIdPrefix] sehingga saat di-tap
/// di keranjang, app membuka halaman `pricelist_custom_line` untuk editing,
/// bukan product detail yang memerlukan produk dari katalog.
///
/// ## Harga
/// Harga yang dipakai adalah harga tersimpan di `order_letter_details`.
///
/// ## Diskon
/// - Direct: User(L1) → disc1, SPV(L2) → disc2, RSM(L3) → disc3, Analyst(L4) → disc4.
/// - Indirect: RSM rows (dalam urutan) → disc1, disc2, disc3;
///   "Diskon Toko" rows → [indirectStoreDiscounts].
abstract final class OrderDetailCartPreloader {
  OrderDetailCartPreloader._();

  static const _divanType = 'divan';
  static const _headboardType = 'headboard';
  static const _sorongType = 'sorong';
  static const _bonusType = 'bonus';

  /// Konversi details menjadi list [CartItem].
  static List<CartItem> convert(OrderHistory order) {
    final details = order.details;
    if (details.isEmpty) return [];

    final isIndirect =
        (order.channel?.trim().toUpperCase() ?? '') == 'SO';

    // Passthrough: setiap non-bonus row → CartItem tersendiri.
    // Bonus rows dikumpulkan dan dilampirkan ke non-bonus terdekat sebelumnya.
    final result = <CartItem>[];
    final pendingBonuses = <OrderDetail>[];

    void flushBonusesToLast() {
      // Bonus di awal list (sebelum ada CartItem apa pun) tidak boleh dibuang
      // — tahan (jangan clear) sampai CartItem pertama benar-benar dibuat,
      // baru dilampirkan ke situ.
      if (pendingBonuses.isEmpty || result.isEmpty) {
        return;
      }
      final last = result.last;
      final qty = last.quantity;
      final newSnapshots = [
        ...last.bonusSnapshots,
        ...pendingBonuses.map((b) {
          final perUnit = qty > 0 ? b.qty ~/ qty : b.qty;
          return CartBonusSnapshot(
            name: b.itemDescription.isNotEmpty ? b.itemDescription : b.desc1,
            qty: perUnit > 0 ? perUnit : b.qty,
            sku: b.itemNumber.trim(),
          );
        }),
      ];
      // Rebuild last CartItem dengan bonus baru.
      result[result.length - 1] = last.copyWith(bonusSnapshots: newSnapshots);
      pendingBonuses.clear();
    }

    for (var i = 0; i < details.length; i++) {
      final d = details[i];
      final t = d.itemType.trim().toLowerCase();

      if (t == _bonusType) {
        pendingBonuses.add(d);
        continue;
      }

      // Non-bonus: flush pending bonus ke item sebelumnya, lalu buat CartItem baru.
      flushBonusesToLast();

      final item = _detailToCartItem(
        d,
        orderId: order.id,
        index: i,
        isIndirect: isIndirect,
        customerType: order.customerType,
      );
      if (item != null) {
        result.add(item);
        // Lampirkan bonus orphan yang tertahan (muncul sebelum CartItem
        // pertama ada) ke item baru ini.
        flushBonusesToLast();
      }
    }

    // Sisa bonus setelah loop (bonus di akhir list).
    flushBonusesToLast();

    return result;
  }

  static CartItem? _detailToCartItem(
    OrderDetail d, {
    required int orderId,
    required int index,
    required bool isIndirect,
    String customerType = '',
  }) {
    if (d.qty <= 0) return null;

    final t = d.itemType.trim().toLowerCase();
    final name = d.desc1.isNotEmpty ? d.desc1 : d.itemDescription;
    final ukuran = d.desc2.trim();
    final eup = d.customerPrice;
    final pl = d.unitPrice > 0 ? d.unitPrice : eup;
    final sku = d.itemNumber.trim();

    // ── Tipe komponen → tentukan field kasur/divan/headboard/sorong ──────
    final String kasur;
    final String divan;
    final String headboard;
    final String sorong;
    final bool isSet;
    final double eupKasur, eupDivan, eupHb, eupSorong;
    final double plKasur, plDivan, plHb, plSorong;
    final String kasurSku, divanSku, hbSku, sorongSku;

    switch (t) {
      case _divanType:
        kasur = 'Tanpa Kasur';
        divan = name;
        headboard = 'Tanpa Headboard';
        sorong = 'Tanpa Sorong';
        isSet = true;
        eupKasur = 0; eupDivan = eup; eupHb = 0; eupSorong = 0;
        plKasur = 0; plDivan = pl; plHb = 0; plSorong = 0;
        kasurSku = ''; divanSku = sku; hbSku = ''; sorongSku = '';
      case _headboardType:
        kasur = 'Tanpa Kasur';
        divan = 'Tanpa Divan';
        headboard = name;
        sorong = 'Tanpa Sorong';
        isSet = true;
        eupKasur = 0; eupDivan = 0; eupHb = eup; eupSorong = 0;
        plKasur = 0; plDivan = 0; plHb = pl; plSorong = 0;
        kasurSku = ''; divanSku = ''; hbSku = sku; sorongSku = '';
      case _sorongType:
        kasur = 'Tanpa Kasur';
        divan = 'Tanpa Divan';
        headboard = 'Tanpa Headboard';
        sorong = name;
        isSet = true;
        eupKasur = 0; eupDivan = 0; eupHb = 0; eupSorong = eup;
        plKasur = 0; plDivan = 0; plHb = 0; plSorong = pl;
        kasurSku = ''; divanSku = ''; hbSku = ''; sorongSku = sku;
      default:
        // Mattress atau tipe tidak dikenal → kasur standalone.
        kasur = name;
        divan = 'Tanpa Divan';
        headboard = 'Tanpa Headboard';
        sorong = 'Tanpa Sorong';
        isSet = false;
        eupKasur = eup; eupDivan = 0; eupHb = 0; eupSorong = 0;
        plKasur = pl; plDivan = 0; plHb = 0; plSorong = 0;
        kasurSku = sku; divanSku = ''; hbSku = ''; sorongSku = '';
    }

    // ── Diskon ──────────────────────────────────────────────────────────
    final discounts = _extractDiscounts(d.discounts, isIndirect: isIndirect);
    final storeDiscounts = _extractStoreDiscounts(d.discounts);
    final storeAlphaName = _extractStoreAlphaName(d.discounts);

    // ── Channel & Program ────────────────────────────────────────────────
    final channel = d.pricelistType.trim();
    final program = _extractDiscountProgram(d.discounts);

    // ── Produk sintetis (prefix custom agar cart membuka pricelist_custom_line) ─
    final productId = '$kPricelistCustomCartLineIdPrefix${orderId}_$index';

    final product = Product(
      id: productId,
      name: d.itemDescription.isNotEmpty ? d.itemDescription : name,
      price: eup,
      imageUrl: '',
      category: 'Custom pricelist',
      brand: d.brand,
      channel: channel,
      program: program.isNotEmpty ? program : '-',
      kasur: kasur,
      ukuran: ukuran,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      isSet: isSet,
      pricelist: pl,
      eupKasur: eupKasur,
      eupDivan: eupDivan,
      eupHeadboard: eupHb,
      eupSorong: eupSorong,
      plKasur: plKasur,
      plDivan: plDivan,
      plHeadboard: plHb,
      plSorong: plSorong,
      disc1: kPricelistCustomDisc1Max,
      disc2: kPricelistCustomDisc2Max,
      disc3: kPricelistCustomDisc3Max,
      disc4: kPricelistCustomDisc4Max,
      disc5: 0,
      disc6: 0,
      disc7: 0,
      disc8: 0,
      bottomPriceAnalyst: 0,
    );

    return CartItem(
      product: product,
      quantity: d.qty,
      kasurSku: kasurSku,
      divanSku: divanSku,
      sandaranSku: hbSku,
      sorongSku: sorongSku,
      originalEupKasur: eupKasur,
      originalEupDivan: eupDivan,
      originalEupHeadboard: eupHb,
      originalEupSorong: eupSorong,
      discount1: discounts.disc1,
      discount2: discounts.disc2,
      discount3: discounts.disc3,
      discount4: discounts.disc4,
      bonusSnapshots: const [],
      isBonusCustomized: false,
      isCustomSize: false,
      indirectStoreAddressNumber: isIndirect ? 1 : null,
      indirectStoreAlphaName: storeAlphaName,
      indirectStoreDiscounts: storeDiscounts,
      indirectStoreDiscountDisplay: '',
      pricelistArea: d.pricelistArea.trim(),
      isNewCustomerStore:
          isIndirect && AssignedStoreX.isNewCustomerSearchType(customerType),
      indirectCustomerType: isIndirect ? customerType.trim() : '',
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static _DiscExtract _extractDiscounts(
    List<OrderDiscount> rows, {
    required bool isIndirect,
  }) {
    double disc1 = 0, disc2 = 0, disc3 = 0, disc4 = 0;

    if (isIndirect) {
      final rsmRows = rows
          .where((r) =>
              r.approverLevel.toLowerCase().contains('rsm') ||
              r.approverLevel.toLowerCase().contains('manager'))
          .where((r) => _parseDiscountPct(r.discountVal) > 0)
          .toList();

      if (rsmRows.isNotEmpty) disc1 = _parseDiscountPct(rsmRows[0].discountVal);
      if (rsmRows.length > 1) disc2 = _parseDiscountPct(rsmRows[1].discountVal);
      if (rsmRows.length > 2) disc3 = _parseDiscountPct(rsmRows[2].discountVal);

      final analystRow = rows
          .where((r) => r.approverLevel.toLowerCase().contains('analyst'))
          .firstOrNull;
      if (analystRow != null) {
        disc4 = _parseDiscountPct(analystRow.discountVal);
      }
    } else {
      for (final r in rows) {
        final level = r.approverLevel.toLowerCase();
        final pct = _parseDiscountPct(r.discountVal);
        if (level == 'user' || level == 'sc') {
          disc1 = pct;
        } else if (level == 'spv' || level == 'supervisor') {
          disc2 = pct;
        } else if (level.contains('rsm') || level == 'manager') {
          disc3 = pct;
        } else if (level == 'analyst') {
          disc4 = pct;
        }
      }
    }

    return _DiscExtract(disc1: disc1, disc2: disc2, disc3: disc3, disc4: disc4);
  }

  static List<double> _extractStoreDiscounts(List<OrderDiscount> rows) {
    final result = <double>[];
    for (final r in rows) {
      if (r.approverLevel.toLowerCase().startsWith('diskon toko')) {
        final pct = _parseDiscountPct(r.discountVal);
        if (pct > 0) result.add(pct);
      }
    }
    return result;
  }

  static String _extractStoreAlphaName(List<OrderDiscount> rows) {
    for (final r in rows) {
      if (r.approverLevel.toLowerCase().startsWith('diskon toko')) {
        return r.approverName;
      }
    }
    return '';
  }

  static String _extractDiscountProgram(List<OrderDiscount> rows) {
    for (final r in rows) {
      final dp = r.discountProgram.trim();
      if (dp.isNotEmpty && dp != '-') return dp;
    }
    return '';
  }

  static double _parseDiscountPct(String val) =>
      double.tryParse(val.replaceAll('%', '').trim()) ?? 0.0;
}

// ── Internal types ─────────────────────────────────────────────

class _DiscExtract {
  const _DiscExtract({
    required this.disc1,
    required this.disc2,
    required this.disc3,
    required this.disc4,
  });
  final double disc1;
  final double disc2;
  final double disc3;
  final double disc4;
}
