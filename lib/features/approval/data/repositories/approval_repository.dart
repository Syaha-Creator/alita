import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/auth_service.dart';
import '../models/approval_model.dart';
import '../../domain/entities/approval_entity.dart';
import '../cache/approval_cache.dart';

class ApprovalRepository {
  final OrderLetterService _orderLetterService = locator<OrderLetterService>();

  /// Get all order letters (approvals) filtered by current user's hierarchy (optimized version with caching)
  Future<List<ApprovalEntity>> getApprovals(
      {String? creator, bool forceRefresh = false}) async {
    try {
      // Check cache first (if not force refresh)
      if (!forceRefresh) {
        final cachedApprovals = ApprovalCache.getCachedApprovals();
        if (cachedApprovals != null) {
          return cachedApprovals;
        }
      }

      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return [];
      }

      List<ApprovalEntity> approvals = [];

      // Try to get order letters with complete data first (optimized approach)
      try {
        final orderLettersWithData =
            await _orderLetterService.getOrderLettersWithCompleteData(
          includeDetails: true,
          includeDiscounts: true,
          includeApprovals: true,
        );

        if (orderLettersWithData.isNotEmpty) {
          approvals = await _processOrderLettersWithCompleteData(
            orderLettersWithData,
            currentUserId,
            currentUserName,
          );
        }
      } catch (e) {
        // Silently fall back to individual API calls
      }

      // Fallback to original approach if optimized method fails
      if (approvals.isEmpty) {
        approvals = await _getApprovalsOriginalMethod(
            currentUserId, currentUserName, creator);
      }

      // Cache the results
      ApprovalCache.cacheApprovals(approvals);

      return approvals;
    } catch (e) {
      // Return cached data if available, even if expired
      return ApprovalCache.getCachedApprovals() ?? [];
    }
  }

  /// Original method for getting approvals (fallback)
  Future<List<ApprovalEntity>> _getApprovalsOriginalMethod(
    int currentUserId,
    String currentUserName,
    String? creator,
  ) async {
    try {
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

        // Extract discount IDs from order_letter_discount in details
        final List<Map<String, dynamic>> extractedDiscounts = [];
        for (final detail in details) {
          if (detail['order_letter_discount'] != null) {
            final orderLetterDiscounts =
                detail['order_letter_discount'] as List;
            for (final discount in orderLetterDiscounts) {
              extractedDiscounts.add({
                'id': discount['order_letter_discount_id'],
                'order_letter_id': orderLetterId,
                'order_letter_detail_id': detail['order_letter_detail_id'],
                'discount': discount['discount'],
              });
            }
          }
        }

        // Get discounts for this order letter
        final allDiscounts = await _orderLetterService.getOrderLetterDiscounts(
            orderLetterId: orderLetterId);

        // Filter discounts that belong to this specific order letter
        final apiDiscounts = allDiscounts
            .where((discount) => discount['order_letter_id'] == orderLetterId)
            .toList();

        // Combine extracted discounts with API discounts
        final discounts = [...extractedDiscounts, ...apiDiscounts];

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

      // Sort approvals by creation time (newest first) with improved date parsing
      approvals.sort((a, b) {
        // Primary: Use createdAt (actual creation time) for most accurate sorting
        DateTime? dateA = _parseDate(a.createdAt);
        DateTime? dateB = _parseDate(b.createdAt);

        // If creation dates are valid, use them for sorting
        if (dateA != null && dateB != null) {
          print(
              'ApprovalRepository: Sorting by createdAt - A: ${a.createdAt} (rul), B: ${b.createdAt} ($dateB)');
          return dateB.compareTo(dateA); // Newest first
        }

        // Fallback 1: Use order date if createdAt is not available
        dateA ??= _parseDate(a.orderDate);
        dateB ??= _parseDate(b.orderDate);

        if (dateA != null && dateB != null) {
          print(
              'ApprovalRepository: Sorting by orderDate - A: ${a.orderDate} ($dateA), B: ${b.orderDate} ($dateB)');
          return dateB.compareTo(dateA); // Newest first
        }

        // Fallback 2: Use request date if order date parsing failed
        dateA ??= _parseDate(a.requestDate);
        dateB ??= _parseDate(b.requestDate);

        if (dateA != null && dateB != null) {
          print(
              'ApprovalRepository: Sorting by requestDate - A: ${a.requestDate} ($dateA), B: ${b.requestDate} ($dateB)');
          return dateB.compareTo(dateA); // Newest first
        }

        // Last resort: Sort by ID (newest first)
        return b.id.compareTo(a.id);
      });

      return approvals;
    } catch (e) {
      return [];
    }
  }

  /// Parse date string with multiple format support including ISO datetime with timezone
  DateTime? _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    try {
      // Try standard ISO format first (handles both date and datetime with timezone)
      final result = DateTime.parse(dateString);
      return result;
    } catch (e) {
      print(
          'ApprovalRepository: _parseDate - failed to parse "$dateString" with DateTime.parse: $e');
      try {
        // Try common date formats
        final formats = [
          'yyyy-MM-dd', // 2024-01-15
          'dd/MM/yyyy', // 15/01/2024
          'MM/dd/yyyy', // 01/15/2024
          'yyyy-MM-dd HH:mm:ss', // 2024-01-15 10:30:00
          'dd-MM-yyyy', // 15-01-2024
        ];

        for (final format in formats) {
          try {
            // Simple parsing for common formats
            if (format == 'yyyy-MM-dd' && dateString.length == 10) {
              final parts = dateString.split('-');
              if (parts.length == 3) {
                final result = DateTime(
                  int.parse(parts[0]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[2]), // day
                );
                return result;
              }
            } else if (format == 'dd/MM/yyyy' && dateString.contains('/')) {
              final parts = dateString.split('/');
              if (parts.length == 3) {
                final result = DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[1]), // month
                  int.parse(parts[0]), // day
                );
                return result;
              }
            } else if (format == 'MM/dd/yyyy' && dateString.contains('/')) {
              final parts = dateString.split('/');
              if (parts.length == 3) {
                final result = DateTime(
                  int.parse(parts[2]), // year
                  int.parse(parts[0]), // month
                  int.parse(parts[1]), // day
                );
                return result;
              }
            }
          } catch (e) {
            continue;
          }
        }

        print(
            'ApprovalRepository: _parseDate - failed to parse "$dateString" with any format');
        return null;
      } catch (e) {
        return null;
      }
    }
  }

  /// Get discounts for timeline with caching
  Future<List<Map<String, dynamic>>> getDiscountsForTimeline(
      int orderLetterId) async {
    try {
      // Check cache first
      final cachedDiscounts = ApprovalCache.getCachedDiscounts(orderLetterId);
      if (cachedDiscounts != null) {
        return cachedDiscounts;
      }

      // Fetch from API
      final discounts = await _orderLetterService.getOrderLetterDiscounts(
        orderLetterId: orderLetterId,
      );

      // Cache the results
      ApprovalCache.cacheDiscounts(orderLetterId, discounts);

      return discounts;
    } catch (e) {
      return ApprovalCache.getCachedDiscounts(orderLetterId) ?? [];
    }
  }

  /// Get cached user info
  Map<String, dynamic>? getCachedUserInfo() {
    return ApprovalCache.getCachedUserInfo();
  }

  /// Cache user info
  void cacheUserInfo(Map<String, dynamic> userInfo) {
    ApprovalCache.cacheUserInfo(userInfo);
  }

  /// Get approvals with pagination support
  Future<List<ApprovalEntity>> getApprovalsWithPagination({
    String? creator,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    try {
      // First, ensure we have all data loaded
      await getApprovals(creator: creator, forceRefresh: forceRefresh);

      // Check if pagination should be used
      if (ApprovalCache.shouldUsePagination()) {
        final paginatedApprovals = ApprovalCache.getPaginatedApprovals(page);
        print(
            'ApprovalRepository: Returning page $page with ${paginatedApprovals.length} items');
        return paginatedApprovals;
      } else {
        // Return all data if pagination not needed
        return ApprovalCache.getCachedApprovals() ?? [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get pagination info
  Map<String, dynamic> getPaginationInfo() {
    return {
      'should_use_pagination': ApprovalCache.shouldUsePagination(),
      'total_pages': ApprovalCache.getTotalPages(),
      'items_per_page': ApprovalCache.itemsPerPage,
      'total_items': ApprovalCache.getCachedApprovals()?.length ?? 0,
      'lazy_load_threshold': ApprovalCache.lazyLoadThreshold,
    };
  }

  /// Background sync - refresh cache if needed
  Future<void> backgroundSync() async {
    try {
      if (!ApprovalCache.needsBackgroundSync()) {
        return;
      }

      // Refresh data in background without clearing cache immediately
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return;
      }

      List<ApprovalEntity> newApprovals = [];

      // Try optimized approach first
      try {
        final orderLettersWithData =
            await _orderLetterService.getOrderLettersWithCompleteData(
          includeDetails: true,
          includeDiscounts: true,
          includeApprovals: true,
        );

        if (orderLettersWithData.isNotEmpty) {
          newApprovals = await _processOrderLettersWithCompleteData(
            orderLettersWithData,
            currentUserId,
            currentUserName,
          );
        }
      } catch (e) {
        print(
            'ApprovalRepository: Background sync - optimized approach failed: $e');
        // Fallback to original method
        newApprovals = await _getApprovalsOriginalMethod(
            currentUserId, currentUserName, null);
      }

      // Smart update: only update cache if data actually changed
      final currentCache = ApprovalCache.getCachedApprovals();
      if (currentCache == null || _hasDataChanged(currentCache, newApprovals)) {
        ApprovalCache.cacheApprovals(newApprovals);
      }

      ApprovalCache.markBackgroundSyncCompleted();
    } catch (e) {
      //
    }
  }

  /// Force use cache only (for testing cache effectiveness)
  Future<List<ApprovalEntity>> getApprovalsFromCacheOnly() async {
    final cachedApprovals = ApprovalCache.getCachedApprovals();
    if (cachedApprovals != null) {
      return cachedApprovals;
    } else {
      return [];
    }
  }

  /// Test cache performance
  void testCachePerformance() async {
    final stopwatch = Stopwatch()..start();

    // Test cache access
    final cachedData = ApprovalCache.getCachedApprovals();
    stopwatch.stop();
  }

  /// Update specific approval without full refresh
  Future<ApprovalEntity?> updateSingleApproval(int orderLetterId) async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return null;
      }

      // Get updated data for this specific order letter
      final orderLetters = await _orderLetterService.getOrderLetters();
      final orderLetter = orderLetters.firstWhere(
        (ol) => ol['id'] == orderLetterId,
        orElse: () => {},
      );

      if (orderLetter.isEmpty) return null;

      // Get updated details, discounts, and approvals for this order letter
      final details = await _orderLetterService.getOrderLetterDetails(
          orderLetterId: orderLetterId);
      final discounts = await _orderLetterService.getOrderLetterDiscounts(
          orderLetterId: orderLetterId);
      final approvalHistory = await _orderLetterService.getOrderLetterApproves(
          orderLetterId: orderLetterId);

      // Create updated approval model
      final updatedApproval = ApprovalModel.fromJson({
        ...orderLetter,
        'details': details,
        'discounts': discounts,
        'approval_history': approvalHistory,
      });

      // Update in cache
      final updated = ApprovalCache.updateApprovalInCache(updatedApproval);
      if (updated) {
        // Also clear discount cache for this order letter to force refresh
        ApprovalCache.clearDiscountCache(orderLetterId);
      }

      return updatedApproval;
    } catch (e) {
      return null;
    }
  }

  /// Refresh only specific approval by ID (efficient single-item update)
  Future<bool> refreshSingleApproval(int orderLetterId) async {
    final updatedApproval = await updateSingleApproval(orderLetterId);
    return updatedApproval != null;
  }

  /// Check if approval data has changed (for smart background sync)
  bool _hasDataChanged(
      List<ApprovalEntity> oldData, List<ApprovalEntity> newData) {
    if (oldData.length != newData.length) return true;

    // Check if any approval status or key fields have changed
    for (int i = 0; i < oldData.length; i++) {
      final oldApproval = oldData[i];
      final newApproval = newData.firstWhere(
        (approval) => approval.id == oldApproval.id,
        orElse: () => oldApproval, // If not found, consider as changed
      );

      // Check key fields that matter for UI
      if (oldApproval.status != newApproval.status ||
          oldApproval.createdAt != newApproval.createdAt ||
          oldApproval.discounts.length != newApproval.discounts.length) {
        return true;
      }
    }

    return false;
  }

  /// Load new approvals incrementally (for after checkout)
  Future<List<ApprovalEntity>> loadNewApprovalsIncremental() async {
    try {
      // Set loading state
      ApprovalCache.setLoadingNewData(true);

      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        ApprovalCache.setLoadingNewData(false);
        return ApprovalCache.getCachedApprovals() ?? [];
      }

      // Get fresh data from server
      List<ApprovalEntity> freshApprovals = [];

      try {
        final orderLettersWithData =
            await _orderLetterService.getOrderLettersWithCompleteData(
          includeDetails: true,
          includeDiscounts: true,
          includeApprovals: true,
        );

        if (orderLettersWithData.isNotEmpty) {
          freshApprovals = await _processOrderLettersWithCompleteData(
            orderLettersWithData,
            currentUserId,
            currentUserName,
          );
        }
      } catch (e) {
        // Fallback to original method
        freshApprovals = await _getApprovalsOriginalMethod(
            currentUserId, currentUserName, null);
      }

      // Find new approvals that are not in cache
      final cachedApprovals = ApprovalCache.getCachedApprovals() ?? [];
      final newApprovals = freshApprovals
          .where((fresh) =>
              !cachedApprovals.any((cached) => cached.id == fresh.id))
          .toList();

      // Store pending new approvals
      ApprovalCache.setPendingNewApprovals(newApprovals);

      // Merge and update cache
      ApprovalCache.mergePendingApprovals();

      return ApprovalCache.getCachedApprovals() ?? [];
    } catch (e) {
      ApprovalCache.setLoadingNewData(false);
      return ApprovalCache.getCachedApprovals() ?? [];
    }
  }

  /// Clear cache (useful for refresh)
  void clearCache() {
    ApprovalCache.clearAllCache();
  }

  /// Filter order letters based on current user as creator OR approver (SEQUENTIAL) - optimized version
  Future<List<Map<String, dynamic>>> _filterOrderLettersByCreatorOrApprover(
    List<Map<String, dynamic>> orderLetters,
    int currentUserId,
    String currentUserName,
  ) async {
    final List<Map<String, dynamic>> filteredLetters = [];

    // Get all discounts in bulk first to avoid individual API calls
    Map<int, List<Map<String, dynamic>>> discountsByOrderLetter = {};

    try {
      // Try to get all discounts in one call
      final allDiscounts = await _orderLetterService.getOrderLetterDiscounts();

      // Group discounts by order_letter_id
      for (final discount in allDiscounts) {
        final orderLetterId = discount['order_letter_id'] as int?;
        if (orderLetterId != null) {
          discountsByOrderLetter[orderLetterId] ??= [];
          discountsByOrderLetter[orderLetterId]!.add(discount);
        }
      }
    } catch (e) {
      // Silently fall back to individual calls if needed
    }

    for (final orderLetter in orderLetters) {
      final orderLetterId = orderLetter['id'] as int?;
      if (orderLetterId == null) continue;

      final status = orderLetter['status'] ?? 'Pending';
      final creator = orderLetter['creator'];

      // Check if current user is the creator
      bool isCurrentUserCreator = _isNameMatch(creator, currentUserName);

      if (isCurrentUserCreator) {
        filteredLetters.add(orderLetter);
        continue;
      }

      // Get discounts for this order letter (use cached data if available)
      List<Map<String, dynamic>> orderDiscounts =
          discountsByOrderLetter[orderLetterId] ?? [];

      // If no cached data, fall back to individual API call
      if (orderDiscounts.isEmpty) {
        try {
          final allDiscounts = await _orderLetterService
              .getOrderLetterDiscounts(orderLetterId: orderLetterId);
          orderDiscounts = allDiscounts
              .where((discount) => discount['order_letter_id'] == orderLetterId)
              .toList();
        } catch (e) {
          print(
              'ApprovalRepository: Failed to get discounts for order $orderLetterId: $e');
          continue;
        }
      }

      // SEQUENTIAL APPROVAL LOGIC: Check if current user can approve based on previous levels
      bool canCurrentUserApprove = _canUserApproveSequentially(
        orderDiscounts,
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

  /// Process order letters that already contain complete data (optimized approach)
  Future<List<ApprovalEntity>> _processOrderLettersWithCompleteData(
    List<Map<String, dynamic>> orderLettersWithData,
    int currentUserId,
    String currentUserName,
  ) async {
    try {
      // Filter order letters for current user (creator or approver)
      final filteredOrderLetters = await _filterOrderLettersByCreatorOrApprover(
          orderLettersWithData, currentUserId, currentUserName);

      final List<ApprovalEntity> approvals = [];

      for (final orderLetter in filteredOrderLetters) {
        final orderLetterId = orderLetter['id'];

        // Extract data that should already be included in the response
        List<Map<String, dynamic>> details = [];
        List<Map<String, dynamic>> discounts = [];
        List<Map<String, dynamic>> approvalHistory = [];

        // Check if data is already included in the response
        if (orderLetter['details'] != null) {
          final detailsData = orderLetter['details'];
          if (detailsData is List) {
            details = List<Map<String, dynamic>>.from(detailsData)
                .where((detail) => detail['order_letter_id'] == orderLetterId)
                .toList();
          }
        }

        if (orderLetter['discounts'] != null) {
          final discountsData = orderLetter['discounts'];
          if (discountsData is List) {
            discounts = List<Map<String, dynamic>>.from(discountsData)
                .where(
                    (discount) => discount['order_letter_id'] == orderLetterId)
                .toList();
          }
        }

        if (orderLetter['approvals'] != null) {
          final approvalsData = orderLetter['approvals'];
          if (approvalsData is List) {
            approvalHistory = List<Map<String, dynamic>>.from(approvalsData)
                .where(
                    (approval) => approval['order_letter_id'] == orderLetterId)
                .toList();
          }
        }

        // If data is not included, fall back to individual API calls for this order letter
        if (details.isEmpty) {
          final allDetails = await _orderLetterService.getOrderLetterDetails(
              orderLetterId: orderLetterId);
          details = allDetails
              .where((detail) => detail['order_letter_id'] == orderLetterId)
              .toList();
        }

        if (discounts.isEmpty) {
          final allDiscounts = await _orderLetterService
              .getOrderLetterDiscounts(orderLetterId: orderLetterId);
          discounts = allDiscounts
              .where((discount) => discount['order_letter_id'] == orderLetterId)
              .toList();
        }

        if (approvalHistory.isEmpty) {
          final allApprovalHistory = await _orderLetterService
              .getOrderLetterApproves(orderLetterId: orderLetterId);
          approvalHistory = allApprovalHistory
              .where((approval) => approval['order_letter_id'] == orderLetterId)
              .toList();
        }

        // Create approval model
        final approval = ApprovalModel.fromJson({
          ...orderLetter,
          'details': details,
          'discounts': discounts,
          'approval_history': approvalHistory,
        });

        approvals.add(approval);
      }

      // Sort approvals by creation time (newest first)
      approvals.sort((a, b) {
        DateTime? dateA = _parseDate(a.createdAt);
        DateTime? dateB = _parseDate(b.createdAt);

        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA);
        }

        // Fallback sorting by ID if dates are not available
        return b.id.compareTo(a.id);
      });

      return approvals;
    } catch (e) {
      return [];
    }
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

  /// Get approvals by status (optimized with caching)
  Future<List<ApprovalEntity>> getApprovalsByStatus(String status,
      {bool forceRefresh = false}) async {
    try {
      // Use optimized getApprovals with caching
      final allApprovals = await getApprovals(forceRefresh: forceRefresh);
      final filteredApprovals = allApprovals
          .where((approval) =>
              approval.status.toLowerCase() == status.toLowerCase())
          .toList();

      return filteredApprovals;
    } catch (e) {
      return [];
    }
  }

  /// Get pending approvals (optimized with caching)
  Future<List<ApprovalEntity>> getPendingApprovals(
      {bool forceRefresh = false}) async {
    return await getApprovalsByStatus('Pending', forceRefresh: forceRefresh);
  }

  /// Get approved approvals (optimized with caching)
  Future<List<ApprovalEntity>> getApprovedApprovals(
      {bool forceRefresh = false}) async {
    return await getApprovalsByStatus('Approved', forceRefresh: forceRefresh);
  }

  /// Get rejected approvals (optimized with caching)
  Future<List<ApprovalEntity>> getRejectedApprovals(
      {bool forceRefresh = false}) async {
    return await getApprovalsByStatus('Rejected', forceRefresh: forceRefresh);
  }
}
