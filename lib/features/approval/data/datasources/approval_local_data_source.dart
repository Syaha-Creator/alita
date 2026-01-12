import '../../domain/entities/approval_entity.dart';
import '../cache/approval_cache.dart';

/// Local data source untuk approval cache operations
/// Menggunakan ApprovalCache untuk backward compatibility
abstract class ApprovalLocalDataSource {
  List<ApprovalEntity>? getCachedApprovals(int userId);
  void cacheApprovals(int userId, List<ApprovalEntity> approvals);
  bool isApprovalCacheValid(int userId);
  void clearAllCache(int userId);
  void clearDiscountCache(int userId, int orderLetterId);
  List<Map<String, dynamic>>? getCachedDiscounts(int userId, int orderLetterId);
  void cacheDiscounts(
    int userId,
    int orderLetterId,
    List<Map<String, dynamic>> discounts,
  );
  Map<String, dynamic>? getCachedUserInfo(int userId);
  void cacheUserInfo(int userId, Map<String, dynamic> userInfo);
  bool updateApprovalInCache(int userId, ApprovalEntity approval);
  bool shouldUsePagination(int userId);
  List<ApprovalEntity> getPaginatedApprovals(int userId, int page);
  int getTotalPages(int userId);
  bool needsBackgroundSync(int userId);
  void markBackgroundSyncCompleted(int userId);
  void setLoadingNewData(int userId, bool isLoading);
  void setPendingNewApprovals(int userId, List<ApprovalEntity> approvals);
  void mergePendingApprovals(int userId);
  static const int itemsPerPage = ApprovalCache.itemsPerPage;
  static const int lazyLoadThreshold = ApprovalCache.lazyLoadThreshold;
}

class ApprovalLocalDataSourceImpl implements ApprovalLocalDataSource {
  ApprovalLocalDataSourceImpl();

  @override
  List<ApprovalEntity>? getCachedApprovals(int userId) {
    return ApprovalCache.getCachedApprovals(userId);
  }

  @override
  void cacheApprovals(int userId, List<ApprovalEntity> approvals) {
    ApprovalCache.cacheApprovals(userId, approvals);
  }

  @override
  bool isApprovalCacheValid(int userId) {
    return ApprovalCache.isApprovalCacheValid(userId);
  }

  @override
  void clearAllCache(int userId) {
    ApprovalCache.clearAllCache(userId);
  }

  @override
  void clearDiscountCache(int userId, int orderLetterId) {
    ApprovalCache.clearDiscountCache(userId, orderLetterId);
  }

  @override
  List<Map<String, dynamic>>? getCachedDiscounts(
    int userId,
    int orderLetterId,
  ) {
    return ApprovalCache.getCachedDiscounts(userId, orderLetterId);
  }

  @override
  void cacheDiscounts(
    int userId,
    int orderLetterId,
    List<Map<String, dynamic>> discounts,
  ) {
    ApprovalCache.cacheDiscounts(userId, orderLetterId, discounts);
  }

  @override
  Map<String, dynamic>? getCachedUserInfo(int userId) {
    return ApprovalCache.getCachedUserInfo(userId);
  }

  @override
  void cacheUserInfo(int userId, Map<String, dynamic> userInfo) {
    ApprovalCache.cacheUserInfo(userId, userInfo);
  }

  @override
  bool updateApprovalInCache(int userId, ApprovalEntity approval) {
    return ApprovalCache.updateApprovalInCache(userId, approval);
  }

  @override
  bool shouldUsePagination(int userId) {
    return ApprovalCache.shouldUsePagination(userId);
  }

  @override
  List<ApprovalEntity> getPaginatedApprovals(int userId, int page) {
    return ApprovalCache.getPaginatedApprovals(userId, page);
  }

  @override
  int getTotalPages(int userId) {
    return ApprovalCache.getTotalPages(userId);
  }

  @override
  bool needsBackgroundSync(int userId) {
    return ApprovalCache.needsBackgroundSync(userId);
  }

  @override
  void markBackgroundSyncCompleted(int userId) {
    ApprovalCache.markBackgroundSyncCompleted(userId);
  }

  @override
  void setLoadingNewData(int userId, bool isLoading) {
    ApprovalCache.setLoadingNewData(userId, isLoading);
  }

  @override
  void setPendingNewApprovals(int userId, List<ApprovalEntity> approvals) {
    ApprovalCache.setPendingNewApprovals(userId, approvals);
  }

  @override
  void mergePendingApprovals(int userId) {
    ApprovalCache.mergePendingApprovals(userId);
  }

  // Note: These are static constants, not instance methods
  // They should be accessed via ApprovalLocalDataSource.itemsPerPage
  static const int itemsPerPage = ApprovalCache.itemsPerPage;
  static const int lazyLoadThreshold = ApprovalCache.lazyLoadThreshold;
}

