import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alitapricelist/core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/area_utils.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/network_error.dart';
import '../data/models/product.dart';
import '../../../core/enums/sales_mode.dart';
import '../../auth/logic/auth_provider.dart';
import '../../indirect/logic/indirect_session_provider.dart';
import '../../indirect/logic/sales_mode_provider.dart';
import 'indirect_catalog_filter_utils.dart';
import 'master_data_provider.dart';

/// Snapshot load result: network success sets [isFromStaleCache] false.
/// On network/API failure, last successful snapshot may be returned with
/// [isFromStaleCache] true (full list replace on every successful fetch).
@immutable
class ProductListLoadResult {
  const ProductListLoadResult({
    required this.products,
    this.isFromStaleCache = false,
  });

  final List<Product> products;
  final bool isFromStaleCache;
}

// ─────────────────────────────────────────────────────────
//  Sort
// ─────────────────────────────────────────────────────────

/// Sort options for product list
enum SortOption {
  newest('Terbaru'),
  priceLowToHigh('Harga: Rendah ke Tinggi'),
  priceHighToLow('Harga: Tinggi ke Rendah');

  final String label;
  const SortOption(this.label);
}

/// State provider for sort option (default: newest / original order)
final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.newest);

// ─────────────────────────────────────────────────────────
//  Cascading Filters: Area → Channel → Brand
// ─────────────────────────────────────────────────────────

/// Area — default from auth resolved against available areas (smart mapping + fallback)
final selectedAreaProvider = StateProvider<String>((ref) {
  final auth = ref.watch(authProvider);
  final areas = ref.watch(areasProvider);
  final userArea = auth.defaultArea.isNotEmpty ? auth.defaultArea : '';
  return AreaUtils.resolveDefaultArea(userArea, areas);
});

