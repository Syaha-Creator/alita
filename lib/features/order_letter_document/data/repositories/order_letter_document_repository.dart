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

      // Get specific order letter data with complete information including contacts
      final orderLetterUrl = ApiConfig.getOrderLetterByIdUrl(
          token: token, orderLetterId: orderLetterId);
      final orderLetterResponse = await dio.get(orderLetterUrl);

      if (orderLetterResponse.statusCode != 200) {
        throw Exception('Failed to get order letter data');
      }

      final result = orderLetterResponse.data['result'];
      final orderLetterData = result['order_letter'];

      // Extract work place information from result
      final workPlaceName = result['work_place_name'];
      final workPlaceAddress = result['work_place_address'];

      // Extract details from the response (discounts are now nested in each detail)
      final detailsData = result['order_letter_details'] ?? [];

      // Extract all discounts from details for backward compatibility with the main model
      final List<dynamic> discountsData = [];
      for (final detail in detailsData) {
        final detailDiscounts = detail['order_letter_discount'] ?? [];
        for (final discount in detailDiscounts) {
          // Add the order_letter_detail_id to the discount for proper mapping
          discount['order_letter_detail_id'] =
              detail['order_letter_detail_id'] ?? detail['id'];
          discountsData.add(discount);
        }
      }

      // Extract approvals from discounts (they are nested in each discount)
      final List<dynamic> approvalsData = [];
      for (final discount in discountsData) {
        final discountApprovals = discount['order_letter_approves'] ?? [];
        for (final approval in discountApprovals) {
          // Add the order_letter_discount_id to the approval for proper mapping
          approval['order_letter_discount_id'] = discount['id'];
          approvalsData.add(approval);
        }
      }

      // Extract contacts from the response
      final contactsData = result['order_letter_contacts'] ?? [];

      // Extract payments from the response
      final paymentsData = result['order_letter_payments'] ?? [];

      // Combine all data
      final combinedData = {
        ...orderLetterData,
        'details': detailsData,
        'discounts': discountsData,
        'approvals': approvalsData,
        'contacts': contactsData,
        'payments': paymentsData,
        'work_place_name': workPlaceName,
        'work_place_address': workPlaceAddress,
      };

      return OrderLetterDocumentModel.fromJson(
          Map<String, dynamic>.from(combinedData));
    } catch (e) {
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
      return [];
    }
  }
}
