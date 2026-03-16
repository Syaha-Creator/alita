import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/area_utils.dart';
import '../data/models/product.dart';
import '../../auth/logic/auth_provider.dart';
import 'master_data_provider.dart';

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
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.newest);

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
  } catch (_) {
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
  } catch (_) {
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

    // Step 1: Find the selected channel's id
    final channelObj = masterData.channels.firstWhere(
      (c) => c['channel']?.toString() == selectedChannel,
      orElse: () => <String, dynamic>{},
    );
    final selectedChannelId = channelObj['id'];
    if (selectedChannelId == null) return [];

    // Step 2: Filter brands by pl_channel_id, extract unique names
    return masterData.brands
        .where((b) => b['pl_channel_id'] == selectedChannelId)
        .map((b) => (b['brand'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  } catch (_) {
    return [];
  }
});

/// Whether cascading selection is complete (channel + brand both chosen)
final isFilterCompleteProvider = Provider<bool>((ref) {
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

/// Fetches product list from on-premise API.
/// Returns empty list when channel or brand is not selected (guard clause).
/// Response shape: {"status":"success","data":[{ "id", "kasur", "ukuran", "end_user_price", "series", "channel", "brand", ... }]}
final productListProvider = FutureProvider<List<Product>>((ref) async {
  final area = ref.watch(effectiveAreaProvider);
  final channel = ref.watch(selectedChannelProvider);
  final brand = ref.watch(selectedBrandProvider);

  if (channel == null || brand == null) return [];

  try {
    final formattedArea = _toTitleCase(area);

    final response = await ApiClient.instance.get(
      '/rawdata_price_lists/filtered_pl',
      queryParams: {
        'area': formattedArea,
        'channel': channel,
        'brand': brand,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat pricelist (${response.statusCode}). Coba lagi nanti.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded == null) throw Exception('Response tidak valid.');

    List<dynamic> rawList;
    if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      rawList = decoded['data'] as List<dynamic>;
    } else if (decoded is List) {
      rawList = decoded;
    } else {
      rawList = [];
    }

    return rawList.map((e) {
      final json = e is Map<String, dynamic> ? e : <String, dynamic>{};
      final nameRaw = '${json['kasur'] ?? ''} ${json['ukuran'] ?? ''}'.trim();
      final name = nameRaw.isEmpty ? 'Produk Tanpa Nama' : nameRaw;
      final priceRaw = json['end_user_price'];
      final price = (priceRaw is num)
          ? priceRaw.toDouble()
          : (double.tryParse(priceRaw?.toString() ?? '') ?? 0.0);
      double toDouble(dynamic v) =>
          (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? 0.0);
      // Batas diskon: coba beberapa key (API bisa pakai disc_1, disc1, discount_1, dll)
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
      // Jika API mengirim persen (10 = 10%), konversi ke fraksi (0.1)
      double toDiscFraction(int i) {
        final d = readDisc(i);
        if (d <= 0) return 0.0;
        return d > 1 ? (d / 100) : d; // > 1 anggap persen
      }

      return Product(
        id: (json['id'] ?? '').toString(),
        name: name,
        price: price,
        imageUrl: 'https://picsum.photos/seed/${json['id'] ?? 0}/400/600',
        category: (json['series'] ?? 'Uncategorized').toString(),
        description: (json['detail_list'] ?? 'Deskripsi detail belum tersedia untuk produk ini.').toString(),
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
        qtyBonus1: json['qty_bonus1'] is int ? json['qty_bonus1'] as int : int.tryParse(json['qty_bonus1']?.toString() ?? ''),
        bonus2: json['bonus_2']?.toString(),
        qtyBonus2: json['qty_bonus2'] is int ? json['qty_bonus2'] as int : int.tryParse(json['qty_bonus2']?.toString() ?? ''),
        bonus3: json['bonus_3']?.toString(),
        qtyBonus3: json['qty_bonus3'] is int ? json['qty_bonus3'] as int : int.tryParse(json['qty_bonus3']?.toString() ?? ''),
        bonus4: json['bonus_4']?.toString(),
        qtyBonus4: json['qty_bonus4'] is int ? json['qty_bonus4'] as int : int.tryParse(json['qty_bonus4']?.toString() ?? ''),
        bonus5: json['bonus_5']?.toString(),
        qtyBonus5: json['qty_bonus5'] is int ? json['qty_bonus5'] as int : int.tryParse(json['qty_bonus5']?.toString() ?? ''),
        bonus6: json['bonus_6']?.toString(),
        qtyBonus6: json['qty_bonus6'] is int ? json['qty_bonus6'] as int : int.tryParse(json['qty_bonus6']?.toString() ?? ''),
        bonus7: json['bonus_7']?.toString(),
        qtyBonus7: json['qty_bonus7'] is int ? json['qty_bonus7'] as int : int.tryParse(json['qty_bonus7']?.toString() ?? ''),
        bonus8: json['bonus_8']?.toString(),
        qtyBonus8: json['qty_bonus8'] is int ? json['qty_bonus8'] as int : int.tryParse(json['qty_bonus8']?.toString() ?? ''),
        plBonus1: json['pl_bonus_1'] != null ? toDouble(json['pl_bonus_1']) : null,
        plBonus2: json['pl_bonus_2'] != null ? toDouble(json['pl_bonus_2']) : null,
        plBonus3: json['pl_bonus_3'] != null ? toDouble(json['pl_bonus_3']) : null,
        plBonus4: json['pl_bonus_4'] != null ? toDouble(json['pl_bonus_4']) : null,
        plBonus5: json['pl_bonus_5'] != null ? toDouble(json['pl_bonus_5']) : null,
        plBonus6: json['pl_bonus_6'] != null ? toDouble(json['pl_bonus_6']) : null,
        plBonus7: json['pl_bonus_7'] != null ? toDouble(json['pl_bonus_7']) : null,
        plBonus8: json['pl_bonus_8'] != null ? toDouble(json['pl_bonus_8']) : null,
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
  } catch (e) {
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
  var products = productsAsync.valueOrNull ?? [];
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
      final existingProduct = groupedMap[groupName]!;
      if (p.price > 0 && p.price < existingProduct.price) {
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

