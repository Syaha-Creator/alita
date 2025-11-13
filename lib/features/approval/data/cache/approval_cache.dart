import '../../domain/entities/approval_entity.dart';

/// Cache manager untuk approval data
class ApprovalCache {
  // Cache untuk approval data per user (key: userId)
  static final Map<int, List<ApprovalEntity>> _cachedApprovalsByUser = {};
  static final Map<int, DateTime> _cacheTimestampByUser = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Cache untuk discounts data (untuk timeline) - per user dan order letter
  static final Map<String, List<Map<String, dynamic>>> _discountCache = {};
  static final Map<String, DateTime> _discountCacheTimestamp = {};
  static const Duration _discountCacheValidDuration = Duration(minutes: 10);

  // Cache untuk user info per user
  static final Map<int, Map<String, dynamic>> _userInfoCacheByUser = {};
  static final Map<int, DateTime> _userInfoCacheTimestampByUser = {};
  static const Duration _userInfoCacheValidDuration = Duration(hours: 1);

  // Pagination settings
  static const int itemsPerPage = 20;
  static const int lazyLoadThreshold = 50;

  // Background sync settings per user
  static final Map<int, DateTime> _lastBackgroundSyncByUser = {};
  static const Duration _backgroundSyncInterval = Duration(minutes: 3);

  // Incremental loading state per user
  static final Map<int, bool> _isLoadingNewDataByUser = {};
  static final Map<int, List<ApprovalEntity>> _pendingNewApprovalsByUser = {};

  /// Check if approval cache is still valid for a specific user
  static bool isApprovalCacheValid(int userId) {
    if (!_cachedApprovalsByUser.containsKey(userId) ||
        !_cacheTimestampByUser.containsKey(userId)) {
      return false;
    }

    final now = DateTime.now();
    final isValid = now
            .difference(_cacheTimestampByUser[userId]!)
            .compareTo(_cacheValidDuration) <
        0;

    return isValid;
  }

  /// Get cached approvals for a specific user
  static List<ApprovalEntity>? getCachedApprovals(int userId) {
    if (isApprovalCacheValid(userId)) {
      return _cachedApprovalsByUser[userId];
    }
    return null;
  }

  /// Cache approvals data for a specific user
  static void cacheApprovals(int userId, List<ApprovalEntity> approvals) {
    _cachedApprovalsByUser[userId] = approvals;
    _cacheTimestampByUser[userId] = DateTime.now();
  }

  /// Check if discount cache is valid for specific order letter and user
  static bool isDiscountCacheValid(int userId, int orderLetterId) {
    final cacheKey = '${userId}_$orderLetterId';
    if (!_discountCache.containsKey(cacheKey) ||
        !_discountCacheTimestamp.containsKey(cacheKey)) {
      return false;
    }

    final now = DateTime.now();
    final timestamp = _discountCacheTimestamp[cacheKey]!;
    return now.difference(timestamp).compareTo(_discountCacheValidDuration) < 0;
  }

  /// Get cached discounts for specific order letter and user
  static List<Map<String, dynamic>>? getCachedDiscounts(
      int userId, int orderLetterId) {
    final cacheKey = '${userId}_$orderLetterId';
    if (isDiscountCacheValid(userId, orderLetterId)) {
      return _discountCache[cacheKey];
    }
    return null;
  }

  /// Cache discounts for specific order letter and user
  static void cacheDiscounts(
      int userId, int orderLetterId, List<Map<String, dynamic>> discounts) {
    final cacheKey = '${userId}_$orderLetterId';
    _discountCache[cacheKey] = discounts;
    _discountCacheTimestamp[cacheKey] = DateTime.now();
  }

  /// Check if user info cache is valid for a specific user
  static bool isUserInfoCacheValid(int userId) {
    if (!_userInfoCacheByUser.containsKey(userId) ||
        !_userInfoCacheTimestampByUser.containsKey(userId)) {
      return false;
    }

    final now = DateTime.now();
    return now
            .difference(_userInfoCacheTimestampByUser[userId]!)
            .compareTo(_userInfoCacheValidDuration) <
        0;
  }

