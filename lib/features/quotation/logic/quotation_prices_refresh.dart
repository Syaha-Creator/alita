import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/log.dart';
import '../../cart/logic/cart_item_price_refresh.dart';
import '../../pricelist/data/models/product.dart';
import '../../pricelist/logic/product_provider.dart';
import '../data/quotation_model.dart';
import 'quotation_list_provider.dart';

/// Ongkir dari teks penawaran (angka saja), sama seperti detail sheet.
double quotationPostageAmount(String postage) {
  if (postage.isEmpty) return 0;
  final digits = postage.replaceAll(RegExp(r'[^\d]'), '');
  return double.tryParse(digits) ?? 0;
}

/// [subtotal] = jumlah total baris; [totalPrice] = subtotal − diskon + ongkir.
QuotationModel recalculateQuotationTotals(QuotationModel q) {
  final lineSum = q.items.fold<double>(0, (s, e) => s + e.totalPrice);
  final postage = quotationPostageAmount(q.postage);
  final subtotal = lineSum;
  final totalPrice = subtotal - q.discount + postage;
  return q.copyWith(subtotal: subtotal, totalPrice: totalPrice);
}

/// Channel & brand untuk API pricelist: dari item snapshot, fallback filter Beranda.
({String channel, String brand})? quotationCatalogFilter(
  QuotationModel q,
  WidgetRef ref,
) {
  if (q.items.isEmpty) return null;
  var channel = q.items.first.product.channel.trim();
  var brand = q.items.first.product.brand.trim();
  if (channel.isEmpty) {
    channel = ref.read(selectedChannelProvider) ?? '';
  }
  if (brand.isEmpty) {
    brand = ref.read(selectedBrandProvider) ?? '';
  }
  if (channel.isEmpty || brand.isEmpty) return null;

  for (final item in q.items) {
    final c = item.product.channel.trim().isEmpty
        ? channel
        : item.product.channel.trim();
    final b = item.product.brand.trim().isEmpty
        ? brand
        : item.product.brand.trim();
    if (c != channel || b != brand) return null;
  }
  return (channel: channel, brand: brand);
}

bool _quotationLinePricingChanged(QuotationModel before, QuotationModel after) {
  if (before.items.length != after.items.length) return true;
  for (var i = 0; i < before.items.length; i++) {
    if (before.items[i].totalPrice != after.items[i].totalPrice) return true;
    if (before.items[i].product.price != after.items[i].product.price) {
      return true;
    }
  }
  return before.subtotal != after.subtotal || before.totalPrice != after.totalPrice;
}

/// Tarik pricelist, terapkan ke [quotation], hitung ulang total. Gagal → lempar.
Future<QuotationModel> refreshQuotationFromServer(
  QuotationModel quotation,
  WidgetRef ref,
) async {
  final filter = quotationCatalogFilter(quotation, ref);
  if (filter == null) {
    throw StateError('Channel atau brand tidak diketahui untuk penawaran ini.');
  }
  final area = ref.read(effectiveAreaProvider);
  final catalog = await fetchFilteredPlProductsForRefresh(
    area: area,
    channel: filter.channel,
    brand: filter.brand,
  );
  final result =
      CartItemPriceRefresh.applyToLines(quotation.items, catalog);
  return recalculateQuotationTotals(
    quotation.copyWith(items: result.items),
  );
}

/// Setelah koneksi kembali: refresh semua draft yang bisa di-map ke satu channel/brand.
/// Mengembalikan jumlah penawaran yang benar-benar berubah harganya.
Future<int> refreshAllStoredQuotationsFromServer(WidgetRef ref) async {
  final list = ref.read(quotationListProvider);
  if (list.isEmpty) return 0;

  final area = ref.read(effectiveAreaProvider);
  final catalogCache = <String, List<Product>>{};
  var changedCount = 0;

  for (final q in list) {
    final filter = quotationCatalogFilter(q, ref);
    if (filter == null) continue;

    final cacheKey = '${filter.channel}|${filter.brand}';
    try {
      final catalog = catalogCache[cacheKey] ??=
          await fetchFilteredPlProductsForRefresh(
        area: area,
        channel: filter.channel,
        brand: filter.brand,
      );

      final result = CartItemPriceRefresh.applyToLines(q.items, catalog);
      final updated =
          recalculateQuotationTotals(q.copyWith(items: result.items));

      if (_quotationLinePricingChanged(q, updated)) {
        await ref.read(quotationListProvider.notifier).update(updated);
        changedCount++;
      }
    } catch (e, st) {
      Log.error(
        e,
        st,
        reason: 'refreshAllStoredQuotationsFromServer id=${q.id}',
      );
    }
  }

  return changedCount;
}
