import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class OrderLetterContactService {
  final Dio _dio;

  OrderLetterContactService(this._dio);

  /// Create order letter contact with phone number (simple: only order_letter_id and phone)
  Future<Map<String, dynamic>> createPhoneContact({
    required int orderLetterId,
    required String phoneNumber,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final url = ApiConfig.getCreateOrderLetterContactUrl(token: token);

      final requestData = {
        'order_letter_id': orderLetterId,
        'phone': phoneNumber,
      };

      final response = await _dio.post(url, data: requestData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
            'Failed to create phone contact: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating phone contact: $e');
    }
  }

  /// Upload all phone numbers for an order letter (loop for each phone)
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
    } catch (e) {
      throw Exception('Error uploading phone numbers: $e');
    }
  }
}
