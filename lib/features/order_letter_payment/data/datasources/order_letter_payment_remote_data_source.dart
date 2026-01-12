import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/auth_service.dart';

/// Remote data source untuk order letter payment API calls
abstract class OrderLetterPaymentRemoteDataSource {
  Future<Map<String, dynamic>> createPayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
    String? receiptImagePath,
    String? paymentDate,
  });

  Future<List<Map<String, dynamic>>> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  });
}

class OrderLetterPaymentRemoteDataSourceImpl
    implements OrderLetterPaymentRemoteDataSource {
  final Dio dio;

  OrderLetterPaymentRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> createPayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
    String? receiptImagePath,
    String? paymentDate,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw ServerException('Token tidak tersedia. Silakan login ulang.');
      }

      final url = ApiConfig.getCreateOrderLetterPaymentUrl(token: token);

      // Use FormData for multipart/form-data request (like Postman form-data)
      // Field names use array notation: order_letter_payment[field_name]
      final formData = FormData.fromMap({
        'order_letter_payment[order_letter_id]': orderLetterId.toString(),
        'order_letter_payment[payment_method]': paymentMethod,
        'order_letter_payment[payment_bank]': paymentBank,
        'order_letter_payment[payment_number]': paymentNumber,
        'order_letter_payment[payment_amount]': paymentAmount.toString(),
        'order_letter_payment[creator]': creator.toString(),
        if (note != null && note.trim().isNotEmpty)
          'order_letter_payment[note]': note.trim(),
        if (paymentDate != null && paymentDate.trim().isNotEmpty)
          'order_letter_payment[payment_date]': paymentDate.trim(),
        if (receiptImagePath != null && receiptImagePath.isNotEmpty)
          'order_letter_payment[image]': await MultipartFile.fromFile(
            receiptImagePath,
            filename: receiptImagePath.split('/').last,
          ),
      });

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) {
            // Accept all status codes to see the response body
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(
          'Gagal membuat payment (${response.statusCode}): ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw NetworkException(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        );
      } else if (e.response?.statusCode == 401 ||
          e.response?.statusCode == 403) {
        throw ServerException(
          'Tidak memiliki akses untuk membuat payment. Silakan login ulang.',
        );
      } else {
        throw ServerException(
          'Gagal membuat payment: ${e.message ?? "Unknown error"}',
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Error creating payment: ${e.toString()}');
    }
  }

  @override
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
          receiptImagePath: payment['receipt_image_path'] as String?,
          paymentDate: payment['payment_date'] as String?,
        );
        results.add(result);
      }

      return results;
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Error uploading payment methods: ${e.toString()}');
    }
  }
}

