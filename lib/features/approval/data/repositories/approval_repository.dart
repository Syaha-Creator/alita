import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/auth_service.dart';
import '../models/approval_model.dart';
import '../../domain/entities/approval_entity.dart';

class ApprovalRepository {
  final OrderLetterService _orderLetterService = locator<OrderLetterService>();

  /// Get all order letters (approvals) filtered by current user's hierarchy
  Future<List<ApprovalEntity>> getApprovals({String? creator}) async {
    try {
      // Get current user ID only (no need for leader data)
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return [];
      }

      // Get all order letters (without creator filter to see all orders where current user is approver)
      final allOrderLetters = await _orderLetterService.getOrderLetters();

      final filteredOrderLetters = await _filterOrderLettersByCreatorOrApprover(
          allOrderLetters, currentUserId, currentUserName);

      final List<ApprovalEntity> approvals = [];

      for (final orderLetter in filteredOrderLetters) {
        final orderLetterId = orderLetter['id'];
        final noSp = orderLetter['no_sp'];

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

        approvals.add(approval);
      }

      // Sort approvals by order date (newest first)
      approvals.sort((a, b) {
        try {
          final dateA = DateTime.parse(a.orderDate);
          final dateB = DateTime.parse(b.orderDate);
          return dateB.compareTo(dateA); // Newest first
        } catch (e) {
          // If date parsing fails, fallback to request date
          try {
            final dateA = DateTime.parse(a.requestDate);
            final dateB = DateTime.parse(b.requestDate);
            return dateB.compareTo(dateA); // Newest first
          } catch (e) {
            // If both dates fail, sort by ID (newest first)
            return b.id.compareTo(a.id);
          }
        }
      });

      return approvals;
    } catch (e) {
      return [];
    }
  }

  /// Filter order letters based on current user as creator OR approver (SEQUENTIAL)
  Future<List<Map<String, dynamic>>> _filterOrderLettersByCreatorOrApprover(
    List<Map<String, dynamic>> orderLetters,
    int currentUserId,
    String currentUserName,
  ) async {
    final List<Map<String, dynamic>> filteredLetters = [];

    for (final orderLetter in orderLetters) {
      final orderLetterId = orderLetter['id'];
      final status = orderLetter['status'] ?? 'Pending';
      final creator = orderLetter['creator'];

      // Check if current user is the creator
      bool isCurrentUserCreator = _isNameMatch(creator, currentUserName);

      if (isCurrentUserCreator) {
        filteredLetters.add(orderLetter);
        continue;
      }

      // Get discounts for this order letter
      final allDiscounts = await _orderLetterService.getOrderLetterDiscounts(
          orderLetterId: orderLetterId);

      // SEQUENTIAL APPROVAL LOGIC: Check if current user can approve based on previous levels
      bool canCurrentUserApprove = _canUserApproveSequentially(
        allDiscounts,
        currentUserId,
        currentUserName,
        orderLetterId,
      );

      if (canCurrentUserApprove) {
        filteredLetters.add(orderLetter);
      }
    }

    return filteredLetters;
  }

  /// Check if user can approve based on SEQUENTIAL approval logic
  bool _canUserApproveSequentially(
    List<Map<String, dynamic>> discounts,
    int currentUserId,
    String currentUserName,
    int orderLetterId,
  ) {
    // Sort discounts by approver_level_id to ensure sequential order
    final sortedDiscounts = List<Map<String, dynamic>>.from(discounts)
      ..sort((a, b) {
        final levelA = a['approver_level_id'] ?? 0;
        final levelB = b['approver_level_id'] ?? 0;
        return levelA.compareTo(levelB);
      });

    // Find current user's level and check if they have already approved
    int? currentUserLevel;
    int? currentUserDiscountId;
    bool hasUserApproved = false;

    for (final discount in sortedDiscounts) {
      if (discount['order_letter_id'] == orderLetterId) {
        final approverId = discount['approver'];
        final approverName = discount['approver_name'];
        final level = discount['approver_level_id'];
        final approved = discount['approved'];

        if (approverId == currentUserId ||
            _isNameMatch(approverName, currentUserName)) {
          currentUserLevel = level;
          currentUserDiscountId = discount['id'];
          hasUserApproved = approved == true;
          break;
        }
      }
    }

    if (currentUserLevel == null) {
      return false;
    }

    // If user has already approved, they can always see the approval (for tracking)
    if (hasUserApproved) {
      return true;
    }

    // If user hasn't approved yet, check sequential logic
    // For level 1 (User), always allow (auto-approved)
    if (currentUserLevel == 1) {
      return true;
    }

    // For level 2-5, check if immediate previous level is approved
    bool foundPreviousLevel = false;
    for (final discount in sortedDiscounts) {
      if (discount['order_letter_id'] == orderLetterId) {
        final level = discount['approver_level_id'];
        final approved = discount['approved'];

        // Check if this is the immediate previous level
        if (level != null && level == currentUserLevel - 1) {
          foundPreviousLevel = true;
          if (approved != true) {
            return false;
          } else {
            break;
          }
        }
      }
    }

    // If no previous level found, allow approval (for new order letters)
    if (!foundPreviousLevel) {
      return true;
    }

    // Check if current user's level is pending
    for (final discount in sortedDiscounts) {
      if (discount['order_letter_id'] == orderLetterId) {
        final level = discount['approver_level_id'];
        final approved = discount['approved'];
        final approverId = discount['approver'];
        final approverName = discount['approver_name'];

        if (level != null &&
            level == currentUserLevel &&
            (approverId == currentUserId ||
                _isNameMatch(approverName, currentUserName))) {
          if (approved == null || approved == false) {
            return true; // Can approve
          } else {
            return false; // Already approved
          }
        }
      }
    }

    return false;
  }

  /// Helper method to check if names match (with various fallbacks)
  bool _isNameMatch(String? creator, String userFullName) {
    if (creator == null) return false;

    // Exact match
    if (creator == userFullName) return true;

    // Trimmed match
    if (creator.trim() == userFullName.trim()) return true;

    // Case insensitive match
    if (creator.toLowerCase().trim() == userFullName.toLowerCase().trim()) {
      return true;
    }

    // Partial match
    if (creator.toLowerCase().contains(userFullName.toLowerCase()) ||
        userFullName.toLowerCase().contains(creator.toLowerCase())) {
      return true;
    }

    return false;
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
