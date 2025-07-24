import 'package:dio/dio.dart';
import '../../../../services/api_client.dart';
import '../models/order_letter_model.dart';
import '../models/order_letter_detail_model.dart';

class ApprovalRepository {
  final ApiClient apiClient;
  final Dio dio;

  ApprovalRepository(this.apiClient, this.dio);

  Future<Map<String, dynamic>> createApproval({
    required OrderLetterModel orderLetter,
    required List<OrderLetterDetailModel> details,
    required List<double> discounts,
  }) async {
    try {
      // Create order letter first
      final orderLetterResponse = await apiClient.post(
        '/api/order_letters',
        data: orderLetter.toJson(),
      );

      if (orderLetterResponse.statusCode != 201) {
        throw Exception('Failed to create order letter');
      }

      final orderLetterData = orderLetterResponse.data;
      final orderLetterId = orderLetterData['id'];

      // Create order letter details
      for (final detail in details) {
        final detailData = detail.toJson();
        detailData['order_letter_id'] = orderLetterId;

        final detailResponse = await apiClient.post(
          '/api/order_letter_details',
          data: detailData,
        );

        if (detailResponse.statusCode != 201) {
          throw Exception('Failed to create order letter detail');
        }
      }

      return {
        'success': true,
        'message': 'Approval created successfully',
        'orderLetterId': orderLetterId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getApprovals({String? creator}) async {
    try {
      final orderLetters = await getOrderLetters(creator: creator);
      final orderLetterDetails = await getOrderLetterDetails();

      return {
        'orderLetters': orderLetters,
        'orderLetterDetails': orderLetterDetails,
      };
    } catch (e) {
      return {
        'orderLetters': <OrderLetterModel>[],
        'orderLetterDetails': <OrderLetterDetailModel>[],
      };
    }
  }

  Future<List<OrderLetterModel>> getOrderLetters({String? creator}) async {
    try {
      String url = '/api/order_letters';
      if (creator != null) {
        url += '?creator=$creator';
      }

      final response = await apiClient.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderLetterModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error fetching order letters: $e');
      return [];
    }
  }

  Future<List<OrderLetterDetailModel>> getOrderLetterDetails() async {
    try {
      final response = await dio.get(
        'https://alita.massindo.com/api/v1/order_letter_details?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => OrderLetterDetailModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching order letter details: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> postOrderLetterDiscounts(
      {required int orderLetterId, required List<double> discounts}) async {
    try {
      final List<Map<String, dynamic>> discountResults = [];

      for (final discount in discounts) {
        final response = await dio.post(
          'https://alita.massindo.com/api/v1/order_letter_discounts?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
          data: {
            'order_letter_id': orderLetterId,
            'discount': discount,
          },
        );

        discountResults.add({
          'discount': discount,
          'success': response.statusCode == 200 || response.statusCode == 201,
          'message': response.data?['message'] ?? 'Discount posted',
        });
      }

      // Cek apakah semua discount berhasil di-post
      final allSuccess = discountResults.every((result) => result['success']);

      return {
        'success': allSuccess,
        'message': allSuccess
            ? 'All discounts posted successfully'
            : 'Some discounts failed to post',
        'results': discountResults,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error posting discounts: $e',
        'results': [],
      };
    }
  }

  Future<Map<String, dynamic>> createOrderLetterWithDiscounts(
      {required OrderLetterModel orderLetter,
      required List<double> discounts}) async {
    try {
      // POST Order Letter
      final orderLetterResponse = await dio.post(
        'https://alita.massindo.com/api/v1/order_letters?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
        data: orderLetter.toJson(),
      );

      if (orderLetterResponse.statusCode == 200 ||
          orderLetterResponse.statusCode == 201) {
        final orderLetterId = orderLetterResponse.data['id'];

        // POST Discounts
        final discountResult = await postOrderLetterDiscounts(
            orderLetterId: orderLetterId, discounts: discounts);

        return {
          'success': discountResult['success'],
          'message': discountResult['message'],
          'orderLetterId': orderLetterId,
          'discountResults': discountResult['results'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create order letter',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter with discounts: $e',
      };
    }
  }
}
