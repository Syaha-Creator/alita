import 'package:dio/dio.dart';

import '../../../../config/api_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/auth_service.dart';

/// Remote data source untuk order letter contact API calls
abstract class OrderLetterContactRemoteDataSource {
  Future<Map<String, dynamic>> createPhoneContact({
    required int orderLetterId,
    required String phoneNumber,
  });

  Future<List<Map<String, dynamic>>> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  });
}

class OrderLetterContactRemoteDataSourceImpl
    implements OrderLetterContactRemoteDataSource {
  final Dio dio;

  OrderLetterContactRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> createPhoneContact({
    required int orderLetterId,
    required String phoneNumber,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw ServerException('Token tidak tersedia. Silakan login ulang.');
      }

      final url = ApiConfig.getCreateOrderLetterContactUrl(token: token);

      final requestData = {
        'order_letter_id': orderLetterId,
        'phone': phoneNumber,
      };

      final response = await dio.post(url, data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(
          'Gagal membuat phone contact: Status ${response.statusCode}',
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
          'Tidak memiliki akses untuk membuat contact. Silakan login ulang.',
        );
      } else {
        throw ServerException(
          'Gagal membuat phone contact: ${e.message ?? "Unknown error"}',
        );
      }
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Error creating phone contact: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  }) async {
    try {
      final List<Map<String, dynamic>> results = [];
      final List<String> phoneNumbers = [primaryPhone];

      // Add secondary phone if exists
      if (secondaryPhone != null && secondaryPhone.trim().isNotEmpty) {
        phoneNumbers.add(secondaryPhone.trim());
      }

      // Loop through all phone numbers and upload each one
      for (String phone in phoneNumbers) {
        final result = await createPhoneContact(
          orderLetterId: orderLetterId,
          phoneNumber: phone,
        );
        results.add(result);
      }

      return results;
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('Error uploading phone numbers: ${e.toString()}');
    }
  }
}

