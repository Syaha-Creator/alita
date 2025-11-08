import 'package:flutter/foundation.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/team_hierarchy_service.dart';
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

      // Process order letters in parallel for better performance
      final approvalFutures = filteredOrderLetters.map((orderLetter) async {
        final orderLetterId = orderLetter['id'];

        // Make parallel API calls for details, discounts, and approvals
        final futures = [
          _orderLetterService.getOrderLetterDetails(
              orderLetterId: orderLetterId),
          _orderLetterService.getOrderLetterDiscounts(
              orderLetterId: orderLetterId),
          _orderLetterService.getOrderLetterApproves(
              orderLetterId: orderLetterId),
        ];

        // Wait for all API calls in parallel
        final results = await Future.wait(futures);
        final allDetails = results[0];
        final allDiscounts = results[1];
        final allApprovalHistory = results[2];

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

        // Filter discounts that belong to this specific order letter
        final apiDiscounts = allDiscounts
            .where((discount) => discount['order_letter_id'] == orderLetterId)
            .toList();

        // Combine extracted discounts with API discounts
        final discounts = [...extractedDiscounts, ...apiDiscounts];

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
      }).toList();

      // Wait for all order letters to be processed
      approvals.addAll(await Future.wait(approvalFutures));

      // Sort approvals by creation time (newest first) with improved date parsing
      approvals.sort((a, b) {
        // Primary: Use createdAt (actual creation time) for most accurate sorting
        DateTime? dateA = _parseDate(a.createdAt);
        DateTime? dateB = _parseDate(b.createdAt);

        // If creation dates are valid, use them for sorting
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Newest first
        }

        // Fallback 1: Use order date if createdAt is not available
        dateA ??= _parseDate(a.orderDate);
        dateB ??= _parseDate(b.orderDate);

        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Newest first
        }

        // Fallback 2: Use request date if order date parsing failed
        dateA ??= _parseDate(a.requestDate);
        dateB ??= _parseDate(b.requestDate);

        if (dateA != null && dateB != null) {
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
    ApprovalCache.getCachedApprovals();
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

  /// Update only approval statuses (lightweight operation)
  Future<List<ApprovalEntity>> updateApprovalStatusesOnly() async {
    try {
      // Get current cached approvals
      final cachedApprovals = ApprovalCache.getCachedApprovals();
      if (cachedApprovals == null || cachedApprovals.isEmpty) {
        // If cache is empty, do a full refresh instead
        return await getApprovals(forceRefresh: true);
      }

      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();
      if (currentUserId == null || currentUserName == null) {
        return cachedApprovals;
      }

      // Get order letters with minimal data (just status)
      final orderLetters = await _orderLetterService.getOrderLetters();

      // Filter order letters for current user
      final filteredOrderLetters = await _filterOrderLettersByCreatorOrApprover(
          orderLetters, currentUserId, currentUserName);

      // Create a map of order letter ID to status and full data
      final statusMap = <int, String>{};
      final orderLetterMap = <int, Map<String, dynamic>>{};

      for (final orderLetter in filteredOrderLetters) {
        final id = orderLetter['id'] as int?;
        final status = orderLetter['status'] as String?;
        if (id != null && status != null) {
          statusMap[id] = status;
          orderLetterMap[id] = orderLetter;
        }
      }

      // Find new order letters that are not in cache
      final cachedIds = cachedApprovals.map((a) => a.id).toSet();
      final newOrderLetterIds =
          statusMap.keys.where((id) => !cachedIds.contains(id)).toList();

      // Fetch full data for new order letters
      List<ApprovalEntity> newApprovals = [];
      for (final orderLetterId in newOrderLetterIds) {
        try {
          final orderLetter = orderLetterMap[orderLetterId];
          if (orderLetter == null) continue;

          // Get details, discounts, and approval history for new order letter
          final details = await _orderLetterService.getOrderLetterDetails(
              orderLetterId: orderLetterId);
          final discounts = await _orderLetterService.getOrderLetterDiscounts(
              orderLetterId: orderLetterId);
          final approvalHistory = await _orderLetterService
              .getOrderLetterApproves(orderLetterId: orderLetterId);

          // Create approval model for new order letter
          final newApproval = ApprovalModel.fromJson({
            ...orderLetter,
            'details': details,
            'discounts': discounts,
            'approval_history': approvalHistory,
          });

          newApprovals.add(newApproval);
        } catch (e) {
          // Skip this order letter if there's an error
          continue;
        }
      }

      // Update cached approvals with new statuses
      final updatedApprovals = cachedApprovals.map((cachedApproval) {
        final newStatus = statusMap[cachedApproval.id];
        if (newStatus != null && newStatus != cachedApproval.status) {
          // Create updated approval with new status using copyWith-like approach
          return ApprovalModel(
            id: cachedApproval.id,
            noSp: cachedApproval.noSp,
            orderDate: cachedApproval.orderDate,
            requestDate: cachedApproval.requestDate,
            creator: cachedApproval.creator,
            customerName: cachedApproval.customerName,
            phone: cachedApproval.phone,
            email: cachedApproval.email,
            address: cachedApproval.address,
            shipToName: cachedApproval.shipToName,
            addressShipTo: cachedApproval.addressShipTo,
            extendedAmount: cachedApproval.extendedAmount,
            hargaAwal: cachedApproval.hargaAwal,
            discount: cachedApproval.discount,
            note: cachedApproval.note,
            status: newStatus, // Updated status
            keterangan: cachedApproval.keterangan,
            createdAt: cachedApproval.createdAt,
            details: cachedApproval.details,
            discounts: cachedApproval.discounts,
            approvalHistory: cachedApproval.approvalHistory,
          );
        }
        return cachedApproval;
      }).toList();

      // Combine new approvals with updated approvals (new ones at the top)
      final combinedApprovals = [...newApprovals, ...updatedApprovals];

      // Sort by creation time to ensure newest first
      combinedApprovals.sort((a, b) {
        DateTime? dateA = _parseDate(a.createdAt);
        DateTime? dateB = _parseDate(b.createdAt);

        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Newest first
        }

        // Fallback to ID sorting
        return b.id.compareTo(a.id);
      });

      // Update cache with combined data
      ApprovalCache.cacheApprovals(combinedApprovals);

      return combinedApprovals;
    } catch (e) {
      // If status update fails, return cached data
      return ApprovalCache.getCachedApprovals() ?? [];
    }
  }

  /// Clear cache (useful for refresh)
  void clearCache() {
    ApprovalCache.clearAllCache();
  }

  /// Filter order letters based on team hierarchy (creator + subordinates)
  Future<List<Map<String, dynamic>>> _filterOrderLettersByCreatorOrApprover(
    List<Map<String, dynamic>> orderLetters,
    int currentUserId,
    String currentUserName,
  ) async {
    final List<Map<String, dynamic>> filteredLetters = [];

    // Get team hierarchy data
    final teamHierarchyService = locator<TeamHierarchyService>();
    final teamData = await teamHierarchyService.getTeamHierarchy();

    if (teamData == null) {
      // If team hierarchy data is not available, fallback to showing only current user's orders
      if (kDebugMode) {
        if (kDebugMode) {
          print(
              'ApprovalRepository: Team hierarchy data not available, showing only current user orders');
        }
      }
      return _filterByCurrentUserOnly(orderLetters, currentUserId);
    }

    // Get all subordinate user IDs (including nested teams)
    final subordinateUserIds = teamData.getAllSubordinateUserIds();

    if (kDebugMode) {
      if (kDebugMode) {
        print('ApprovalRepository: Current user ID: $currentUserId');
      }
      if (kDebugMode) {
        print(
            'ApprovalRepository: Has subordinates: ${teamData.hasSubordinates()}');
        if (kDebugMode) {
          print(
              'ApprovalRepository: Subordinate user IDs: $subordinateUserIds');
        }
      }
    }

    // Filter orders based on hierarchy
    for (final orderLetter in orderLetters) {
      final orderLetterId = orderLetter['id'] as int?;
      if (orderLetterId == null) continue;

      final creator = orderLetter['creator'];
      if (creator == null) continue;

      final creatorId = int.tryParse(creator.toString());
      if (creatorId == null) continue;

      // Check if creator is current user
      if (creatorId == currentUserId) {
        filteredLetters.add(orderLetter);
        continue;
      }

      // Check if creator is one of the subordinates
      if (subordinateUserIds.contains(creatorId)) {
        filteredLetters.add(orderLetter);
        continue;
      }

      // Check if current user is assigned as approver (e.g. analyst) for this order letter
      if (await _isUserApproverForOrderLetter(orderLetter, currentUserId)) {
        filteredLetters.add(orderLetter);
        continue;
      }
    }

    if (kDebugMode) {
      if (kDebugMode) {
        print(
            'ApprovalRepository: Filtered ${filteredLetters.length} orders out of ${orderLetters.length} total orders');
      }
    }
    return filteredLetters;
  }

  Future<bool> _isUserApproverForOrderLetter(
    Map<String, dynamic> orderLetter,
    int currentUserId,
  ) async {
    final orderLetterId = orderLetter['id'] as int?;
    if (orderLetterId == null) {
      return false;
    }

    bool matchesCurrentUser(dynamic value) {
      if (value == null) return false;
      final parsed = int.tryParse(value.toString());
      return parsed == currentUserId;
    }

    bool checkDiscountList(dynamic discountsData) {
      if (discountsData is List) {
        for (final discount in discountsData) {
          if (discount is Map<String, dynamic>) {
            final approver = discount['approver'] ?? discount['leader'];
            if (matchesCurrentUser(approver)) {
              return true;
            }
          }
        }
      }
      return false;
    }

    // Check discounts included directly in the order letter payload
    if (checkDiscountList(orderLetter['discounts'])) {
      return true;
    }

    // Check nested discounts inside details if present
    final detailsData = orderLetter['details'];
    if (detailsData is List) {
      for (final detail in detailsData) {
        if (detail is Map<String, dynamic>) {
          if (checkDiscountList(detail['order_letter_discount'])) {
            return true;
          }
        }
      }
    }

    // Check approval records if included
    final approvalsData = orderLetter['approvals'];
    if (approvalsData is List) {
      for (final approval in approvalsData) {
        if (approval is Map<String, dynamic>) {
          final leader = approval['leader'] ?? approval['approver'];
          if (matchesCurrentUser(leader)) {
            return true;
          }
        }
      }
    }

    // Fallback: fetch discounts from API for this order letter
    try {
      final discounts = await _orderLetterService.getOrderLetterDiscounts(
        orderLetterId: orderLetterId,
      );
      for (final discount in discounts) {
        final approver = discount['approver'] ?? discount['leader'];
        if (matchesCurrentUser(approver)) {
          return true;
        }
      }
    } catch (e) {
      // Ignore errors and treat as no match
    }

    return false;
  }

  /// Fallback method to filter only current user's orders
  List<Map<String, dynamic>> _filterByCurrentUserOnly(
    List<Map<String, dynamic>> orderLetters,
    int currentUserId,
  ) {
    final List<Map<String, dynamic>> filteredLetters = [];

    for (final orderLetter in orderLetters) {
      final orderLetterId = orderLetter['id'] as int?;
      if (orderLetterId == null) continue;

      final creator = orderLetter['creator'];

      // Check if creator is current user
      if (creator != null && creator.toString() == currentUserId.toString()) {
        filteredLetters.add(orderLetter);
      }
    }

    return filteredLetters;
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
        // Use parallel calls for better performance
        if (details.isEmpty || discounts.isEmpty || approvalHistory.isEmpty) {
          final futures = <Future>[];

          Future<List<Map<String, dynamic>>>? detailsFuture;
          Future<List<Map<String, dynamic>>>? discountsFuture;
          Future<List<Map<String, dynamic>>>? approvalHistoryFuture;

          if (details.isEmpty) {
            detailsFuture = _orderLetterService.getOrderLetterDetails(
                orderLetterId: orderLetterId);
            futures.add(detailsFuture);
          }

          if (discounts.isEmpty) {
            discountsFuture = _orderLetterService.getOrderLetterDiscounts(
                orderLetterId: orderLetterId);
            futures.add(discountsFuture);
          }

          if (approvalHistory.isEmpty) {
            approvalHistoryFuture = _orderLetterService.getOrderLetterApproves(
                orderLetterId: orderLetterId);
            futures.add(approvalHistoryFuture);
          }

          // Wait for all API calls in parallel
          await Future.wait(futures);

          // Process results
          if (details.isEmpty && detailsFuture != null) {
            final allDetails = await detailsFuture;
            details = allDetails
                .where((detail) => detail['order_letter_id'] == orderLetterId)
                .toList();
          }

          if (discounts.isEmpty && discountsFuture != null) {
            final allDiscounts = await discountsFuture;
            discounts = allDiscounts
                .where(
                    (discount) => discount['order_letter_id'] == orderLetterId)
                .toList();
          }

          if (approvalHistory.isEmpty && approvalHistoryFuture != null) {
            final allApprovalHistory = await approvalHistoryFuture;
            approvalHistory = allApprovalHistory
                .where(
                    (approval) => approval['order_letter_id'] == orderLetterId)
                .toList();
          }
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
