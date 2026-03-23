import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/network_error.dart';
import '../../../core/utils/retry.dart';
import '../data/models/item_lookup.dart';

/// Provider untuk data lookup item_num (SKU Pabrik) dari API pl_lookup_item_nums.
/// Return Map grouped by [tipe] (lowercase) agar lookup di UI O(1), plus caching.
final itemLookupProvider =
    FutureProvider<Map<String, List<ItemLookup>>>((ref) async {
  try {
    final response = await retry(
      () => ApiClient.instance.get(
        '/pl_lookup_item_nums',
        timeout: const Duration(seconds: 15),
      ),
      maxAttempts: 2,
      tag: 'itemLookup',
    );

    if (response.statusCode != 200) {
      Log.warning('ItemLookup: HTTP ${response.statusCode}',
          tag: 'itemLookup');
      return {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return {};

    if (decoded['status'] != 'success' || decoded['result'] is! List) {
      return {};
    }

    final List<dynamic> data = decoded['result'] as List<dynamic>;
    final Map<String, List<ItemLookup>> groupedMap = {};
    for (var e in data) {
      final lookup = ItemLookup.fromJson(e as Map<String, dynamic>);
      final key = lookup.tipe.toLowerCase().trim();
      groupedMap.putIfAbsent(key, () => []).add(lookup);
    }
    return groupedMap;
  } catch (e, st) {
    if (isNetworkError(e)) {
      Log.warning('itemLookupProvider: $e', tag: 'itemLookup');
    } else {
      Log.error(e, st, reason: 'itemLookupProvider');
    }
    return {};
  }
});
