import 'package:dio/dio.dart';
import '../../../../config/api_config.dart';
import '../../../../services/auth_service.dart';
import '../models/order_letter_document_model.dart';

class OrderLetterDocumentRepository {
  final Dio dio;

  OrderLetterDocumentRepository(this.dio);

  /// Get complete order letter document data including details, discounts, and approvals
  Future<OrderLetterDocumentModel?> getOrderLetterDocument(
      int orderLetterId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      // Get order letter data from the list endpoint and filter by ID
      final currentUserId = await AuthService.getCurrentUserId();
      final orderLettersUrl = ApiConfig.getOrderLettersUrl(
          token: token, creator: currentUserId.toString());
      final orderLettersResponse = await dio.get(orderLettersUrl);

      if (orderLettersResponse.statusCode != 200) {
        throw Exception('Failed to get order letters data');
      }

      final orderLettersData =
          orderLettersResponse.data['result'] ?? orderLettersResponse.data;
      final List<dynamic> orderLettersList =
          orderLettersData is List ? orderLettersData : [orderLettersData];

      // Find the specific order letter by ID
      final orderLetterData = orderLettersList.firstWhere(
        (orderLetter) => orderLetter['id'] == orderLetterId,
        orElse: () =>
            throw Exception('Order letter with ID $orderLetterId not found'),
      );

      print(
          'OrderLetterDocumentRepository: Found order letter data: $orderLetterData');
      print(
          'OrderLetterDocumentRepository: Order letter ID: ${orderLetterData['id']}');
      print(
          'OrderLetterDocumentRepository: No SP: ${orderLetterData['no_sp']}');
      print(
          'OrderLetterDocumentRepository: Status: ${orderLetterData['status']}');

      // Get order letter details
      final detailsUrl = ApiConfig.getOrderLetterDetailsUrl(
          token: token, orderLetterId: orderLetterId);
      final detailsResponse = await dio.get(detailsUrl);

      List<dynamic> detailsData = [];
      if (detailsResponse.statusCode == 200) {
        final detailsResult =
            detailsResponse.data['result'] ?? detailsResponse.data;
        final allDetails =
            detailsResult is List ? detailsResult : [detailsResult];

        // Filter details by order_letter_id
        detailsData = allDetails.where((detail) {
          final detailOrderLetterId = detail['order_letter_id'];
          return detailOrderLetterId == orderLetterId;
        }).toList();

        print(
            'OrderLetterDocumentRepository: Found ${allDetails.length} total details, filtered to ${detailsData.length} for order letter $orderLetterId');
      } else {
        print(
            'OrderLetterDocumentRepository: Details response status: ${detailsResponse.statusCode}');
      }

      // Get order letter discounts
      final discountsUrl = ApiConfig.getOrderLetterDiscountsUrl(
          token: token, orderLetterId: orderLetterId);
      final discountsResponse = await dio.get(discountsUrl);

      List<dynamic> discountsData = [];
      if (discountsResponse.statusCode == 200) {
        final discountsResult =
            discountsResponse.data['result'] ?? discountsResponse.data;
        final allDiscounts =
            discountsResult is List ? discountsResult : [discountsResult];

        // Filter discounts by order_letter_id
        discountsData = allDiscounts.where((discount) {
          final discountOrderLetterId = discount['order_letter_id'];
          return discountOrderLetterId == orderLetterId;
        }).toList();

        print(
            'OrderLetterDocumentRepository: Found ${allDiscounts.length} total discounts, filtered to ${discountsData.length} for order letter $orderLetterId');
        if (discountsData.isNotEmpty) {
          print(
              'OrderLetterDocumentRepository: First filtered discount: ${discountsData.first}');
        }
      } else {
        print(
            'OrderLetterDocumentRepository: Discounts response status: ${discountsResponse.statusCode}');
      }

      // Get order letter approvals
      final approvalsUrl = ApiConfig.getOrderLetterApprovesUrl(
          token: token, orderLetterId: orderLetterId);
      final approvalsResponse = await dio.get(approvalsUrl);

      List<dynamic> approvalsData = [];
      if (approvalsResponse.statusCode == 200) {
        final approvalsResult =
            approvalsResponse.data['result'] ?? approvalsResponse.data;
        final allApprovals =
            approvalsResult is List ? approvalsResult : [approvalsResult];

        // Filter approvals by order_letter_id (if available in approval data)
        approvalsData = allApprovals.where((approval) {
          final approvalOrderLetterId = approval['order_letter_id'];
          return approvalOrderLetterId == orderLetterId;
        }).toList();

        print(
            'OrderLetterDocumentRepository: Found ${allApprovals.length} total approvals, filtered to ${approvalsData.length} for order letter $orderLetterId');
      } else {
        print(
            'OrderLetterDocumentRepository: Approvals response status: ${approvalsResponse.statusCode}');
      }

      // Combine all data
      final combinedData = {
        ...orderLetterData,
        'details': detailsData,
        'discounts': discountsData,
        'approvals': approvalsData,
      };

      print('OrderLetterDocumentRepository: Combined data: $combinedData');

      return OrderLetterDocumentModel.fromJson(
          Map<String, dynamic>.from(combinedData));
    } catch (e) {
      print(
          'OrderLetterDocumentRepository: Error getting order letter document: $e');
      return null;
    }
  }

  /// Get all order letters for current user
  Future<List<OrderLetterDocumentModel>> getOrderLetters() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token not available');
      }

      final currentUserId = await AuthService.getCurrentUserId();
      final url = ApiConfig.getOrderLettersUrl(
          token: token, creator: currentUserId.toString());

      final response = await dio.get(url);

      if (response.statusCode != 200) {
        throw Exception('Failed to get order letters');
      }

      final data = response.data['result'] ?? response.data;
      final List<dynamic> orderLettersList = data is List ? data : [data];

      return orderLettersList
          .map((orderLetter) => OrderLetterDocumentModel.fromJson(orderLetter))
          .toList();
    } catch (e) {
      print('OrderLetterDocumentRepository: Error getting order letters: $e');
      return [];
    }
  }
}
