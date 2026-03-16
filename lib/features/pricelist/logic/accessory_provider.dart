import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../data/models/accessory.dart';

/// Provider untuk aksesoris (pengganti bonus) dari API pl_accessories.
final accessoryProvider = FutureProvider<List<Accessory>>((ref) async {
  try {
    final response = await ApiClient.instance.get(
      '/pl_accessories',
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      debugPrint('Accessory: HTTP ${response.statusCode}');
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];

    final List<dynamic>? rawList = decoded['result'] is List<dynamic>
        ? decoded['result'] as List<dynamic>
        : (decoded['data'] is List<dynamic>
            ? decoded['data'] as List<dynamic>
            : null);
    if (rawList != null &&
        (decoded['status'] == 'success' || decoded['data'] != null)) {
      final Map<String, Accessory> uniqueAcc = {};
      for (var e in rawList) {
        final acc = Accessory.fromJson(e as Map<String, dynamic>);
        uniqueAcc[acc.itemNum] = acc;
      }
      return uniqueAcc.values.toList();
    }
    return [];
  } catch (e) {
    debugPrint('Accessory: $e');
    return [];
  }
});
