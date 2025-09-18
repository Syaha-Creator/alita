import '../../domain/entities/approval_entity.dart';

/// Cache manager untuk approval data
class ApprovalCache {
  // Cache untuk approval data
  static List<ApprovalEntity>? _cachedApprovals;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Cache untuk discounts data (untuk timeline)
  static final Map<int, List<Map<String, dynamic>>> _discountCache = {};
  static final Map<int, DateTime> _discountCacheTimestamp = {};
  static const Duration _discountCacheValidDuration = Duration(minutes: 10);

  // Cache untuk user info
  static Map<String, dynamic>? _userInfoCache;
  static DateTime? _userInfoCacheTimestamp;
  static const Duration _userInfoCacheValidDuration = Duration(hours: 1);

  // Pagination settings
  static const int itemsPerPage = 20;
  static const int lazyLoadThreshold = 50;

  // Background sync settings
  static DateTime? _lastBackgroundSync;
  static const Duration _backgroundSyncInterval = Duration(minutes: 3);

  // Incremental loading state
  static bool _isLoadingNewData = false;
  static List<ApprovalEntity>? _pendingNewApprovals;

  /// Check if approval cache is still valid
  static bool isApprovalCacheValid() {
    if (_cachedApprovals == null || _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    final isValid =
        now.difference(_cacheTimestamp!).compareTo(_cacheValidDuration) < 0;

    return isValid;
  }

  /// Get cached approvals
  static List<ApprovalEntity>? getCachedApprovals() {
    if (isApprovalCacheValid()) {
      return _cachedApprovals;
    }
    return null;
  }

  /// Cache approvals data
  static void cacheApprovals(List<ApprovalEntity> approvals) {
    _cachedApprovals = approvals;
    _cacheTimestamp = DateTime.now();
  }

  /// Check if discount cache is valid for specific order letter
  static bool isDiscountCacheValid(int orderLetterId) {
    if (!_discountCache.containsKey(orderLetterId) ||
        !_discountCacheTimestamp.containsKey(orderLetterId)) {
      return false;
    }

    final now = DateTime.now();
    final timestamp = _discountCacheTimestamp[orderLetterId]!;
    return now.difference(timestamp).compareTo(_discountCacheValidDuration) < 0;
  }

  /// Get cached discounts for specific order letter
  static List<Map<String, dynamic>>? getCachedDiscounts(int orderLetterId) {
    if (isDiscountCacheValid(orderLetterId)) {
      return _discountCache[orderLetterId];
    }
    return null;
  }

  /// Cache discounts for specific order letter
  static void cacheDiscounts(
      int orderLetterId, List<Map<String, dynamic>> discounts) {
    _discountCache[orderLetterId] = discounts;
    _discountCacheTimestamp[orderLetterId] = DateTime.now();
  }

  /// Check if user info cache is valid
  static bool isUserInfoCacheValid() {
    if (_userInfoCache == null || _userInfoCacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    return now
            .difference(_userInfoCacheTimestamp!)
            .compareTo(_userInfoCacheValidDuration) <
        0;
  }

  /// Get cached user info
  static Map<String, dynamic>? getCachedUserInfo() {
    if (isUserInfoCacheValid()) {
      return _userInfoCache;
    }
    return null;
  }

  /// Cache user info
  static void cacheUserInfo(Map<String, dynamic> userInfo) {
    _userInfoCache = userInfo;
    _userInfoCacheTimestamp = DateTime.now();
  }

  /// Clear all cache (useful for refresh or logout)
  static void clearAllCache() {
    _cachedApprovals = null;
    _cacheTimestamp = null;
    _discountCache.clear();
    _discountCacheTimestamp.clear();
    _userInfoCache = null;
    _userInfoCacheTimestamp = null;
  }

  /// Clear only approval cache (for refresh)
  static void clearApprovalCache() {
    _cachedApprovals = null;
    _cacheTimestamp = null;
  }

  /// Clear discount cache for specific order letter
  static void clearDiscountCache(int orderLetterId) {
    _discountCache.remove(orderLetterId);
    _discountCacheTimestamp.remove(orderLetterId);
  }

  /// Update specific approval in cache
  static bool updateApprovalInCache(ApprovalEntity updatedApproval) {
    if (_cachedApprovals == null) return false;

    final index = _cachedApprovals!
        .indexWhere((approval) => approval.id == updatedApproval.id);
    if (index != -1) {
      _cachedApprovals![index] = updatedApproval;
      return true;
    }
    return false;
  }

  /// Add new approval to cache
  static void addApprovalToCache(ApprovalEntity newApproval) {
    if (_cachedApprovals == null) {
      _cachedApprovals = [newApproval];
    } else {
      _cachedApprovals!
          .insert(0, newApproval); // Add to beginning (newest first)
    }
    _cacheTimestamp = DateTime.now();
  }

  /// Remove approval from cache
  static bool removeApprovalFromCache(int approvalId) {
    if (_cachedApprovals == null) return false;

    final initialLength = _cachedApprovals!.length;
    _cachedApprovals!.removeWhere((approval) => approval.id == approvalId);
    return _cachedApprovals!.length < initialLength;
  }

  /// Check if background sync is needed
  static bool needsBackgroundSync() {
    if (_lastBackgroundSync == null) return true;

    final now = DateTime.now();
    return now
            .difference(_lastBackgroundSync!)
            .compareTo(_backgroundSyncInterval) >=
        0;
  }

  /// Mark background sync as completed
  static void markBackgroundSyncCompleted() {
    _lastBackgroundSync = DateTime.now();
  }

  /// Check if pagination should be used based on data size
  static bool shouldUsePagination() {
    return (_cachedApprovals?.length ?? 0) > lazyLoadThreshold;
  }

  /// Get paginated approvals
  static List<ApprovalEntity> getPaginatedApprovals(int page) {
    if (_cachedApprovals == null) return [];

    final startIndex = (page - 1) * itemsPerPage;
    final endIndex =
        (startIndex + itemsPerPage).clamp(0, _cachedApprovals!.length);

    if (startIndex >= _cachedApprovals!.length) return [];

    return _cachedApprovals!.sublist(startIndex, endIndex);
  }

  /// Get total pages
  static int getTotalPages() {
    if (_cachedApprovals == null) return 0;
    return ((_cachedApprovals!.length - 1) / itemsPerPage).floor() + 1;
  }

  /// Set loading state for new data
  static void setLoadingNewData(bool loading) {
    _isLoadingNewData = loading;
  }

  /// Check if loading new data
  static bool isLoadingNewData() {
    return _isLoadingNewData;
  }

  /// Set pending new approvals (for incremental loading)
  static void setPendingNewApprovals(List<ApprovalEntity>? approvals) {
    _pendingNewApprovals = approvals;
  }

  /// Get pending new approvals
  static List<ApprovalEntity>? getPendingNewApprovals() {
    return _pendingNewApprovals;
  }

  /// Merge pending new approvals with cache
  static void mergePendingApprovals() {
    if (_pendingNewApprovals != null && _pendingNewApprovals!.isNotEmpty) {
      if (_cachedApprovals == null) {
        _cachedApprovals = List.from(_pendingNewApprovals!);
      } else {
        // Add new approvals to the beginning (newest first)
        final newItems = _pendingNewApprovals!
            .where((newApproval) =>
                !_cachedApprovals!.any((cached) => cached.id == newApproval.id))
            .toList();

        _cachedApprovals!.insertAll(0, newItems);
      }

      _pendingNewApprovals = null;
      _cacheTimestamp = DateTime.now();
    }
    _isLoadingNewData = false;
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'approval_cache_valid': isApprovalCacheValid(),
      'approval_cache_size': _cachedApprovals?.length ?? 0,
      'approval_cache_timestamp': _cacheTimestamp?.toIso8601String(),
      'discount_cache_size': _discountCache.length,
      'user_info_cache_valid': isUserInfoCacheValid(),
      'user_info_cache_timestamp': _userInfoCacheTimestamp?.toIso8601String(),
      'should_use_pagination': shouldUsePagination(),
      'total_pages': getTotalPages(),
      'needs_background_sync': needsBackgroundSync(),
      'last_background_sync': _lastBackgroundSync?.toIso8601String(),
      'is_loading_new_data': _isLoadingNewData,
      'pending_new_approvals': _pendingNewApprovals?.length ?? 0,
    };
  }
}
