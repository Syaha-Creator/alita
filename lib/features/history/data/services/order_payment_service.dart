import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/services/api_client.dart';

class OrderPaymentService {
  const OrderPaymentService._();

  static final ApiClient _api = ApiClient.instance;

  static Future<http.Response> createAdditionalPayment({
    required int orderId,
    required Map<String, dynamic> payload,
    required File receiptFile,
    required int userId,
  }) async {
    final fields = <String, String>{
      'order_letter_payment[order_letter_id]': '$orderId',
      'order_letter_payment[created_by]': '$userId',
    };

    payload.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        fields['order_letter_payment[$key]'] = value.toString();
      }
    });

    if (!receiptFile.existsSync()) {
      throw StateError(
        'File bukti pembayaran tidak ditemukan: ${receiptFile.path}',
      );
    }

    final file = await http.MultipartFile.fromPath(
      'order_letter_payment[image]',
      receiptFile.path,
    );

    return _api.postMultipart(
      '/order_letter_payments',
      fields: fields,
      files: [file],
    );
  }
}