  /// Get cached user info for a specific user
  static Map<String, dynamic>? getCachedUserInfo(int userId) {
    if (isUserInfoCacheValid(userId)) {
      return _userInfoCacheByUser[userId];
    }
    return null;
  }

  /// Cache user info for a specific user
  static void cacheUserInfo(int userId, Map<String, dynamic> userInfo) {
    _userInfoCacheByUser[userId] = userInfo;
    _userInfoCacheTimestampByUser[userId] = DateTime.now();
  }

  /// Clear all cache for a specific user (useful for refresh or logout)
  static void clearAllCache(int userId) {
    _cachedApprovalsByUser.remove(userId);
    _cacheTimestampByUser.remove(userId);
    _userInfoCacheByUser.remove(userId);
    _userInfoCacheTimestampByUser.remove(userId);
    _lastBackgroundSyncByUser.remove(userId);
    _isLoadingNewDataByUser.remove(userId);
    _pendingNewApprovalsByUser.remove(userId);

    // Clear discount cache for this user
    final keysToRemove = _discountCache.keys
        .where((key) => key.startsWith('${userId}_'))
        .toList();
    for (final key in keysToRemove) {
      _discountCache.remove(key);
      _discountCacheTimestamp.remove(key);
    }
  }

  /// Clear all cache for all users (useful for complete reset)
  static void clearAllCacheForAllUsers() {
    _cachedApprovalsByUser.clear();
    _cacheTimestampByUser.clear();
    _discountCache.clear();
    _discountCacheTimestamp.clear();
    _userInfoCacheByUser.clear();
    _userInfoCacheTimestampByUser.clear();
    _lastBackgroundSyncByUser.clear();
    _isLoadingNewDataByUser.clear();
    _pendingNewApprovalsByUser.clear();
  }

  /// Clear only approval cache for a specific user (for refresh)
  static void clearApprovalCache(int userId) {
    _cachedApprovalsByUser.remove(userId);
    _cacheTimestampByUser.remove(userId);
  }

  /// Clear discount cache for specific order letter and user
  static void clearDiscountCache(int userId, int orderLetterId) {
    final cacheKey = '${userId}_$orderLetterId';
    _discountCache.remove(cacheKey);
    _discountCacheTimestamp.remove(cacheKey);
  }

  /// Update specific approval in cache for a specific user
  static bool updateApprovalInCache(
      int userId, ApprovalEntity updatedApproval) {
    if (!_cachedApprovalsByUser.containsKey(userId)) return false;

    final approvals = _cachedApprovalsByUser[userId]!;
    final index =
        approvals.indexWhere((approval) => approval.id == updatedApproval.id);
    if (index != -1) {
      approvals[index] = updatedApproval;
      _cacheTimestampByUser[userId] = DateTime.now();
      return true;
    }
    return false;
  }

  /// Add new approval to cache for a specific user
  static void addApprovalToCache(int userId, ApprovalEntity newApproval) {
    if (!_cachedApprovalsByUser.containsKey(userId)) {
      _cachedApprovalsByUser[userId] = [newApproval];
    } else {
      _cachedApprovalsByUser[userId]!
          .insert(0, newApproval); // Add to beginning (newest first)
    }
    _cacheTimestampByUser[userId] = DateTime.now();
  }

  /// Remove approval from cache for a specific user
  static bool removeApprovalFromCache(int userId, int approvalId) {
    if (!_cachedApprovalsByUser.containsKey(userId)) return false;

    final approvals = _cachedApprovalsByUser[userId]!;
    final initialLength = approvals.length;
    approvals.removeWhere((approval) => approval.id == approvalId);
    return approvals.length < initialLength;
  }

  /// Check if background sync is needed for a specific user
  static bool needsBackgroundSync(int userId) {
    if (!_lastBackgroundSyncByUser.containsKey(userId)) return true;

    final now = DateTime.now();
    return now
            .difference(_lastBackgroundSyncByUser[userId]!)
            .compareTo(_backgroundSyncInterval) >=
        0;
  }

