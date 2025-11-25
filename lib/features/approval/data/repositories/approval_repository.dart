import '../../../../config/dependency_injection.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/leader_service.dart';
import '../../../../services/location_service.dart';
import '../models/approval_model.dart';
import '../../domain/entities/approval_entity.dart';
import '../cache/approval_cache.dart';

class ApprovalRepository {
  final OrderLetterService _orderLetterService = locator<OrderLetterService>();

  /// Get all order letters (approvals) filtered by current user's role
  /// The backend API automatically filters based on user role:
  /// - order_letters_by_direct_leader (supervisor with subordinates)
  /// - order_letters_by_indirect_leader (Regional Manager/Manager)
  /// - order_letters_by_analyst (Analyst)
  /// - order_letters_by_controller (Controller)
  /// - order_letters (Staff - default)
  Future<List<ApprovalEntity>> getApprovals(
      {String? creator, bool forceRefresh = false}) async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return [];
      }

      // Check cache first (if not force refresh)
      if (!forceRefresh) {
        final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
        if (cachedApprovals != null) {
          return cachedApprovals;
        }
      }

      // Get order letters with new format (includes details, discounts, etc.)
      final response = await _orderLetterService.getOrderLetters();

      // Process new response format: { status: "success", result: [...] }
      // Each result item has: order_letter, order_letter_details, order_letter_contacts, etc.
      // Convert filtered order letters to ApprovalEntity with complete data
      final List<ApprovalEntity> approvals = [];

      for (final item in response) {
        // Check if this is the new format with nested structure
        if (item.containsKey('order_letter')) {
          // New format: extract order_letter and related data
          final orderLetter = item['order_letter'] as Map<String, dynamic>;

          // Filter order letters by creator or approver (with full item data for approver check)
          final shouldInclude = await _shouldIncludeOrderLetter(
              orderLetter, item, currentUserId, currentUserName);
          if (!shouldInclude) continue;

          final orderLetterDetails =
              item['order_letter_details'] as List<dynamic>? ?? [];

          // Extract discounts from order_letter_details (nested in each detail)
          final List<Map<String, dynamic>> allDiscounts = [];
          final List<Map<String, dynamic>> allDetails = [];

          for (final detailData in orderLetterDetails) {
            if (detailData is Map<String, dynamic>) {
              // Extract detail
              final detail = Map<String, dynamic>.from(detailData);
              final orderLetterDiscounts =
                  detail['order_letter_discount'] as List<dynamic>? ?? [];

              // Remove nested discount from detail
              final detailWithoutDiscount = Map<String, dynamic>.from(detail);
              detailWithoutDiscount.remove('order_letter_discount');
              allDetails.add(detailWithoutDiscount);

              // Extract discounts from this detail
              for (final discountData in orderLetterDiscounts) {
                if (discountData is Map<String, dynamic>) {
                  final discount = Map<String, dynamic>.from(discountData);
                  discount['order_letter_detail_id'] =
                      detail['order_letter_detail_id'] ?? detail['id'];
                  allDiscounts.add(discount);
                }
              }
            }
          }

          // Extract approval history from discounts
          final List<Map<String, dynamic>> allApprovalHistory = [];
          for (final discount in allDiscounts) {
            final orderLetterApproves =
                discount['order_letter_approves'] as List<dynamic>? ?? [];
            for (final approveData in orderLetterApproves) {
              if (approveData is Map<String, dynamic>) {
                final approval = Map<String, dynamic>.from(approveData);
                approval['order_letter_id'] = orderLetter['id'];
                approval['order_letter_discount_id'] =
                    discount['order_letter_discount_id'] ?? discount['id'];
                allApprovalHistory.add(approval);
              }
            }
          }

          // Convert to ApprovalEntity with complete data
          final approval = ApprovalModel.fromJson({
            ...orderLetter,
            'details': allDetails,
            'discounts': allDiscounts,
            'approval_history': allApprovalHistory,
          });

          approvals.add(approval);
        } else {
          // Old format: direct order letter object
          // Filter order letters by creator or approver
          final shouldInclude = await _shouldIncludeOrderLetter(
              item, item, currentUserId, currentUserName);
          if (!shouldInclude) continue;

          final approval = _convertOrderLetterToApprovalEntity(item);
          approvals.add(approval);
        }
      }

      // Sort approvals by creation time (newest first)
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

      // Only cache if we have approvals (don't overwrite cache with empty list)
      if (approvals.isNotEmpty) {
        ApprovalCache.cacheApprovals(currentUserId, approvals);
      }

      // If we got empty list but have cached data, return cached data instead
      if (approvals.isEmpty) {
        final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
        if (cachedApprovals != null && cachedApprovals.isNotEmpty) {
          return cachedApprovals;
        }
      }

      return approvals;
    } catch (e) {
      // Return cached data if available, even if expired (don't return empty list)
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];
      final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
      if (cachedApprovals != null && cachedApprovals.isNotEmpty) {
        return cachedApprovals;
      }
      // Only return empty list if there's really no cached data
      return [];
    }
  }

  /// Convert order letter Map to ApprovalEntity (simplified version - for backward compatibility)
  ApprovalEntity _convertOrderLetterToApprovalEntity(
      Map<String, dynamic> orderLetter) {
    final id = orderLetter['id'] as int? ?? 0;
    final noSp = orderLetter['no_sp']?.toString() ?? '';
    final orderDate = orderLetter['order_date']?.toString() ?? '';
    final requestDate = orderLetter['request_date']?.toString() ?? '';
    final creator = orderLetter['creator']?.toString() ?? '';
    final customerName = orderLetter['customer_name']?.toString() ?? '';
    final phone = orderLetter['phone']?.toString() ?? '';
    final email = orderLetter['email']?.toString() ?? '';
    final address = orderLetter['address']?.toString() ?? '';
    final shipToName = orderLetter['ship_to_name']?.toString();
    final addressShipTo = orderLetter['address_ship_to']?.toString();

    // Parse extended_amount (can be String or double)
    double extendedAmount = 0.0;
    final extendedAmountValue = orderLetter['extended_amount'];
    if (extendedAmountValue != null) {
      if (extendedAmountValue is double) {
        extendedAmount = extendedAmountValue;
      } else if (extendedAmountValue is String) {
        extendedAmount = double.tryParse(extendedAmountValue) ?? 0.0;
      } else if (extendedAmountValue is int) {
        extendedAmount = extendedAmountValue.toDouble();
      }
    }

    // Parse harga_awal
    int hargaAwal = 0;
    final hargaAwalValue = orderLetter['harga_awal'];
    if (hargaAwalValue != null) {
      if (hargaAwalValue is int) {
        hargaAwal = hargaAwalValue;
      } else if (hargaAwalValue is String) {
        hargaAwal = int.tryParse(hargaAwalValue) ?? 0;
      } else if (hargaAwalValue is double) {
        hargaAwal = hargaAwalValue.toInt();
      }
    }

    // Parse discount (can be String or double)
    double? discount;
    final discountValue = orderLetter['discount'];
    if (discountValue != null) {
      if (discountValue is double) {
        discount = discountValue;
      } else if (discountValue is String) {
        discount = double.tryParse(discountValue);
      } else if (discountValue is int) {
        discount = discountValue.toDouble();
      }
    }

    final note = orderLetter['note']?.toString() ?? '';
    final status = orderLetter['status']?.toString() ?? 'Pending';
    final spgCode = orderLetter['sales_code']?.toString();
    final keterangan = orderLetter['keterangan']?.toString();
    final createdAt = orderLetter['created_at']?.toString();

    // Parse take_away (can be bool, String, or null)
    bool? takeAway;
    final takeAwayValue = orderLetter['take_away'];
    if (takeAwayValue != null) {
      if (takeAwayValue is bool) {
        takeAway = takeAwayValue;
      } else if (takeAwayValue is String) {
        final lowerValue = takeAwayValue.toLowerCase();
        takeAway = lowerValue == 'true' ||
            lowerValue == 'take away' ||
            lowerValue == '1';
      } else if (takeAwayValue is int) {
        takeAway = takeAwayValue == 1;
      }
    }

    // Parse postage (can be String or double)
    double? postage;
    final postageValue = orderLetter['postage'];
    if (postageValue != null) {
      if (postageValue is double) {
        postage = postageValue;
      } else if (postageValue is String) {
        postage = double.tryParse(postageValue);
      } else if (postageValue is int) {
        postage = postageValue.toDouble();
      }
    }

    return ApprovalEntity(
      id: id,
      noSp: noSp,
      orderDate: orderDate,
      requestDate: requestDate,
      creator: creator,
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      shipToName: shipToName,
      addressShipTo: addressShipTo,
      extendedAmount: extendedAmount,
      hargaAwal: hargaAwal,
      discount: discount,
      note: note,
      status: status,
      spgCode: spgCode,
      keterangan: keterangan,
      createdAt: createdAt,
      details: [], // Empty - not fetched
      discounts: [], // Empty - not fetched
      approvalHistory: [], // Empty - not fetched
      takeAway: takeAway,
      postage: postage,
    );
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
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      // Check cache first
      final cachedDiscounts =
          ApprovalCache.getCachedDiscounts(currentUserId, orderLetterId);
      if (cachedDiscounts != null) {
        return cachedDiscounts;
      }

      // Fetch from API
      final discounts = await _orderLetterService.getOrderLetterDiscounts(
        orderLetterId: orderLetterId,
      );

      // Cache the results
      ApprovalCache.cacheDiscounts(currentUserId, orderLetterId, discounts);

      return discounts;
    } catch (e) {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];
      return ApprovalCache.getCachedDiscounts(currentUserId, orderLetterId) ??
          [];
    }
  }

  /// Get cached user info
  Future<Map<String, dynamic>?> getCachedUserInfo() async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return null;
    return ApprovalCache.getCachedUserInfo(currentUserId);
  }

  /// Cache user info
  Future<void> cacheUserInfo(Map<String, dynamic> userInfo) async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return;
    ApprovalCache.cacheUserInfo(currentUserId, userInfo);
  }

  /// Get approvals with pagination support
  Future<List<ApprovalEntity>> getApprovalsWithPagination({
    String? creator,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      // First, ensure we have all data loaded
      await getApprovals(creator: creator, forceRefresh: forceRefresh);

      // Check if pagination should be used
      if (ApprovalCache.shouldUsePagination(currentUserId)) {
        final paginatedApprovals =
            ApprovalCache.getPaginatedApprovals(currentUserId, page);
        return paginatedApprovals;
      } else {
        // Return all data if pagination not needed
        return ApprovalCache.getCachedApprovals(currentUserId) ?? [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get pagination info
  Future<Map<String, dynamic>> getPaginationInfo() async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) {
      return {
        'should_use_pagination': false,
        'total_pages': 0,
        'items_per_page': ApprovalCache.itemsPerPage,
        'total_items': 0,
        'lazy_load_threshold': ApprovalCache.lazyLoadThreshold,
      };
    }
    return {
      'should_use_pagination': ApprovalCache.shouldUsePagination(currentUserId),
      'total_pages': ApprovalCache.getTotalPages(currentUserId),
      'items_per_page': ApprovalCache.itemsPerPage,
      'total_items':
          ApprovalCache.getCachedApprovals(currentUserId)?.length ?? 0,
      'lazy_load_threshold': ApprovalCache.lazyLoadThreshold,
    };
  }

  /// Background sync - refresh cache if needed
  Future<void> backgroundSync() async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return;

      if (!ApprovalCache.needsBackgroundSync(currentUserId)) {
        return;
      }

      // Get current cached approvals first - NEVER clear cache if it exists
      final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
      if (cachedApprovals == null || cachedApprovals.isEmpty) {
        // If cache is empty, do a full refresh
        try {
          final newApprovals = await getApprovals(forceRefresh: true);
          if (newApprovals.isNotEmpty) {
            ApprovalCache.cacheApprovals(currentUserId, newApprovals);
          }
        } catch (e) {
          // If error, keep existing cache (don't clear)
        }
        ApprovalCache.markBackgroundSyncCompleted(currentUserId);
        return;
      }

      // Refresh data in background without clearing cache immediately
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserName == null) {
        return;
      }

      // Use getApprovals which handles new format correctly
      List<ApprovalEntity> newApprovals = [];
      try {
        newApprovals = await getApprovals(forceRefresh: true);
      } catch (e) {
        // If error, don't update cache - keep existing cache
        ApprovalCache.markBackgroundSyncCompleted(currentUserId);
        return;
      }

      // Smart update: only update cache if we have data and data actually changed
      // NEVER update cache with empty list - always preserve existing cache
      if (newApprovals.isNotEmpty) {
        final currentCache = ApprovalCache.getCachedApprovals(currentUserId);
        if (currentCache == null ||
            _hasDataChanged(currentCache, newApprovals)) {
          ApprovalCache.cacheApprovals(currentUserId, newApprovals);
        }
      }
      // If newApprovals is empty, don't update cache (keep existing cache)

      ApprovalCache.markBackgroundSyncCompleted(currentUserId);
    } catch (e) {
      //
    }
  }

  /// Force use cache only (for testing cache effectiveness)
  Future<List<ApprovalEntity>> getApprovalsFromCacheOnly() async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return [];
    final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
    if (cachedApprovals != null) {
      return cachedApprovals;
    } else {
      return [];
    }
  }

  /// Test cache performance
  Future<void> testCachePerformance() async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return;
    final stopwatch = Stopwatch()..start();

    // Test cache access
    ApprovalCache.getCachedApprovals(currentUserId);
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
      final response = await _orderLetterService.getOrderLetters();

      // Find the order letter in response (handle new format)
      Map<String, dynamic>? orderLetter;
      Map<String, dynamic>? fullItem;

      for (final item in response) {
        if (item.containsKey('order_letter')) {
          final ol = item['order_letter'] as Map<String, dynamic>;
          if ((ol['id'] as int?) == orderLetterId) {
            orderLetter = ol;
            fullItem = item;
            break;
          }
        } else {
          if ((item['id'] as int?) == orderLetterId) {
            orderLetter = item;
            break;
          }
        }
      }

      if (orderLetter == null || orderLetter.isEmpty) return null;

      // If we have full item with details (new format), use it
      List<Map<String, dynamic>> details = [];
      List<Map<String, dynamic>> discounts = [];
      List<Map<String, dynamic>> approvalHistory = [];

      if (fullItem != null) {
        // Extract from new format
        final orderLetterDetails =
            fullItem['order_letter_details'] as List<dynamic>? ?? [];

        for (final detailData in orderLetterDetails) {
          if (detailData is Map<String, dynamic>) {
            final detail = Map<String, dynamic>.from(detailData);
            final orderLetterDiscounts =
                detail['order_letter_discount'] as List<dynamic>? ?? [];

            // Remove nested discount from detail
            final detailWithoutDiscount = Map<String, dynamic>.from(detail);
            detailWithoutDiscount.remove('order_letter_discount');
            details.add(detailWithoutDiscount);

            // Extract discounts from this detail
            for (final discountData in orderLetterDiscounts) {
              if (discountData is Map<String, dynamic>) {
                final discount = Map<String, dynamic>.from(discountData);
                discount['order_letter_detail_id'] =
                    detail['order_letter_detail_id'] ?? detail['id'];
                discounts.add(discount);

                // Extract approval history from discounts
                final orderLetterApproves =
                    discount['order_letter_approves'] as List<dynamic>? ?? [];
                for (final approveData in orderLetterApproves) {
                  if (approveData is Map<String, dynamic>) {
                    final approval = Map<String, dynamic>.from(approveData);
                    approval['order_letter_id'] = orderLetterId;
                    approval['order_letter_discount_id'] =
                        discount['order_letter_discount_id'] ?? discount['id'];
                    approvalHistory.add(approval);
                  }
                }
              }
            }
          }
        }
      } else {
        // Old format: fetch separately
        details = await _orderLetterService.getOrderLetterDetails(
            orderLetterId: orderLetterId);
        discounts = await _orderLetterService.getOrderLetterDiscounts(
            orderLetterId: orderLetterId);
        approvalHistory = await _orderLetterService.getOrderLetterApproves(
            orderLetterId: orderLetterId);
      }

      // Create updated approval model
      final updatedApproval = ApprovalModel.fromJson({
        ...orderLetter,
        'details': details,
        'discounts': discounts,
        'approval_history': approvalHistory,
      });

      // Update in cache
      final updated =
          ApprovalCache.updateApprovalInCache(currentUserId, updatedApproval);
      if (updated) {
        // Also clear discount cache for this order letter to force refresh
        ApprovalCache.clearDiscountCache(currentUserId, orderLetterId);
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
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId == null || currentUserName == null) {
        return [];
      }

      // Set loading state
      ApprovalCache.setLoadingNewData(currentUserId, true);

      List<ApprovalEntity> freshApprovals = [];
      try {
        freshApprovals = await getApprovals(forceRefresh: true);
      } catch (e) {
        // If error, return cached data instead of empty list
        final cachedApprovals =
            ApprovalCache.getCachedApprovals(currentUserId) ?? [];
        ApprovalCache.setLoadingNewData(currentUserId, false);
        return cachedApprovals;
      }

      // Find new approvals that are not in cache
      final cachedApprovals =
          ApprovalCache.getCachedApprovals(currentUserId) ?? [];
      final newApprovals = freshApprovals
          .where((fresh) =>
              !cachedApprovals.any((cached) => cached.id == fresh.id))
          .toList();

      // Store pending new approvals
      ApprovalCache.setPendingNewApprovals(currentUserId, newApprovals);

      // Merge and update cache
      ApprovalCache.mergePendingApprovals(currentUserId);

      return ApprovalCache.getCachedApprovals(currentUserId) ?? [];
    } catch (e) {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];
      ApprovalCache.setLoadingNewData(currentUserId, false);
      return ApprovalCache.getCachedApprovals(currentUserId) ?? [];
    }
  }

  /// Update only approval statuses (lightweight operation)
  Future<List<ApprovalEntity>> updateApprovalStatusesOnly() async {
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();
      if (currentUserId == null || currentUserName == null) {
        // Return cached data if available (but currentUserId might be null)
        if (currentUserId != null) {
          final cached = ApprovalCache.getCachedApprovals(currentUserId);
          return cached ?? [];
        }
        return [];
      }

      // Get current cached approvals
      final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
      if (cachedApprovals == null || cachedApprovals.isEmpty) {
        // If cache is empty, do a full refresh instead
        try {
          return await getApprovals(forceRefresh: true);
        } catch (e) {
          // If error, return empty list (don't return cached because it's already empty)
          return [];
        }
      }

      // Get order letters with new format (includes details, discounts, etc.)
      final response = await _orderLetterService.getOrderLetters();

      // Create a map of order letter ID to status (only for filtered order letters)
      final statusMap = <int, String>{};
      final orderLetterMap = <int, Map<String, dynamic>>{};

      // Process response with proper filtering using full item data
      for (final item in response) {
        Map<String, dynamic> orderLetter;
        Map<String, dynamic> fullItem;

        if (item.containsKey('order_letter')) {
          // New format: extract order_letter
          orderLetter = item['order_letter'] as Map<String, dynamic>;
          fullItem = item;
        } else {
          // Old format: direct order letter object
          orderLetter = item;
          fullItem = item;
        }

        // Check if this order letter should be included for current user
        final shouldInclude = await _shouldIncludeOrderLetter(
            orderLetter, fullItem, currentUserId, currentUserName);

        if (shouldInclude) {
          final id = orderLetter['id'] as int?;
          final status = orderLetter['status'] as String?;
          if (id != null && status != null) {
            statusMap[id] = status;
            orderLetterMap[id] = orderLetter;
          }
        }
      }

      // Find new order letters that are not in cache
      final cachedIds = cachedApprovals.map((a) => a.id).toSet();
      final newOrderLetterIds =
          statusMap.keys.where((id) => !cachedIds.contains(id)).toList();

      // Fetch full data for new order letters (only if there are new ones)
      List<ApprovalEntity> newApprovals = [];
      if (newOrderLetterIds.isNotEmpty) {
        // Get full response again to extract complete data for new order letters
        for (final item in response) {
          Map<String, dynamic>? orderLetter;
          Map<String, dynamic>? fullItem;

          if (item.containsKey('order_letter')) {
            orderLetter = item['order_letter'] as Map<String, dynamic>;
            fullItem = item;
          } else {
            orderLetter = item;
            fullItem = item;
          }

          final orderLetterId = orderLetter['id'] as int?;
          if (orderLetterId == null ||
              !newOrderLetterIds.contains(orderLetterId)) {
            continue;
          }

          // Check if should include (double check)
          final shouldInclude = await _shouldIncludeOrderLetter(
              orderLetter, fullItem, currentUserId, currentUserName);
          if (!shouldInclude) continue;

          try {
            // Extract data from new format if available
            if (fullItem.containsKey('order_letter_details')) {
              final orderLetterDetails =
                  fullItem['order_letter_details'] as List<dynamic>? ?? [];

              final List<Map<String, dynamic>> allDiscounts = [];
              final List<Map<String, dynamic>> allDetails = [];

              for (final detailData in orderLetterDetails) {
                if (detailData is Map<String, dynamic>) {
                  final detail = Map<String, dynamic>.from(detailData);
                  final orderLetterDiscounts =
                      detail['order_letter_discount'] as List<dynamic>? ?? [];

                  final detailWithoutDiscount =
                      Map<String, dynamic>.from(detail);
                  detailWithoutDiscount.remove('order_letter_discount');
                  allDetails.add(detailWithoutDiscount);

                  for (final discountData in orderLetterDiscounts) {
                    if (discountData is Map<String, dynamic>) {
                      final discount = Map<String, dynamic>.from(discountData);
                      discount['order_letter_detail_id'] =
                          detail['order_letter_detail_id'] ?? detail['id'];
                      allDiscounts.add(discount);
                    }
                  }
                }
              }

              final List<Map<String, dynamic>> allApprovalHistory = [];
              for (final discount in allDiscounts) {
                final orderLetterApproves =
                    discount['order_letter_approves'] as List<dynamic>? ?? [];
                for (final approveData in orderLetterApproves) {
                  if (approveData is Map<String, dynamic>) {
                    final approval = Map<String, dynamic>.from(approveData);
                    approval['order_letter_id'] = orderLetterId;
                    approval['order_letter_discount_id'] =
                        discount['order_letter_discount_id'] ?? discount['id'];
                    allApprovalHistory.add(approval);
                  }
                }
              }

              final newApproval = ApprovalModel.fromJson({
                ...orderLetter,
                'details': allDetails,
                'discounts': allDiscounts,
                'approval_history': allApprovalHistory,
              });

              newApprovals.add(newApproval);
            } else {
              // Old format: fetch separately
              final details = await _orderLetterService.getOrderLetterDetails(
                  orderLetterId: orderLetterId);
              final discounts = await _orderLetterService
                  .getOrderLetterDiscounts(orderLetterId: orderLetterId);
              final approvalHistory = await _orderLetterService
                  .getOrderLetterApproves(orderLetterId: orderLetterId);

              final newApproval = ApprovalModel.fromJson({
                ...orderLetter,
                'details': details,
                'discounts': discounts,
                'approval_history': approvalHistory,
              });

              newApprovals.add(newApproval);
            }
          } catch (e) {
            // Skip this order letter if there's an error
            continue;
          }
        }
      }

      // Update cached approvals with new statuses (preserve all existing approvals)
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
            takeAway: cachedApproval.takeAway,
            postage: cachedApproval.postage,
          );
        }
        return cachedApproval;
      }).toList();

      // Combine new approvals with updated approvals (new ones at the top)
      // IMPORTANT: Always include all cached approvals, even if they're not in statusMap
      // This ensures we don't lose data when filtering doesn't match
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

      // NEVER update cache with empty list - always preserve existing cache
      // Only update if we have data
      if (combinedApprovals.isNotEmpty) {
        ApprovalCache.cacheApprovals(currentUserId, combinedApprovals);
      }

      return combinedApprovals;
    } catch (e) {
      // If status update fails, return cached data (never return empty list if cache exists)
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId == null) return [];
      final cached = ApprovalCache.getCachedApprovals(currentUserId);
      return cached ?? [];
    }
  }

  /// Clear cache (useful for refresh)
  Future<void> clearCache() async {
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return;
    ApprovalCache.clearAllCache(currentUserId);
  }

  /// Check if order letter should be included for current user (creator or approver)
  /// Note: Team hierarchy filtering is now handled by the backend API endpoints
  /// based on user role (direct_leader, indirect_leader, analyst, controller, staff)
  Future<bool> _shouldIncludeOrderLetter(
    Map<String, dynamic> orderLetter,
    Map<String, dynamic> fullItem,
    int currentUserId,
    String currentUserName,
  ) async {
    final orderLetterId = orderLetter['id'] as int?;
    if (orderLetterId == null) return false;

    final creator = orderLetter['creator'];
    if (creator == null) return false;

    final creatorId = int.tryParse(creator.toString());
    if (creatorId == null) return false;

    // Check if creator is current user
    if (creatorId == currentUserId) {
      return true;
    }

    // Check if current user is assigned as approver for this order letter
    // Using fullItem to check nested structure: order_letter_details -> order_letter_discount
    // Note: Team hierarchy/subordinate filtering is now handled by backend API
    // (order_letters_by_direct_leader, order_letters_by_indirect_leader, etc.)
    if (await _isUserApproverForOrderLetterWithFullData(
        orderLetter, fullItem, currentUserId)) {
      return true;
    }

    return false;
  }

  /// Check if user is approver for order letter using full item data (nested structure)
  Future<bool> _isUserApproverForOrderLetterWithFullData(
    Map<String, dynamic> orderLetter,
    Map<String, dynamic> fullItem,
    int currentUserId,
  ) async {
    final currentUserName = await AuthService.getCurrentUserName();
    if (currentUserName == null) return false;

    // Normalize current user name for comparison (trim, lowercase, and remove extra spaces)
    final normalizedCurrentUserName =
        currentUserName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // Get leader data to match user_id by approver_level
    LeaderByUserModel? leaderData;
    try {
      final leaderService = locator<LeaderService>();
      leaderData = await leaderService.getLeaderByUser();
    } catch (e) {
      // Continue without leader data
    }

    // Check nested structure: order_letter_details -> order_letter_discount -> approver_name
    final orderLetterDetails =
        fullItem['order_letter_details'] as List<dynamic>? ?? [];

    // If order_letter_details is empty, try to check if fullItem itself contains discounts
    // (for old format or different API response structure)
    if (orderLetterDetails.isEmpty) {
      // Try to check discounts directly in fullItem (for old format)
      final discounts =
          fullItem['order_letter_discounts'] as List<dynamic>? ?? [];
      if (discounts.isNotEmpty) {
        for (final discountData in discounts) {
          if (discountData is Map<String, dynamic>) {
            if (await _checkIfUserIsApproverWithLeaderData(discountData,
                normalizedCurrentUserName, currentUserId, leaderData)) {
              return true;
            }
          }
        }
      }

      // If still not found and we have order letter ID, try fetching discounts separately
      final orderLetterId = orderLetter['id'] as int?;
      if (orderLetterId != null) {
        try {
          final discounts = await getDiscountsForTimeline(orderLetterId);
          for (final discountData in discounts) {
            if (await _checkIfUserIsApproverWithLeaderData(discountData,
                normalizedCurrentUserName, currentUserId, leaderData)) {
              return true;
            }
          }
        } catch (e) {
          // If fetching fails, continue with other checks
        }
      }
    } else {
      // New format: check nested structure
      for (final detailData in orderLetterDetails) {
        if (detailData is Map<String, dynamic>) {
          final orderLetterDiscounts =
              detailData['order_letter_discount'] as List<dynamic>? ?? [];

          for (final discountData in orderLetterDiscounts) {
            if (discountData is Map<String, dynamic>) {
              if (await _checkIfUserIsApproverWithLeaderData(discountData,
                  normalizedCurrentUserName, currentUserId, leaderData)) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }

  /// Check if user is approver with leader data to match user_id by approver_level
  Future<bool> _checkIfUserIsApproverWithLeaderData(
    Map<String, dynamic> discountData,
    String normalizedCurrentUserName,
    int currentUserId,
    LeaderByUserModel? leaderData,
  ) async {
    // First check: approver/leader ID if available (most reliable)
    final approverId = discountData['approver'] ?? discountData['leader'];
    if (approverId != null) {
      int? parsedId;
      if (approverId is int) {
        parsedId = approverId;
      } else if (approverId is String) {
        parsedId = int.tryParse(approverId);
      } else {
        parsedId = int.tryParse(approverId.toString());
      }

      if (parsedId != null && parsedId == currentUserId) {
        return true;
      }
    }

    // Second check: match user_id by approver_level using leader data
    if (leaderData != null) {
      final approverLevel = discountData['approver_level'] as String? ?? '';
      final approverLevelId = discountData['approver_level_id'] as int?;

      // Try to get leader ID by level
      int? expectedLeaderId;
      if (approverLevelId != null) {
        final leaderService = locator<LeaderService>();
        expectedLeaderId = leaderService.getLeaderIdByDiscountLevel(
            leaderData, approverLevelId);
      } else if (approverLevel.isNotEmpty) {
        // Map approver_level string to level ID
        int? levelId;
        switch (approverLevel.toLowerCase()) {
          case 'user':
            levelId = 1;
            break;
          case 'direct leader':
            levelId = 2;
            break;
          case 'indirect leader':
            levelId = 3;
            break;
          case 'analyst':
            levelId = 4;
            break;
          case 'controller':
            levelId = 5;
            break;
        }
        if (levelId != null) {
          final leaderService = locator<LeaderService>();
          expectedLeaderId =
              leaderService.getLeaderIdByDiscountLevel(leaderData, levelId);
        }
      }

      if (expectedLeaderId != null && expectedLeaderId == currentUserId) {
        return true;
      }
    }

    // Third check: approver_name matching (fallback)
    return _checkIfUserIsApprover(
        discountData, normalizedCurrentUserName, currentUserId);
  }

  /// Helper method to check if user is approver for a discount
  /// Checks both approver_name (with partial matching for name variations) and approver/leader ID
  bool _checkIfUserIsApprover(
    Map<String, dynamic> discountData,
    String normalizedCurrentUserName,
    int currentUserId,
  ) {
    final approverName = discountData['approver_name'] as String? ?? '';
    if (approverName.isNotEmpty) {
      // Normalize: trim, lowercase, and remove extra spaces
      final normalizedApproverName =
          approverName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      // Exact match
      if (normalizedApproverName == normalizedCurrentUserName) {
        return true;
      }

      // Partial match: check if approver_name contains user name or vice versa
      // This handles cases where user_name is "Arikmadi" but approver_name is "Arikmadi Tri Widodo"
      if (normalizedApproverName.contains(normalizedCurrentUserName) ||
          normalizedCurrentUserName.contains(normalizedApproverName)) {
        // Additional validation: ensure it's a meaningful match (not just single character)
        if (normalizedCurrentUserName.length >= 3) {
          return true;
        }
      }

      // Word-based matching: split by space and check if any word matches
      // This handles cases where names might be in different order
      final approverWords = normalizedApproverName
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      final userWords = normalizedCurrentUserName
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      // Check if any word from user name matches any word from approver name
      for (final userWord in userWords) {
        if (userWord.length >= 3 && approverWords.contains(userWord)) {
          return true;
        }
      }

      // Special case: check if first word of approver name matches user name (or first word of user name)
      // This handles "Arikmadi" matching "Arikmadi Tri Widodo"
      if (approverWords.isNotEmpty && userWords.isNotEmpty) {
        final approverFirstWord = approverWords.first;
        final userFirstWord = userWords.first;
        if (approverFirstWord == userFirstWord && userFirstWord.length >= 3) {
          return true;
        }
        // Also check if approver name starts with user first word
        if (normalizedApproverName.startsWith(userFirstWord) &&
            userFirstWord.length >= 3) {
          return true;
        }
      }
    }

    // Also check approver/leader ID if available (for backward compatibility)
    final approverId = discountData['approver'] ?? discountData['leader'];
    if (approverId != null) {
      // Handle different types: int, String, or null
      int? parsedId;
      if (approverId is int) {
        parsedId = approverId;
      } else if (approverId is String) {
        parsedId = int.tryParse(approverId);
      } else {
        parsedId = int.tryParse(approverId.toString());
      }

      if (parsedId != null && parsedId == currentUserId) {
        return true;
      }
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
      // Get current location for approval
      String? approvalLocation;
      try {
        final locationInfo = await LocationService.getLocationInfo();
        if (locationInfo != null) {
          final address = locationInfo['address'] as String?;
          if (address != null && address.isNotEmpty) {
            approvalLocation = address;
          } else {
            final lat = locationInfo['latitude'] as double?;
            final lon = locationInfo['longitude'] as double?;
            if (lat != null && lon != null) {
              approvalLocation = '$lat,$lon';
            }
          }
        }
      } catch (e) {
        // If location cannot be obtained, continue without it
      }

      final approvalData = {
        'order_letter_id': orderLetterId,
        'approver_name': approverName,
        'approver_email': approverEmail,
        'action': action,
        'comment': comment,
        if (approvalLocation != null) 'location': approvalLocation,
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
