import '../../cart/data/cart_item.dart';
import '../data/models/item_lookup.dart';

/// Hasil pemetaan [CartItem] → seleksi konfigurator + custom flags untuk
/// [ProductDetailPage] (buka dari keranjang / penawaran).
class CartItemSnapshotRestoreResult {
  const CartItemSnapshotRestoreResult({
    required this.kasurLookup,
    required this.divanLookup,
    required this.headboardLookup,
    required this.sorongLookup,
    required this.isKasurCustom,
    required this.isDivanCustom,
    required this.isHeadboardCustom,
    required this.isSorongCustom,
    required this.customKasurNote,
    required this.customDivanNote,
    required this.customHeadboardNote,
    required this.customSorongNote,
  });

  final ItemLookup? kasurLookup;
  final ItemLookup? divanLookup;
  final ItemLookup? headboardLookup;
  final ItemLookup? sorongLookup;

  final bool isKasurCustom;
  final bool isDivanCustom;
  final bool isHeadboardCustom;
  final bool isSorongCustom;

  final String customKasurNote;
  final String customDivanNote;
  final String customHeadboardNote;
  final String customSorongNote;
}

/// Memulihkan lookup & custom dari snapshot agar detail produk selaras dengan
/// saat barang dimasukkan ke keranjang.
abstract final class CartItemSnapshotDetailRestore {
  CartItemSnapshotDetailRestore._();

  static bool _isCustomSku(String sku) =>
      sku.trim().toUpperCase() == CartItem.customItemSku;

  static ItemLookup? _findByItemNum(
    String sku,
    Map<String, List<ItemLookup>> grouped,
  ) {
    final t = sku.trim().toLowerCase();
    if (t.isEmpty) return null;
    for (final list in grouped.values) {
      for (final l in list) {
        if (l.itemNum.trim().toLowerCase() == t) return l;
      }
    }
    return null;
  }

  static ItemLookup? _findByKainWarnaUkuran(
    String kain,
    String warna,
    String ukuran,
    Map<String, List<ItemLookup>> grouped,
  ) {
    final kk = kain.trim().toLowerCase();
    final ww = warna.trim().toLowerCase();
    final uu = ukuran.trim();
    if (kk.isEmpty && ww.isEmpty) return null;
    for (final list in grouped.values) {
      for (final l in list) {
        if (uu.isNotEmpty && l.ukuran != ukuran) continue;
        final lk = (l.jenisKain ?? '').trim().toLowerCase();
        final lw = (l.warnaKain ?? '').trim().toLowerCase();
        if (lk == kk && lw == ww) return l;
      }
    }
    return null;
  }

  static CartItemSnapshotRestoreResult compute(
    CartItem item,
    Map<String, List<ItemLookup>> groupedLookups,
  ) {
    final p = item.product;
    final size = p.ukuran;

    final ks = item.kasurSku.trim();
    final isKasurCustom = _isCustomSku(ks);
    ItemLookup? kasurL;
    if (!isKasurCustom && ks.isNotEmpty) {
      kasurL = _findByItemNum(ks, groupedLookups);
    }

    final ds = item.divanSku.trim();
    final isDivanCustom = _isCustomSku(ds);
    ItemLookup? divanL;
    if (!isDivanCustom && ds.isNotEmpty) {
      divanL = _findByItemNum(ds, groupedLookups);
      divanL ??= _findByKainWarnaUkuran(
        item.divanKain,
        item.divanWarna,
        size,
        groupedLookups,
      );
    }

    final hs = item.sandaranSku.trim();
    final isHbCustom = _isCustomSku(hs);
    ItemLookup? hbL;
    if (!isHbCustom && hs.isNotEmpty) {
      hbL = _findByItemNum(hs, groupedLookups);
      hbL ??= _findByKainWarnaUkuran(
        item.sandaranKain,
        item.sandaranWarna,
        size,
        groupedLookups,
      );
    }

    final ss = item.sorongSku.trim();
    final isSorongCustom = _isCustomSku(ss);
    ItemLookup? sorongL;
    if (!isSorongCustom && ss.isNotEmpty) {
      sorongL = _findByItemNum(ss, groupedLookups);
      sorongL ??= _findByKainWarnaUkuran(
        item.sorongKain,
        item.sorongWarna,
        size,
        groupedLookups,
      );
    }

    final String kasurNote;
    if (isKasurCustom) {
      kasurNote = _kasurCustomNoteFromDescription(p.description);
    } else {
      kasurNote = '';
    }

    return CartItemSnapshotRestoreResult(
      kasurLookup: kasurL,
      divanLookup: divanL,
      headboardLookup: hbL,
      sorongLookup: sorongL,
      isKasurCustom: isKasurCustom,
      isDivanCustom: isDivanCustom,
      isHeadboardCustom: isHbCustom,
      isSorongCustom: isSorongCustom,
      customKasurNote: kasurNote,
      customDivanNote: item.divanWarna.isNotEmpty
          ? item.divanWarna
          : (item.divanKain.toLowerCase() == 'custom' ? 'Custom' : ''),
      customHeadboardNote: item.sandaranWarna.isNotEmpty
          ? item.sandaranWarna
          : (item.sandaranKain.toLowerCase() == 'custom' ? 'Custom' : ''),
      customSorongNote: item.sorongWarna.isNotEmpty
          ? item.sorongWarna
          : (item.sorongKain.toLowerCase() == 'custom' ? 'Custom' : ''),
    );
  }

  /// Ambil catatan custom kasur dari baris deskripsi konfigurator bila ada.
  static String _kasurCustomNoteFromDescription(String description) {
    final lines = description.split('\n');
    for (final line in lines.reversed) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('[') && t.contains('·')) continue;
      if (t.length > 200) return t.substring(0, 200);
      return t;
    }
    return '';
  }
}
