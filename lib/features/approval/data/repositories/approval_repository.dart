import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../models/approval_model.dart';
import '../../domain/entities/approval_entity.dart';

class ApprovalRepository {
  final OrderLetterService _orderLetterService = locator<OrderLetterService>();

  /// Get all order letters (approvals)
  Future<List<ApprovalEntity>> getApprovals({String? creator}) async {
    try {
      final orderLetters =
          await _orderLetterService.getOrderLetters(creator: creator);

      final List<ApprovalEntity> approvals = [];

      for (final orderLetter in orderLetters) {
        final orderLetterId = orderLetter['id'];
        final noSp = orderLetter['no_sp'];

        print(
            'ApprovalRepository: Processing order letter ID: $orderLetterId, No SP: $noSp');

        // Get details for this order letter
        final allDetails = await _orderLetterService.getOrderLetterDetails(
            orderLetterId: orderLetterId);

        // Filter details that belong to this specific order letter
        final details = allDetails
            .where((detail) => detail['order_letter_id'] == orderLetterId)
            .toList();

        print(
            'ApprovalRepository: Found ${allDetails.length} total details, filtered to ${details.length} for order letter $orderLetterId');
        for (final detail in details) {
          print(
              'ApprovalRepository: Detail - ID: ${detail['id']}, Order Letter ID: ${detail['order_letter_id']}, Desc: ${detail['desc_1']}');
        }

        // Get discounts for this order letter
        final allDiscounts = await _orderLetterService.getOrderLetterDiscounts(
            orderLetterId: orderLetterId);

        // Filter discounts that belong to this specific order letter
        final discounts = allDiscounts
            .where((discount) => discount['order_letter_id'] == orderLetterId)
            .toList();

        print(
            'ApprovalRepository: Found ${allDiscounts.length} total discounts, filtered to ${discounts.length} for order letter $orderLetterId');
        for (final discount in discounts) {
          print(
              'ApprovalRepository: Discount - ID: ${discount['id']}, Order Letter ID: ${discount['order_letter_id']}, Amount: ${discount['discount']}');
        }

        // Get approval history for this order letter
        final allApprovalHistory = await _orderLetterService
            .getOrderLetterApproves(orderLetterId: orderLetterId);

        // Filter approval history that belongs to this specific order letter
        final approvalHistory = allApprovalHistory
            .where((history) => history['order_letter_id'] == orderLetterId)
            .toList();

        // Create approval model
        final approval = ApprovalModel.fromJson({
          ...orderLetter,
          'details': details,
          'discounts': discounts,
          'approval_history': approvalHistory,
        });

        approvals.add(approval);
      }

      return approvals;
    } catch (e) {
      print('ApprovalRepository: Error getting approvals: $e');
      return [];
    }
  }

  /// Get single approval by ID
  Future<ApprovalEntity?> getApprovalById(int orderLetterId) async {
    try {
      final orderLetters = await _orderLetterService.getOrderLetters();
      final orderLetter = orderLetters.firstWhere(
        (ol) => ol['id'] == orderLetterId,
        orElse: () => {},
      );

      if (orderLetter.isEmpty) return null;

      // Get details for this order letter
      final allDetails = await _orderLetterService.getOrderLetterDetails(
          orderLetterId: orderLetterId);

      // Filter details that belong to this specific order letter
      final details = allDetails
          .where((detail) => detail['order_letter_id'] == orderLetterId)
          .toList();

      // Get discounts for this order letter
      final allDiscounts = await _orderLetterService.getOrderLetterDiscounts(
          orderLetterId: orderLetterId);

      // Filter discounts that belong to this specific order letter
      final discounts = allDiscounts
          .where((discount) => discount['order_letter_id'] == orderLetterId)
          .toList();

      // Get approval history for this order letter
      final allApprovalHistory = await _orderLetterService
          .getOrderLetterApproves(orderLetterId: orderLetterId);

      // Filter approval history that belongs to this specific order letter
      final approvalHistory = allApprovalHistory
          .where((history) => history['order_letter_id'] == orderLetterId)
          .toList();

      // Create approval model
      final approval = ApprovalModel.fromJson({
        ...orderLetter,
        'details': details,
        'discounts': discounts,
        'approval_history': approvalHistory,
      });

      return approval;
    } catch (e) {
      print('ApprovalRepository: Error getting approval by ID: $e');
      return null;
    }
  }

  /// Create approval (approve/reject order letter)
  Future<Map<String, dynamic>> createApproval({
    required int orderLetterId,
    required String action, // approve/reject
    required String approverName,
    required String approverEmail,
    String? comment,
  }) async {
    try {
      final approvalData = {
        'order_letter_id': orderLetterId,
        'approver_name': approverName,
        'approver_email': approverEmail,
        'action': action,
        'comment': comment,
      };

      final result =
          await _orderLetterService.createOrderLetterApprove(approvalData);

      if (result['success']) {
        // Update order letter status
        final updateData = {
          'status': action == 'approve' ? 'Approved' : 'Rejected',
        };

        // Note: We need to implement updateOrderLetter method in OrderLetterService
        // For now, we'll just return the approval result
        return result;
      }

      return result;
    } catch (e) {
      print('ApprovalRepository: Error creating approval: $e');
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }

  /// Get approvals by status
  Future<List<ApprovalEntity>> getApprovalsByStatus(String status) async {
    try {
      final allApprovals = await getApprovals();
      return allApprovals
          .where((approval) =>
              approval.status.toLowerCase() == status.toLowerCase())
          .toList();
    } catch (e) {
      print('ApprovalRepository: Error getting approvals by status: $e');
      return [];
    }
  }

  /// Get pending approvals
  Future<List<ApprovalEntity>> getPendingApprovals() async {
    return await getApprovalsByStatus('Pending');
  }

  /// Get approved approvals
  Future<List<ApprovalEntity>> getApprovedApprovals() async {
    return await getApprovalsByStatus('Approved');
  }

  /// Get rejected approvals
  Future<List<ApprovalEntity>> getRejectedApprovals() async {
    return await getApprovalsByStatus('Rejected');
  }
}