/// Master data: available areas — parsed from API cache.
/// API shape may use field `name` or `area` per item. Returns unique list.
final areasProvider = Provider<List<String>>((ref) {
  final masterData = ref.watch(masterDataProvider);
  try {
    if (masterData.areas.isEmpty) return [];
    return masterData.areas
        .map((a) => (a['name'] ?? a['area'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
  } catch (e, st) {
    Log.error(e, st, reason: 'areasProvider parse');
    return [];
  }
});

/// Effective area for API/query: "Harga Nasional" rule.
/// If selected brand is "Spring Air" or "Therapedic" (case-insensitive), use "Nasional".
/// Otherwise use the user-selected area.
final effectiveAreaProvider = Provider<String>((ref) {
  final selectedArea = ref.watch(selectedAreaProvider);
  final selectedBrand = ref.watch(selectedBrandProvider) ?? '';
  final brandLower = selectedBrand.toLowerCase();
  if (brandLower.contains('spring air') ||
      brandLower.contains('therapedic') ||
      brandLower.contains('sleep spa')) {
    return 'Nasional';
  }
  return selectedArea;
});

/// Channel selection (nullable — user must pick one)
final selectedChannelProvider = StateProvider<String?>((ref) => null);

/// Brand selection (nullable — user must pick one after channel)
final selectedBrandProvider = StateProvider<String?>((ref) => null);

/// Master data: available channels — parsed from API cache.
/// API shape: {"status":"success","data":[{"id":223,"channel":"Direct"}, ...]}
/// Returns unique `List<String>` of channel names.
final channelsProvider = Provider<List<String>>((ref) {
  final masterData = ref.watch(masterDataProvider);
  try {
    if (masterData.channels.isEmpty) return [];

    return masterData.channels
        .map((c) => (c['channel'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  } catch (e, st) {
    Log.error(e, st, reason: 'channelsProvider parse');
    return [];
  }
});

/// Master data: brands filtered by the selected channel.
/// API shape: {"status":"success","data":[{"id":622,"brand":"Comforta","pl_channel_id":223}, ...]}
///
/// Flow:
/// 1. Find the channel object whose `channel` field matches the selected name.
/// 2. Get its `id`.
/// 3. Filter brands where `pl_channel_id` == that id.
/// 4. Return unique brand names.
final brandsProvider = Provider<List<String>>((ref) {
  final selectedChannel = ref.watch(selectedChannelProvider);
  if (selectedChannel == null) return [];

  final masterData = ref.watch(masterDataProvider);
  try {
    if (masterData.channels.isEmpty || masterData.brands.isEmpty) return [];

    // Step 1: Find the selected channel's id (API may return id as int or string)
    final channelObj = masterData.channels.firstWhere(
      (c) => c['channel']?.toString() == selectedChannel,
      orElse: () => <String, dynamic>{},
    );
    final rawId = channelObj['id'];
    if (rawId == null) return [];
    final selectedChannelId =
        rawId is int ? rawId : int.tryParse(rawId.toString());
    if (selectedChannelId == null) return [];

    // Step 2: Filter brands by pl_channel_id (may be int or string from API)
    return masterData.brands
        .where((b) {
          final plId = b['pl_channel_id'];
          if (plId == null) return false;
          final plIdInt = plId is int ? plId : int.tryParse(plId.toString());
          return plIdInt != null && plIdInt == selectedChannelId;
        })
        .map((b) => (b['brand'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  } catch (e, st) {
    Log.error(e, st, reason: 'brandsProvider parse');
    return [];
  }
});

/// Channel list for filter UI: mode indirect → hanya nama yang mengandung "toko".
final catalogChannelsProvider = Provider<List<String>>((ref) {
  final all = ref.watch(channelsProvider);
  final mode = ref.watch(salesModeProvider);
  if (mode != SalesMode.indirect) return all;
  return IndirectCatalogFilterUtils.filterTokoChannels(all);
});

/// Brand list for filter UI: indirect + toko terpilih → sesuai [catcode_27] bila ada.
final catalogBrandsProvider = Provider<List<String>>((ref) {
  final mode = ref.watch(salesModeProvider);
  final session = ref.watch(indirectSessionProvider);
  final selectedChannel = ref.watch(selectedChannelProvider);
  if (selectedChannel == null) return [];

  if (mode != SalesMode.indirect || !session.hasStore) {
    return ref.watch(brandsProvider);
  }

  final masterData = ref.watch(masterDataProvider);
  return IndirectCatalogFilterUtils.brandNamesForChannel(
    masterData.channels,
    masterData.brands,
    selectedChannel,
    catcode27: session.selectedStore!.catcode27,
  );
});

/// Berubah saat toko indirect / daftar channel toko / master data siap — untuk sync otomatis filter.
final indirectCatalogSyncTokenProvider = Provider<String?>((ref) {
  final mode = ref.watch(salesModeProvider);
  if (mode != SalesMode.indirect) return null;
  final store =
      ref.watch(indirectSessionProvider.select((s) => s.selectedStore));
  if (store == null) return null;
  final tokoKey = ref.watch(catalogChannelsProvider).join('|');
  ref.watch(masterDataProvider);
  return '${store.addressNumber}|${store.catcode27 ?? ''}|$tokoKey';
});

/// Whether cascading selection is complete (channel + brand both chosen)
final isFilterCompleteProvider = Provider<bool>((ref) {
  final mode = ref.watch(salesModeProvider);
  if (mode == SalesMode.indirect) {
    final session = ref.watch(indirectSessionProvider);
    if (!session.hasStore) return false;
  }
  return ref.watch(selectedChannelProvider) != null &&
      ref.watch(selectedBrandProvider) != null;
});

// ─────────────────────────────────────────────────────────
//  Search
// ─────────────────────────────────────────────────────────

/// State provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// ─────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────

/// Safeguard: format area string to Title Case for API (case-sensitive).
String _toTitleCase(String text) {
  if (text.isEmpty) return text;
  return text.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

// ─────────────────────────────────────────────────────────
//  Product Data (API)
// ─────────────────────────────────────────────────────────

/// Maps API `data` list rows to [Product] (same rules as historical provider).
List<Product> mapFilteredPlRawListToProducts(
  List<dynamic> rawList,
  String channel,
  String brand,
) {
  return rawList.map((e) {
    final json = e is Map<String, dynamic> ? e : <String, dynamic>{};
    final nameRaw = '${json['kasur'] ?? ''} ${json['ukuran'] ?? ''}'.trim();
    final name = nameRaw.isEmpty ? 'Produk Tanpa Nama' : nameRaw;
    final priceRaw = json['end_user_price'];
    final price = (priceRaw is num)
        ? priceRaw.toDouble()
        : (double.tryParse(priceRaw?.toString() ?? '') ?? 0.0);
    double toDouble(dynamic v) => (v is num)
        ? v.toDouble()
        : (double.tryParse(v?.toString() ?? '') ?? 0.0);
    double readDisc(int i) {
      final keys = ['disc_$i', 'disc$i', 'discount_$i', 'max_disc_$i'];
      for (final k in keys) {
        final v = json[k];
        if (v == null) continue;
        final d = toDouble(v);
        if (d > 0) return d;
      }
      return 0.0;
    }

    double toDiscFraction(int i) {
      final d = readDisc(i);
      if (d <= 0) return 0.0;
      return d > 1 ? (d / 100) : d;
    }

    return Product(
      id: (json['id'] ?? '').toString(),
      name: name,
      price: price,
      imageUrl: AppConfig.placeholderProductImageById(json['id']),
      category: (json['series'] ?? 'Uncategorized').toString(),
      description: (json['detail_list'] ??
              'Deskripsi detail belum tersedia untuk produk ini.')
          .toString(),
      channel: (json['channel'] ?? channel).toString(),
      brand: (json['brand'] ?? brand).toString(),
      program: (json['program'] ?? '-').toString(),
      kasur: (json['kasur'] ?? '').toString(),
      ukuran: (json['ukuran'] ?? '').toString(),
      divan: (json['divan'] ?? '').toString(),
      headboard: (json['headboard'] ?? '').toString(),
      sorong: (json['sorong'] ?? '').toString(),
      isSet: json['set'] == true,
      pricelist: toDouble(json['pricelist']),
      eupKasur: toDouble(json['eup_kasur']),
      eupDivan: toDouble(json['eup_divan']),
      eupHeadboard: toDouble(json['eup_headboard']),
      eupSorong: toDouble(json['eup_sorong']),
      plKasur: toDouble(json['pl_kasur']),
      plDivan: toDouble(json['pl_divan']),
      plHeadboard: toDouble(json['pl_headboard']),
      plSorong: toDouble(json['pl_sorong']),
      bonus1: json['bonus_1']?.toString(),
      qtyBonus1: json['qty_bonus1'] is int
          ? json['qty_bonus1'] as int
          : int.tryParse(json['qty_bonus1']?.toString() ?? ''),
      bonus2: json['bonus_2']?.toString(),
      qtyBonus2: json['qty_bonus2'] is int
          ? json['qty_bonus2'] as int
          : int.tryParse(json['qty_bonus2']?.toString() ?? ''),
      bonus3: json['bonus_3']?.toString(),
      qtyBonus3: json['qty_bonus3'] is int
          ? json['qty_bonus3'] as int
          : int.tryParse(json['qty_bonus3']?.toString() ?? ''),
      bonus4: json['bonus_4']?.toString(),
      qtyBonus4: json['qty_bonus4'] is int
          ? json['qty_bonus4'] as int
          : int.tryParse(json['qty_bonus4']?.toString() ?? ''),
      bonus5: json['bonus_5']?.toString(),
      qtyBonus5: json['qty_bonus5'] is int
          ? json['qty_bonus5'] as int
          : int.tryParse(json['qty_bonus5']?.toString() ?? ''),
      bonus6: json['bonus_6']?.toString(),
      qtyBonus6: json['qty_bonus6'] is int
          ? json['qty_bonus6'] as int
          : int.tryParse(json['qty_bonus6']?.toString() ?? ''),
      bonus7: json['bonus_7']?.toString(),
      qtyBonus7: json['qty_bonus7'] is int
          ? json['qty_bonus7'] as int
          : int.tryParse(json['qty_bonus7']?.toString() ?? ''),
      bonus8: json['bonus_8']?.toString(),
      qtyBonus8: json['qty_bonus8'] is int
          ? json['qty_bonus8'] as int
          : int.tryParse(json['qty_bonus8']?.toString() ?? ''),
      plBonus1:
          json['pl_bonus_1'] != null ? toDouble(json['pl_bonus_1']) : null,
      plBonus2:
          json['pl_bonus_2'] != null ? toDouble(json['pl_bonus_2']) : null,
      plBonus3:
          json['pl_bonus_3'] != null ? toDouble(json['pl_bonus_3']) : null,
      plBonus4:
          json['pl_bonus_4'] != null ? toDouble(json['pl_bonus_4']) : null,
      plBonus5:
          json['pl_bonus_5'] != null ? toDouble(json['pl_bonus_5']) : null,
      plBonus6:
          json['pl_bonus_6'] != null ? toDouble(json['pl_bonus_6']) : null,
      plBonus7:
          json['pl_bonus_7'] != null ? toDouble(json['pl_bonus_7']) : null,
      plBonus8:
          json['pl_bonus_8'] != null ? toDouble(json['pl_bonus_8']) : null,
      bottomPriceAnalyst: toDouble(json['bottom_price_analyst']),
      disc1: toDiscFraction(1),
      disc2: toDiscFraction(2),
      disc3: toDiscFraction(3),
      disc4: toDiscFraction(4),
      disc5: toDiscFraction(5),
      disc6: toDiscFraction(6),
      disc7: toDiscFraction(7),
      disc8: toDiscFraction(8),
    );
  }).toList();
}

List<Product> _productsFromResponseBody(
    String body, String channel, String brand) {
  final decoded = jsonDecode(body);
  if (decoded == null) throw Exception('Response tidak valid.');

  List<dynamic> rawList;
  if (decoded is Map<String, dynamic> && decoded['data'] is List) {
    rawList = decoded['data'] as List<dynamic>;
  } else if (decoded is List) {
    rawList = decoded;
  } else {
    rawList = [];
  }

  return mapFilteredPlRawListToProducts(rawList, channel, brand);
}

/// Fetches product list from API; on every **successful** response the full
/// list for this filter is written to disk (overwrites any previous snapshot).
/// On failure, returns the last successful snapshot if any ([isFromStaleCache]).
final productListProvider = FutureProvider<ProductListLoadResult>((ref) async {
  final area = ref.watch(effectiveAreaProvider);
  final channel = ref.watch(selectedChannelProvider);
  final brand = ref.watch(selectedBrandProvider);

  if (channel == null || brand == null) {
    return const ProductListLoadResult(products: []);
  }

  final formattedArea = _toTitleCase(area);
  final cacheKey =
      StorageService.pricelistCacheStorageKey(formattedArea, channel, brand);

  Future<ProductListLoadResult?> tryLoadStale() async {
    final rows = await StorageService.loadPricelistProductRows(cacheKey);
    if (rows == null || rows.isEmpty) return null;
    try {
      final products =
          rows.map((m) => Product.fromJson(m)).toList(growable: false);
      return ProductListLoadResult(
        products: products,
        isFromStaleCache: true,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'pricelist cache parse');
      return null;
    }
  }

  try {
    final response = await ApiClient.instance.get(
      '/rawdata_price_lists/filtered_pl',
      queryParams: {
        'area': formattedArea,
        'channel': channel,
        'brand': brand,
      },
    );

    if (response.statusCode != 200) {
      final stale = await tryLoadStale();
      if (stale != null) return stale;
      throw Exception(
        'Gagal memuat pricelist (${response.statusCode}). Coba lagi nanti.',
      );
    }

    final products = _productsFromResponseBody(response.body, channel, brand);
    final rows = products.map((p) => p.toJson()).toList(growable: false);
    await StorageService.savePricelistProductRows(cacheKey, rows);

    return ProductListLoadResult(products: products, isFromStaleCache: false);
  } catch (e, st) {
    if (isNetworkError(e)) {
      Log.warning('productListProvider fetch: $e', tag: 'Pricelist');
    } else {
      Log.error(e, st, reason: 'productListProvider fetch');
    }
    final stale = await tryLoadStale();
    if (stale != null) return stale;
    rethrow;
  }
});

/// Filtered AND sorted products.
/// API already returns products filtered by Area + Channel + Brand.
/// We apply: Variant Grouping (1 card per model, lowest price) → Search → Sort.
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final selectedChannel = ref.watch(selectedChannelProvider);
  final selectedBrand = ref.watch(selectedBrandProvider);
  if (selectedChannel == null || selectedBrand == null) return [];

  final productsAsync = ref.watch(productListProvider);
  var products = productsAsync.valueOrNull?.products ?? [];
  if (products.isEmpty) return [];

  // --- START LOGIKA GROUPING ---
  final Map<String, Product> groupedMap = {};

  for (final p in products) {
    // 1. Smart Naming: Hindari nama "Tanpa Kasur"
    String groupName = p.kasur.trim();

    if (groupName.toLowerCase() == 'tanpa kasur' || groupName.isEmpty) {
      if (p.divan.toLowerCase() != 'tanpa divan' && p.divan.trim().isNotEmpty) {
        groupName = p.divan.trim();
      } else if (p.headboard.toLowerCase() != 'tanpa headboard' &&
          p.headboard.trim().isNotEmpty) {
        groupName = p.headboard.trim();
      } else if (p.sorong.toLowerCase() != 'tanpa sorong' &&
          p.sorong.trim().isNotEmpty) {
        groupName = p.sorong.trim();
      } else {
        groupName = p.name; // Fallback ke nama asli jika semua gagal
      }
    }

    // 2. Simpan ke Map & Cari Harga Termurah
    if (!groupedMap.containsKey(groupName)) {
      groupedMap[groupName] = p.copyWith(name: groupName);
    } else {
      final existingProduct = groupedMap[groupName];
      if (existingProduct != null &&
          p.price > 0 &&
          p.price < existingProduct.price) {
        groupedMap[groupName] = p.copyWith(name: groupName);
      }
    }
  }

  // 3. Timpa list products dengan hasil grouping
  products = groupedMap.values.toList();
  // --- END LOGIKA GROUPING ---

  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final sortOption = ref.watch(sortOptionProvider);

  // Step 1: Search (on grouped list)
  final filtered = searchQuery.isEmpty
      ? List<Product>.from(products)
      : products
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery) ||
              product.description.toLowerCase().contains(searchQuery))
          .toList();

  // Step 2: Sort
  switch (sortOption) {
    case SortOption.priceLowToHigh:
      filtered.sort((a, b) => a.price.compareTo(b.price));
    case SortOption.priceHighToLow:
      filtered.sort((a, b) => b.price.compareTo(a.price));
    case SortOption.newest:
      break;
  }

  return filtered;
});
