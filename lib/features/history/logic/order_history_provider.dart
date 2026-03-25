import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/api_session_expired.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../core/utils/retry.dart';
import '../../auth/logic/auth_provider.dart';
import '../data/models/order_history.dart';

// ── Filter tanggal: null = backend pakai default (bulan berjalan) ──

final dateFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

// ── Main provider ──────────────────────────────────────────────────

final orderHistoryProvider = FutureProvider.autoDispose<List<OrderHistory>>((
  ref,
) async {
  final dateRange = ref.watch(dateFilterProvider);
  final auth = ref.watch(authProvider);

  final userId = auth.userId;
  if (userId == 0) {
    throw Exception('User ID tidak ditemukan. Silakan login ulang.');
  }

  final queryParams = <String, String>{
    'user_id': userId.toString(),
  };

  if (dateRange != null) {
    queryParams['date_from'] = AppFormatters.apiDate(dateRange.start);
    queryParams['date_to'] = AppFormatters.apiDate(dateRange.end);
  }

  final response = await retry(
    () => ApiClient.instance.get(
      '/order_letters',
      queryParams: queryParams,
      timeout: const Duration(seconds: 15),
    ),
    maxAttempts: 2,
    tag: 'orderHistory',
    retryIf: (e) => e is! Exception || !e.toString().contains('User ID'),
  );

  if (response.statusCode == 401 || response.statusCode == 403) {
    await ref.read(authProvider.notifier).logout();
    throw const ApiSessionExpiredException('GET /order_letters');
  }

  if (response.statusCode != 200) {
    throw Exception('Gagal memuat data (${response.statusCode})');
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;

  if (body['status'] != 'success') {
    throw Exception(body['message']?.toString() ?? 'Respons API tidak valid');
  }

  final list = body['result'] as List? ?? [];
  final orders = list
      .map((e) => OrderHistory.fromApiJson(e as Map<String, dynamic>))
      .toList();

  orders.sort((a, b) {
    final dateA =
        a.createdAt ?? DateTime.tryParse(a.orderDate) ?? DateTime(2000);
    final dateB =
        b.createdAt ?? DateTime.tryParse(b.orderDate) ?? DateTime(2000);
    return dateB.compareTo(dateA);
  });

  return orders;
});
