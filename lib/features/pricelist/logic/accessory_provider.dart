import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/safe_json_list.dart';
import '../data/models/accessory.dart';
import 'product_provider.dart' show effectiveAreaProvider;

/// Provider untuk aksesoris (pengganti bonus) dari API pl_accessories.
///
/// Difilter per [effectiveAreaProvider] karena pricelist aksesoris berbeda
/// per area (sama seperti produk utama di `filtered_pl`). Query param `area`
/// dikirim ke server, dan hasilnya juga difilter ulang di klien sebagai
/// jaga-jaga jika server mengembalikan area lain.
final accessoryProvider = FutureProvider<List<Accessory>>((ref) async {
  final area = ref.watch(effectiveAreaProvider);
  if (area.isEmpty) return [];

  try {
    final response = await ref.read(apiClientProvider).get(
      '/pl_accessories',
      queryParams: {'area': area},
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      Log.warning('HTTP ${response.statusCode}', tag: 'Accessory');
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];

    final rawList = decoded['result'] is List
        ? decoded['result']
        : (decoded['data'] is List ? decoded['data'] : null);
    if (rawList != null &&
        (decoded['status'] == 'success' || decoded['data'] != null)) {
      final lowerArea = area.toLowerCase();
      final Map<String, Accessory> uniqueAcc = {};
      for (final e
          in safeMapList(rawList, fieldName: 'pl_accessories')) {
        final acc = Accessory.fromJson(e);
        // Jaga-jaga: hanya terima baris yang benar-benar milik area ini.
        // Baris tanpa field `area` (API lama) tetap diterima apa adanya.
        if (acc.area.isNotEmpty && acc.area.toLowerCase() != lowerArea) {
          continue;
        }
        uniqueAcc[acc.itemNum] = acc;
      }
      return uniqueAcc.values.toList();
    }
    return [];
  } catch (e, st) {
    Log.error(e, st, reason: 'accessoryProvider');
    return [];
  }
});
