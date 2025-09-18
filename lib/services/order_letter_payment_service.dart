import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class OrderLetterPaymentService {
  final Dio _dio;

  OrderLetterPaymentService(this._dio);

  /// Create order letter payment
  Future<Map<String, dynamic>> createPayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final url = ApiConfig.getCreateOrderLetterPaymentUrl(token: token);

      final requestData = {
        'order_letter_id': orderLetterId,
        'payment_method': paymentMethod,
        'payment_bank': paymentBank,
        'payment_number': paymentNumber,
        'payment_amount': paymentAmount,
        'creator': creator,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      };

      final response = await _dio.post(url, data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create payment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating payment: $e');
    }
  }

  /// Upload all payment methods for an order letter (loop for each payment)
  Future<List<Map<String, dynamic>>> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  }) async {
    try {
      final List<Map<String, dynamic>> results = [];

      // Loop through all payment methods and upload each one
      for (Map<String, dynamic> payment in paymentMethods) {
        final result = await createPayment(
          orderLetterId: orderLetterId,
          paymentMethod: payment['payment_method'] ?? '',
          paymentBank: payment['payment_bank'] ?? '',
          paymentNumber: payment['payment_number'] ?? '',
          paymentAmount: (payment['payment_amount'] as num?)?.toDouble() ?? 0.0,
          creator: creator,
          note: payment['note'] ?? note,
        );
        results.add(result);
      }

      return results;
    } catch (e) {
      throw Exception('Error uploading payment methods: $e');
    }
  }

  /// Upload single payment method
  Future<Map<String, dynamic>> uploadSinglePayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
  }) async {
    return await createPayment(
      orderLetterId: orderLetterId,
      paymentMethod: paymentMethod,
      paymentBank: paymentBank,
      paymentNumber: paymentNumber,
      paymentAmount: paymentAmount,
      creator: creator,
      note: note,
    );
  }
}
