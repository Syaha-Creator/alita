import 'package:dio/dio.dart';
import '../models/order_letter_model.dart';
import '../models/order_letter_detail_model.dart';

abstract class ApprovalRepository {
  Future<Map<String, dynamic>> createOrderLetter(OrderLetterModel orderLetter);
  Future<Map<String, dynamic>> createOrderLetterDetail(
      OrderLetterDetailModel detail);
  Future<List<OrderLetterModel>> getOrderLetters({String? creator});
  Future<List<OrderLetterDetailModel>> getOrderLetterDetails();
  Future<Map<String, dynamic>> postOrderLetterDiscounts(
      {required int orderLetterId, required List<double> discounts});

  Future<Map<String, dynamic>> createOrderLetterWithDiscounts(
      {required OrderLetterModel orderLetter, required List<double> discounts});
}

class ApprovalRepositoryImpl implements ApprovalRepository {
  final Dio dio;

  ApprovalRepositoryImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> createOrderLetter(
      OrderLetterModel orderLetter) async {
    try {
      final response = await dio.post(
        'https://alita.massindo.com/api/v1/order_letters?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
        data: orderLetter.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'orderLetterId': response.data['location']['id'],
          'noSp': response.data['location']['no_sp'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create order letter',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter: $e',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createOrderLetterDetail(
      OrderLetterDetailModel detail) async {
    try {
      final response = await dio.post(
        'https://alita.massindo.com/api/v1/order_letter_details?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
        data: detail.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create order letter detail',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order letter detail: $e',
      };
    }
  }

  @override
  Future<List<OrderLetterModel>> getOrderLetters({String? creator}) async {
    try {
      final response = await dio.get(
        'https://alita.massindo.com/api/v1/order_letters?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
      );

      if (response.statusCode == 200) {
        final List<dynamic> result = response.data['result'];
        final allOrderLetters =
            result.map((json) => OrderLetterModel.fromJson(json)).toList();

        // Debug logging
        print('ApprovalRepository: Raw API response: ${response.data}');
        print(
            'ApprovalRepository: First order letter discount: ${allOrderLetters.isNotEmpty ? allOrderLetters.first.discount : 'No data'}');

        // Filter by creator if provided
        if (creator != null) {
          final filteredLetters = allOrderLetters
              .where((orderLetter) =>
                  orderLetter.creator?.toLowerCase() == creator.toLowerCase())
              .toList();

          print(
              'ApprovalRepository: Filtered by creator "$creator": ${filteredLetters.length} items');
          if (filteredLetters.isNotEmpty) {
            print(
                'ApprovalRepository: First filtered order letter discount: ${filteredLetters.first.discount}');
          }

          return filteredLetters;
        }

        return allOrderLetters;
      } else {
        return [];
      }
    } catch (e) {
      print('ApprovalRepository: Error getting order letters: $e');
      return [];
    }
  }

  @override
  Future<List<OrderLetterDetailModel>> getOrderLetterDetails() async {
    try {
      final response = await dio.get(
        'https://alita.massindo.com/api/v1/order_letter_details?access_token=aRi9lLgtH1FxWWDcW7V9_mw91RrykDOqe3ADRTEffh0&client_id=UjQrHkqRaXgxrMnsuMQis-nbYp_jEbArPHSIN3QVQC8&client_secret=yOEtsL-v5SEg4WMDcCU6Qv7lDBhVpJIfPBpJKU68dV',
      );

      if (response.statusCode == 200) {
        final List<dynamic> result = response.data['result'];
        return result
            .map((json) => OrderLetterDetailModel.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  @override
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

  @override
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
        final orderLetterId = orderLetterResponse.data['location']['id'];

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
