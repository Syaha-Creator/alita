import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class OrderLetterService {
  final Dio dio;

  OrderLetterService(this.dio);

  /// Create Order Letter with Details and Discounts
  Future<Map<String, dynamic>> createOrderLetterWithDetails({
    required Map<String, dynamic> orderLetterData,
    required List<Map<String, dynamic>> detailsData,
    required List<double> discountsData,
  }) async {
    try {
      print('OrderLetterService: Starting order letter creation');

      // Step 1: POST Order Letter
      final orderLetterResult = await createOrderLetter(orderLetterData);
      if (orderLetterResult['success'] != true) {
        return orderLetterResult;
      }

      // Extract order letter ID and no_sp from response
      final responseData = orderLetterResult['data'];
      print('OrderLetterService: Order letter response data: $responseData');

      int? orderLetterId;
      String? noSp;

      // Try different possible response formats
      if (responseData is Map<String, dynamic>) {
        // Try direct access
        orderLetterId = responseData['id'] ?? responseData['order_letter_id'];
        noSp = responseData['no_sp'] ?? responseData['no_sp_number'];

        // If still null, try nested access
        if (orderLetterId == null &&
            responseData['result'] is Map<String, dynamic>) {
          final result = responseData['result'] as Map<String, dynamic>;
          orderLetterId = result['id'] ?? result['order_letter_id'];
          noSp = result['no_sp'] ?? result['no_sp_number'];
        }

        // If still null, try array access
        if (orderLetterId == null &&
            responseData['result'] is List &&
            (responseData['result'] as List).isNotEmpty) {
          final firstResult = (responseData['result'] as List).first;
          if (firstResult is Map<String, dynamic>) {
            orderLetterId = firstResult['id'] ?? firstResult['order_letter_id'];
            noSp = firstResult['no_sp'] ?? firstResult['no_sp_number'];
          }
        }
      }

      print(
          'OrderLetterService: Extracted order letter ID: $orderLetterId, No SP: $noSp');

      // If we still don't have the ID, we need to fetch the latest order letter
      if (orderLetterId == null) {
        print(
            'OrderLetterService: Order letter ID is null, fetching latest order letter');
        final latestOrderLetters =
            await getOrderLetters(creator: orderLetterData['creator']);
        if (latestOrderLetters.isNotEmpty) {
          final latestOrder = latestOrderLetters.first;
          orderLetterId = latestOrder['id'] ?? latestOrder['order_letter_id'];
          noSp = latestOrder['no_sp'] ?? latestOrder['no_sp_number'];
          print(
              'OrderLetterService: Found latest order letter - ID: $orderLetterId, No SP: $noSp');
        }
      }

      if (orderLetterId == null) {
        return {
          'success': false,
          'message': 'Failed to get order letter ID from response',
          'responseData': responseData,
        };
      }

      // Step 2: POST Order Letter Details
      final List<Map<String, dynamic>> detailResults = [];
      for (final detail in detailsData) {
        final detailWithId = Map<String, dynamic>.from(detail);
        detailWithId['order_letter_id'] = orderLetterId;
        detailWithId['no_sp'] = noSp;

        final detailResult = await createOrderLetterDetail(detailWithId);
        detailResults.add(detailResult);

        if (detailResult['success']) {
          print('OrderLetterService: Detail created successfully');
        } else {
          print(
              'OrderLetterService: Failed to create detail: ${detailResult['message']}');
        }
      }

      // Step 3: POST Order Letter Discounts
      final List<Map<String, dynamic>> discountResults = [];
      for (final discount in discountsData) {
        // Find the main product (kasur) detail result to get its ID
        Map<String, dynamic>? kasurDetailResult;
        for (int i = 0; i < detailResults.length; i++) {
          final detailResult = detailResults[i];
          if (detailResult['success'] && detailResult['data'] != null) {
            final detailData = detailResult['data'];
            // Check if this is the main product (not bonus, divan, headboard, sorong)
            final originalDetail = detailsData[i];
            final itemType = originalDetail['item_type'];
            final desc1 = originalDetail['desc_1'];

            print(
                'OrderLetterService: Checking detail $i - itemType: $itemType, desc1: $desc1');

            // Main product is usually the first one (kasur) and not bonus/divan/headboard/sorong
            if (itemType == 'kasur' ||
                (itemType != 'Bonus' &&
                    !desc1.toLowerCase().contains('divan') &&
                    !desc1.toLowerCase().contains('headboard') &&
                    !desc1.toLowerCase().contains('sorong'))) {
              kasurDetailResult = detailResult;
              print(
                  'OrderLetterService: Found main product detail at index $i');
              break;
            }
          }
        }

        // Extract order_letter_detail_id from the result
        int? kasurOrderLetterDetailId;
        if (kasurDetailResult != null && kasurDetailResult['data'] != null) {
          final detailData = kasurDetailResult['data'];
          print('OrderLetterService: Detail data for kasur: $detailData');

          // Try to get ID from location object first (based on the log response)
          if (detailData['location'] != null &&
              detailData['location'] is Map<String, dynamic>) {
            final location = detailData['location'] as Map<String, dynamic>;
            kasurOrderLetterDetailId = location['id'];
            print(
                'OrderLetterService: Found kasur detail ID from location: $kasurOrderLetterDetailId');
          } else {
            // Fallback to direct access
            kasurOrderLetterDetailId = detailData['id'] ??
                detailData['order_letter_detail_id'] ??
                detailData['detail_id'];
            print(
                'OrderLetterService: Found kasur detail ID from direct access: $kasurOrderLetterDetailId');
          }
        }

        final discountData = {
          'order_letter_id': orderLetterId,
          'order_letter_detail_id': kasurOrderLetterDetailId,
          'discount': discount,
        };

        final discountResult = await createOrderLetterDiscount(discountData);
        discountResults.add(discountResult);

        if (discountResult['success']) {
          print('OrderLetterService: Discount created successfully');
        } else {
          print(
              'OrderLetterService: Failed to create discount: ${discountResult['message']}');
        }
      }

      // Check if all operations were successful
      final allDetailsSuccess =
          detailResults.every((result) => result['success']);
      final allDiscountsSuccess =
          discountResults.every((result) => result['success']);

      return {
        'success': allDetailsSuccess && allDiscountsSuccess,
        'message': allDetailsSuccess && allDiscountsSuccess
            ? 'Order letter created successfully with all details and discounts'
            : 'Order letter created but some details or discounts failed',
        'orderLetterId': orderLetterId,
        'noSp': noSp,
        'detailResults': detailResults,
        'discountResults': discountResults,
      };
    } catch (e) {
      print('OrderLetterService: Error in createOrderLetterWithDetails: $e');
      return {
        'success': false,
        'message': 'Error creating order letter: $e',
      };
    }
  }

  /// Create Order Letter
  Future<Map<String, dynamic>> createOrderLetter(
      Map<String, dynamic> orderLetterData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getCreateOrderLetterUrl(token: token);
      print(
          'OrderLetterService: Creating order letter with data: $orderLetterData');
      print(
          'OrderLetterService: Shipping fields in request: ship_to_code=${orderLetterData['ship_to_code']}, address_ship_to=${orderLetterData['address_ship_to']}');

      final response = await dio.post(url, data: orderLetterData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('OrderLetterService: Order letter response: ${response.data}');
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter created successfully',
        };
      } else {
        throw Exception(
            'Failed to create order letter: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error creating order letter: $e');
      return {
        'success': false,
        'message': 'Error creating order letter: $e',
      };
    }
  }

  /// Create Order Letter Detail
  Future<Map<String, dynamic>> createOrderLetterDetail(
      Map<String, dynamic> detailData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getCreateOrderLetterDetailUrl(token: token);
      print('OrderLetterService: Creating detail with data: $detailData');

      final response = await dio.post(url, data: detailData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter detail created successfully',
        };
      } else {
        throw Exception(
            'Failed to create order letter detail: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error creating order letter detail: $e');
      return {
        'success': false,
        'message': 'Error creating order letter detail: $e',
      };
    }
  }

  /// Create Order Letter Discount
  Future<Map<String, dynamic>> createOrderLetterDiscount(
      Map<String, dynamic> discountData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getCreateOrderLetterDiscountUrl(token: token);
      print('OrderLetterService: Creating discount with data: $discountData');

      final response = await dio.post(url, data: discountData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter discount created successfully',
        };
      } else {
        throw Exception(
            'Failed to create order letter discount: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error creating order letter discount: $e');
      return {
        'success': false,
        'message': 'Error creating order letter discount: $e',
      };
    }
  }

  /// Get Order Letters
  Future<List<Map<String, dynamic>>> getOrderLetters({String? creator}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLettersUrl(token: token, creator: creator);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letters: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letters: $e');
      return [];
    }
  }

  /// Get Order Letter Details
  Future<List<Map<String, dynamic>>> getOrderLetterDetails(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterDetailsUrl(
          token: token, orderLetterId: orderLetterId);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter details: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letter details: $e');
      return [];
    }
  }

  /// Get Order Letter Discounts
  Future<List<Map<String, dynamic>>> getOrderLetterDiscounts(
      {int? orderLetterId}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterDiscountsUrl(
          token: token, orderLetterId: orderLetterId);
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter discounts: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letter discounts: $e');
      return [];
    }
  }

  /// Get Order Letter Approves
  Future<List<Map<String, dynamic>>> getOrderLetterApproves({
    int? orderLetterId,
    String? approverId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getOrderLetterApprovesUrl(
        token: token,
        orderLetterId: orderLetterId,
        approverId: approverId,
      );
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['result'] is List) {
          return List<Map<String, dynamic>>.from(data['result']);
        }
        return [];
      } else {
        throw Exception(
            'Failed to fetch order letter approves: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error getting order letter approves: $e');
      return [];
    }
  }

  /// Create Order Letter Approve
  Future<Map<String, dynamic>> createOrderLetterApprove(
      Map<String, dynamic> approveData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not found');
      }

      final url = ApiConfig.getCreateOrderLetterApproveUrl(token: token);
      final response = await dio.post(url, data: approveData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Order letter approve created successfully',
        };
      } else {
        throw Exception(
            'Failed to create order letter approve: ${response.statusCode}');
      }
    } catch (e) {
      print('OrderLetterService: Error creating order letter approve: $e');
      return {
        'success': false,
        'message': 'Error creating order letter approve: $e',
      };
    }
  }
}
