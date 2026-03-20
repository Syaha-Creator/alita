import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/log.dart';
import '../data/models/order_history.dart';
import 'order_history_provider.dart';

class OrderDetailNotifier extends AutoDisposeFamilyAsyncNotifier<OrderHistory, int> {
  @override
  Future<OrderHistory> build(int orderId) => _fetchOrderDetail(orderId);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchOrderDetail(arg));
  }

  Future<void> addAdditionalPayment({
    required Map<String, dynamic> payload,
    required File receiptFile,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final userId = await StorageService.loadUserId();
    final fields = <String, String>{
      'order_letter_payment[order_letter_id]': current.id.toString(),
      'order_letter_payment[created_by]': userId.toString(),
    };

    payload.forEach((key, value) {
      final raw = value?.toString() ?? '';
      if (raw.isNotEmpty) {
        fields['order_letter_payment[$key]'] = raw;
      }
    });

    final file = await http.MultipartFile.fromPath(
      'order_letter_payment[image]',
      receiptFile.path,
    );

    final response = await ApiClient.instance.postMultipart(
      '/order_letter_payments',
      fields: fields,
      files: [file],
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(response.statusCode, response.body),
      );
    }

    await refresh();
    ref.invalidate(orderHistoryProvider);
  }

  Future<void> updateStatus(String status) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final response = await ApiClient.instance.put(
      '/order_letters/${current.id}',
      body: {
        'order_letter': {'status': status},
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        _extractErrorMessage(response.statusCode, response.body),
      );
    }

    await refresh();
    ref.invalidate(orderHistoryProvider);
  }

  Future<OrderHistory> _fetchOrderDetail(int orderId) async {
    try {
      final directResponse = await ApiClient.instance.get('/order_letters/$orderId');
      if (directResponse.statusCode == 200) {
        final parsed = _tryParseSingleOrder(directResponse.body);
        if (parsed != null) return parsed;
      }

      final userId = await StorageService.loadUserId();
      final listResponse = await ApiClient.instance.get(
        '/order_letters',
        queryParams: {
          'user_id': userId.toString(),
          'order_letter_id': orderId.toString(),
        },
      );

      if (listResponse.statusCode != 200) {
        throw Exception(
          'Gagal memuat detail pesanan (${listResponse.statusCode})',
        );
      }

      final body = jsonDecode(listResponse.body);
      final result = body is Map<String, dynamic> ? body['result'] : null;
      if (result is List) {
        for (final row in result) {
          final map = row is Map<String, dynamic>
              ? row
              : Map<String, dynamic>.from(row as Map);
          final parsed = OrderHistory.fromApiJson(map);
          if (parsed.id == orderId) return parsed;
        }
      }

      throw Exception('Detail pesanan tidak ditemukan.');
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetailNotifier._fetchOrderDetail');
      rethrow;
    }
  }

  OrderHistory? _tryParseSingleOrder(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;

      final result = decoded['result'];
      if (result is Map<String, dynamic>) {
        return OrderHistory.fromApiJson(result);
      }
      if (decoded['order_letter'] is Map<String, dynamic>) {
        return OrderHistory.fromApiJson(decoded);
      }
      return null;
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetailNotifier._tryParseSingleOrder');
      return null;
    }
  }

  String _extractErrorMessage(int statusCode, String responseBody) {
    try {
      final body = jsonDecode(responseBody);
      if (body is Map<String, dynamic>) {
        return body['message']?.toString() ??
            body['error']?.toString() ??
            'Gagal memproses data ($statusCode)';
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetailNotifier._extractErrorMessage');
    }
    return 'Gagal memproses data ($statusCode)';
  }
}

final orderDetailProvider =
    AsyncNotifierProvider.autoDispose.family<OrderDetailNotifier, OrderHistory, int>(
  OrderDetailNotifier.new,
);