  /// Mark background sync as completed for a specific user
  static void markBackgroundSyncCompleted(int userId) {
    _lastBackgroundSyncByUser[userId] = DateTime.now();
  }

  /// Check if pagination should be used based on data size for a specific user
  static bool shouldUsePagination(int userId) {
    final approvals = _cachedApprovalsByUser[userId];
    return (approvals?.length ?? 0) > lazyLoadThreshold;
  }

  /// Get paginated approvals for a specific user
  static List<ApprovalEntity> getPaginatedApprovals(int userId, int page) {
    final approvals = _cachedApprovalsByUser[userId];
    if (approvals == null) return [];

    final startIndex = (page - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, approvals.length);

    if (startIndex >= approvals.length) return [];

    return approvals.sublist(startIndex, endIndex);
  }

  /// Get total pages for a specific user
  static int getTotalPages(int userId) {
    final approvals = _cachedApprovalsByUser[userId];
    if (approvals == null) return 0;
    return ((approvals.length - 1) / itemsPerPage).floor() + 1;
  }

  /// Set loading state for new data for a specific user
  static void setLoadingNewData(int userId, bool loading) {
    _isLoadingNewDataByUser[userId] = loading;
  }

  /// Check if loading new data for a specific user
  static bool isLoadingNewData(int userId) {
    return _isLoadingNewDataByUser[userId] ?? false;
  }

  /// Set pending new approvals (for incremental loading) for a specific user
  static void setPendingNewApprovals(
      int userId, List<ApprovalEntity>? approvals) {
    if (approvals == null) {
      _pendingNewApprovalsByUser.remove(userId);
    } else {
      _pendingNewApprovalsByUser[userId] = approvals;
    }
  }

  /// Get pending new approvals for a specific user
  static List<ApprovalEntity>? getPendingNewApprovals(int userId) {
    return _pendingNewApprovalsByUser[userId];
  }

  /// Merge pending new approvals with cache for a specific user
  static void mergePendingApprovals(int userId) {
    final pendingApprovals = _pendingNewApprovalsByUser[userId];
    if (pendingApprovals != null && pendingApprovals.isNotEmpty) {
      if (!_cachedApprovalsByUser.containsKey(userId)) {
        _cachedApprovalsByUser[userId] = List.from(pendingApprovals);
      } else {
        // Add new approvals to the beginning (newest first)
        final newItems = pendingApprovals
            .where((newApproval) => !_cachedApprovalsByUser[userId]!
                .any((cached) => cached.id == newApproval.id))
            .toList();

        _cachedApprovalsByUser[userId]!.insertAll(0, newItems);
      }

      _pendingNewApprovalsByUser.remove(userId);
      _cacheTimestampByUser[userId] = DateTime.now();
    }
    _isLoadingNewDataByUser[userId] = false;
  }

  /// Get cache statistics for debugging for a specific user
  static Map<String, dynamic> getCacheStats(int userId) {
    final approvals = _cachedApprovalsByUser[userId];
    return {
      'approval_cache_valid': isApprovalCacheValid(userId),
      'approval_cache_size': approvals?.length ?? 0,
      'approval_cache_timestamp':
          _cacheTimestampByUser[userId]?.toIso8601String(),
      'discount_cache_size': _discountCache.keys
          .where((key) => key.startsWith('${userId}_'))
          .length,
      'user_info_cache_valid': isUserInfoCacheValid(userId),
      'user_info_cache_timestamp':
          _userInfoCacheTimestampByUser[userId]?.toIso8601String(),
      'should_use_pagination': shouldUsePagination(userId),
      'total_pages': getTotalPages(userId),
      'needs_background_sync': needsBackgroundSync(userId),
      'last_background_sync':
          _lastBackgroundSyncByUser[userId]?.toIso8601String(),
      'is_loading_new_data': isLoadingNewData(userId),
      'pending_new_approvals': _pendingNewApprovalsByUser[userId]?.length ?? 0,
    };
  }
}
