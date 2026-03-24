import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/log.dart';
import '../data/models/order_history.dart';
import '../data/services/order_letter_fetch.dart';
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
      final wrap = await fetchOrderLetterResultWrap(orderId);
      if (wrap != null) {
        return OrderHistory.fromApiJson(wrap);
      }
      throw Exception('Detail pesanan tidak ditemukan.');
    } catch (e, st) {
      Log.error(e, st, reason: 'OrderDetailNotifier._fetchOrderDetail');
      rethrow;
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

