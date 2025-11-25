import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        throw Exception(
            'Failed to get order letter data: Status ${orderLetterResponse.statusCode}');
      }

      // Ensure response data is a Map
      if (orderLetterResponse.data is! Map<String, dynamic>) {
        throw Exception(
            'Invalid response format: expected Map but got ${orderLetterResponse.data.runtimeType}');
      }

      final responseData = orderLetterResponse.data as Map<String, dynamic>;
      final result = responseData['result'];
      if (result == null) {
        throw Exception('Invalid response: result is null');
      }

      if (result is! Map<String, dynamic>) {
        throw Exception('Invalid response format: result is not a Map');
      }

      // After type check, result is guaranteed to be Map<String, dynamic>
      final resultMap = result;
      final orderLetterData = resultMap['order_letter'];
      if (orderLetterData == null) {
        throw Exception('Invalid response: order_letter is null');
      }

      // Extract work place information from result
      final workPlaceName = resultMap['work_place_name'];
      final workPlaceAddress = resultMap['work_place_address'];

      // Extract details from the response (discounts are now nested in each detail)
      final detailsData = resultMap['order_letter_details'] ?? [];

      // Extract all discounts from details for backward compatibility with the main model
      final List<dynamic> discountsData = [];
      for (final detail in detailsData) {
        if (detail is Map<String, dynamic>) {
          final detailId = detail['order_letter_detail_id'] ?? detail['id'];
          final detailDiscounts = detail['order_letter_discount'] ?? [];
          for (final discount in detailDiscounts) {
            if (discount is Map<String, dynamic>) {
              // Add the order_letter_detail_id to the discount for proper mapping
              if (detailId != null) {
                discount['order_letter_detail_id'] = detailId;
              }
              discountsData.add(discount);
            }
          }
        }
      }

      // Extract approvals from discounts (they are nested in each discount)
      final List<dynamic> approvalsData = [];
      for (final discount in discountsData) {
        if (discount is Map<String, dynamic>) {
          final discountId =
              discount['id'] ?? discount['order_letter_discount_id'];
          if (discountId == null) continue;

          final discountApprovals = discount['order_letter_approves'] ?? [];
          for (final approval in discountApprovals) {
            if (approval is Map<String, dynamic>) {
              // Add the order_letter_discount_id to the approval for proper mapping
              approval['order_letter_discount_id'] = discountId;
              approvalsData.add(approval);
            }
          }
        }
      }

      // Extract contacts from the response
      final contactsData = resultMap['order_letter_contacts'] ?? [];

      // Extract payments from the response
      final paymentsData = resultMap['order_letter_payments'] ?? [];

      // Combine all data - ensure orderLetterData is a Map before spreading
      final combinedData = <String, dynamic>{
        if (orderLetterData is Map<String, dynamic>) ...orderLetterData,
        'details': detailsData,
        'discounts': discountsData,
        'approvals': approvalsData,
        'contacts': contactsData,
        'payments': paymentsData,
        'work_place_name': workPlaceName,
        'work_place_address': workPlaceAddress,
      };

      return OrderLetterDocumentModel.fromJson(combinedData);
    } catch (e, stackTrace) {
      // Log error for debugging
      if (kDebugMode) {
        debugPrint('OrderLetterDocumentRepository: Error loading document: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      // Provide more user-friendly error messages
      String errorMessage = 'Gagal memuat dokumen';
      if (e.toString().contains('Token not available')) {
        errorMessage = 'Token tidak tersedia. Silakan login ulang.';
      } else if (e.toString().contains('Status 404')) {
        errorMessage = 'Dokumen tidak ditemukan (ID: $orderLetterId)';
      } else if (e.toString().contains('Status 401') || e.toString().contains('Status 403')) {
        errorMessage = 'Tidak memiliki akses untuk melihat dokumen ini';
      } else if (e.toString().contains('Invalid response format')) {
        errorMessage = 'Format data dari server tidak valid';
      } else if (e.toString().contains('order_letter is null')) {
        errorMessage = 'Data order letter tidak ditemukan';
      } else {
        errorMessage = 'Gagal memuat dokumen: ${e.toString()}';
      }
      
      throw Exception(errorMessage);
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
      if (currentUserId == null) {
        throw Exception('User ID not available');
      }
      final url = ApiConfig.getOrderLettersUrl(
          token: token, userId: currentUserId, creator: currentUserId.toString());

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
