import '../../cart/data/cart_indirect_meta.dart';
import '../../cart/data/cart_item.dart';
import '../data/models/pricelist_custom_line.dart';
import '../data/models/product.dart';

/// Membangun [Product] placeholder grid dan snapshot [CartItem] untuk baris custom.
class PricelistCustomLineBuilder {
  PricelistCustomLineBuilder._();

  static const _tanpaDivan = 'Tanpa Divan';
  static const _tanpaHb = 'Tanpa Headboard';
  static const _tanpaSr = 'Tanpa Sorong';
  static const _tanpaKasur = 'Tanpa Kasur';

  static String newCartLineId() =>
      '$kPricelistCustomCartLineIdPrefix${DateTime.now().microsecondsSinceEpoch}';

  static Product buildGridPlaceholder({
    required String brand,
    required String channel,
  }) {
    return Product(
      id: kPricelistCustomPlaceholderProductId,
      name: 'Baris custom pricelist',
      price: 0,
      imageUrl: '',
      category: 'Tanpa SKU',
      description:
          'Isi nama, ukuran, tipe baris, harga pricelist, dan EUP. '
          'Brand mengikuti filter yang aktif.',
      channel: channel,
      brand: brand,
      program: '-',
      kasur: '',
      ukuran: '',
      divan: _tanpaDivan,
      headboard: _tanpaHb,
      sorong: _tanpaSr,
      isSet: false,
      pricelist: 0,
      eupKasur: 0,
      eupDivan: 0,
      eupHeadboard: 0,
      eupSorong: 0,
      plKasur: 0,
      plDivan: 0,
      plHeadboard: 0,
      plSorong: 0,
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
  }

  /// Prefix untuk category field di Product snapshot custom.
  static const _customCategoryPrefix = 'custom_type:';

  /// Kembalikan string category yang meng-encode jenis baris custom.
  static String categoryForType(PricelistCustomComponentType type) =>
      '$_customCategoryPrefix${type.name}';

  /// Inferensi tipe dari snapshot produk custom (untuk mode edit).
  ///
  /// Prioritas:
  /// 1. Category field (format `custom_type:<enum.name>`) — dipakai untuk semua
  ///    tipe termasuk yang baru (protector/aksesori/sprei/lainnya).
  /// 2. Fallback: deteksi dari struktur kasur/divan/headboard/sorong
  ///    (kompatibilitas mundur untuk snapshot lama).
  static PricelistCustomComponentType? componentTypeFromProduct(Product p) {
    // 1. Decode dari category field
    if (p.category.startsWith(_customCategoryPrefix)) {
      final name = p.category.substring(_customCategoryPrefix.length);
      try {
        return PricelistCustomComponentType.values
            .firstWhere((e) => e.name == name);
      } catch (_) {
        // name tidak dikenali — lanjut ke fallback
      }
    }

    // 2. Fallback: deteksi dari struktur product (snapshot lama)
    bool present(String s) {
      final v = s.trim().toLowerCase();
      return v.isNotEmpty && !v.startsWith('tanpa');
    }

    if (!p.isSet && present(p.kasur)) {
      return PricelistCustomComponentType.mattress;
    }
    if (p.isSet) {
      if (present(p.divan)) return PricelistCustomComponentType.divan;
      if (present(p.headboard)) return PricelistCustomComponentType.headboard;
      if (present(p.sorong)) return PricelistCustomComponentType.sorong;
    }
    return null;
  }

  static Product buildProductSnapshot({
    required String lineId,
    required String productName,
    required String ukuran,
    required String brand,
    required String channel,
    required PricelistCustomComponentType type,
    required double unitPricelist,
    required double unitEup,
    // Label program diskon (e.g. "10%+5%"). Hanya untuk API `discount_program`.
    // `unitEup` yang diteruskan sudah merupakan EUP SETELAH diskon program.
    String? program,
  }) {
    final trimmedName = productName.trim();
    final trimmedSize = ukuran.trim();

    var kasur = '';
    var divan = _tanpaDivan;
    var headboard = _tanpaHb;
    var sorong = _tanpaSr;
    var isSet = false;
    var plK = 0.0;
    var plD = 0.0;
    var plH = 0.0;
    var plS = 0.0;
    var euK = 0.0;
    var euD = 0.0;
    var euH = 0.0;
    var euS = 0.0;

    if (type == PricelistCustomComponentType.mattress) {
      kasur = trimmedName;
      isSet = false;
      plK = unitPricelist;
      euK = unitEup;
    } else if (type == PricelistCustomComponentType.divan) {
      kasur = _tanpaKasur;
      divan = trimmedName;
      isSet = true;
      plD = unitPricelist;
      euD = unitEup;
    } else if (type == PricelistCustomComponentType.headboard) {
      kasur = _tanpaKasur;
      divan = _tanpaDivan;
      headboard = trimmedName;
      sorong = _tanpaSr;
      isSet = true;
      plH = unitPricelist;
      euH = unitEup;
    } else if (type == PricelistCustomComponentType.sorong) {
      kasur = _tanpaKasur;
      divan = _tanpaDivan;
      headboard = _tanpaHb;
      sorong = trimmedName;
      isSet = true;
      plS = unitPricelist;
      euS = unitEup;
    } else {
      // Tipe non-bundle (protector/aksesori/sprei/lainnya) — simpan di kasur,
      // isSet=false supaya tidak muncul sebagai bundle component di UI.
      kasur = trimmedName;
      isSet = false;
      plK = unitPricelist;
      euK = unitEup;
    }

    final totalPl = plK + plD + plH + plS;
    final totalEup = euK + euD + euH + euS;

    return Product(
      id: lineId,
      name: trimmedName,
      price: totalEup,
      imageUrl: '',
      // category di-encode sebagai 'custom_type:<enum.name>' agar tipe bisa
      // dibaca kembali saat edit tanpa bergantung pada struktur product field.
      category: categoryForType(type),
      description:
          '[Custom · ${type.shortLabel}] $trimmedName · $trimmedSize · $brand',
      channel: channel,
      brand: brand,
      program: (program != null && program.isNotEmpty) ? program : '-',
      kasur: kasur,
      ukuran: trimmedSize,
      divan: divan,
      headboard: headboard,
      sorong: sorong,
      isSet: isSet,
      pricelist: totalPl,
      eupKasur: euK,
      eupDivan: euD,
      eupHeadboard: euH,
      eupSorong: euS,
      plKasur: plK,
      plDivan: plD,
      plHeadboard: plH,
      plSorong: plS,
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
  }

  static List<double> _discountPercentsFromFractions(List<double> fractions) {
    double pct(int i) =>
        fractions.length > i ? (fractions[i] * 100).clamp(0.0, 100.0) : 0.0;
    return [pct(0), pct(1), pct(2), pct(3)];
  }

  static CartItem buildCartItem({
    required Product productSnapshot,
    required int quantity,
    required List<double> appliedDiscountFractions,
    CartIndirectMeta? indirectMeta,
    List<CartBonusSnapshot> bonusSnapshots = const [],
    String pricelistArea = '',
    bool isBonusCustomized = false,
  }) {
    final d = _discountPercentsFromFractions(appliedDiscountFractions);

    return CartItem(
      product: productSnapshot,
      masterProduct: null,
      quantity: quantity,
      kasurSku: '',
      divanSku: '',
      sandaranSku: '',
      sorongSku: '',
      originalEupKasur: productSnapshot.eupKasur,
      originalEupDivan: productSnapshot.eupDivan,
      originalEupHeadboard: productSnapshot.eupHeadboard,
      originalEupSorong: productSnapshot.eupSorong,
      discount1: d[0],
      discount2: d[1],
      discount3: d[2],
      discount4: d[3],
      bonusSnapshots: bonusSnapshots,
      isBonusCustomized: isBonusCustomized,
      indirectStoreAddressNumber: indirectMeta?.addressNumber,
      indirectStoreAlphaName: indirectMeta?.alphaName ?? '',
      indirectStoreAddress: indirectMeta?.address ?? '',
      indirectStorePhone: indirectMeta?.phone ?? '',
      indirectStoreDiscounts: indirectMeta?.storeDiscounts ?? const [],
      indirectStoreDiscountDisplay: indirectMeta?.discountDisplay ?? '',
      indirectStoreDiscountCode: indirectMeta?.discountCode ?? '',
      isNewCustomerStore: indirectMeta?.isNewCustomer ?? false,
      pricelistArea: pricelistArea,
    );
  }
}
