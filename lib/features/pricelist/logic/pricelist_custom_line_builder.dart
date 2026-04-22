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

  /// Inferensi tipe dari snapshot produk custom (untuk mode edit).
  static PricelistCustomComponentType? componentTypeFromProduct(Product p) {
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
    }

    final totalPl = plK + plD + plH + plS;
    final totalEup = euK + euD + euH + euS;

    return Product(
      id: lineId,
      name: trimmedName,
      price: totalEup,
      imageUrl: '',
      category: 'Custom pricelist',
      description:
          '[Custom · ${type.shortLabel}] $trimmedName · $trimmedSize · $brand',
      channel: channel,
      brand: brand,
      program: '-',
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
      indirectStoreAddressNumber: indirectMeta?.addressNumber,
      indirectStoreAlphaName: indirectMeta?.alphaName ?? '',
      indirectStoreAddress: indirectMeta?.address ?? '',
      indirectStorePhone: indirectMeta?.phone ?? '',
      indirectStoreDiscounts: indirectMeta?.storeDiscounts ?? const [],
      indirectStoreDiscountDisplay: indirectMeta?.discountDisplay ?? '',
      pricelistArea: pricelistArea,
    );
  }
}
