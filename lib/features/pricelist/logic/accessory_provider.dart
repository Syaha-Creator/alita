import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/log.dart';
import '../../../core/utils/safe_json_list.dart';
import '../data/models/accessory.dart';

/// Provider untuk aksesoris (pengganti bonus) dari API pl_accessories.
final accessoryProvider = FutureProvider<List<Accessory>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '/pl_accessories',
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
      final Map<String, Accessory> uniqueAcc = {};
      for (final e
          in safeMapList(rawList, fieldName: 'pl_accessories')) {
        final acc = Accessory.fromJson(e);
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
