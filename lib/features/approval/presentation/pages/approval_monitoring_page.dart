import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../services/core_notification_service.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/entities/approval_entity.dart';
import '../../data/repositories/approval_repository.dart';
import '../../data/cache/approval_cache.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import '../widgets/approval_card.dart';
import '../widgets/approval_modal.dart';
import '../widgets/approval_skeleton_card.dart';

class ApprovalMonitoringPage extends StatefulWidget {
  const ApprovalMonitoringPage({super.key});

  @override
  State<ApprovalMonitoringPage> createState() => _ApprovalMonitoringPageState();
}

class _ApprovalMonitoringPageState extends State<ApprovalMonitoringPage>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // --- Add state to hold stats ---
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;

  // --- Add state for user permissions ---
  bool _isStaffLevel = false;
  bool _isLoadingUserInfo = true;

  // Add keys for approval cards to refresh timeline
  final Map<int, GlobalKey> _approvalCardKeys = {};

  // Pagination state
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _usePagination = false;

  // Background sync
  Timer? _backgroundSyncTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserInfo();
    _loadApprovals();
    _startBackgroundSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if we need to load new data when returning from other pages
    _checkForNewData();
  }

  /// Check for new data when returning to page
  void _checkForNewData() {
    // If cache is older than 30 seconds, load new data incrementally
    final cacheStats = ApprovalCache.getCacheStats();
    final cacheTimestamp = cacheStats['approval_cache_timestamp'] as String?;

    if (cacheTimestamp != null) {
      final cacheTime = DateTime.tryParse(cacheTimestamp);
      if (cacheTime != null) {
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference.inSeconds > 30) {
          // Load new data incrementally
          context.read<ApprovalBloc>().add(const LoadNewApprovalsIncremental());
        }
      }
    }
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Check cache first
      final cachedUserInfo = locator<ApprovalRepository>().getCachedUserInfo();
      if (cachedUserInfo != null) {
        setState(() {
          _isStaffLevel = cachedUserInfo['isStaffLevel'] ?? false;
          _isLoadingUserInfo = false;
        });
        return;
      }

      // Get current user info from AuthService (no need for leader data)
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();

      if (currentUserId != null && currentUserName != null) {
        final userInfo = {
          'userId': currentUserId,
          'userName': currentUserName,
          'isStaffLevel': false, // All users can approve for now
        };

        // Cache user info
        locator<ApprovalRepository>().cacheUserInfo(userInfo);

        setState(() {
          _isStaffLevel = false;
          _isLoadingUserInfo = false;
        });
      } else {
        setState(() {
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingUserInfo = false;
      });
    }
  }

  void _loadApprovals({bool forceRefresh = false}) {
    final stopwatch = Stopwatch()..start();

    if (forceRefresh) {
      // Clear cache untuk force refresh
      locator<ApprovalRepository>().clearCache();
    } else {
      // Test cache performance
      locator<ApprovalRepository>().testCachePerformance();
    }

    context.read<ApprovalBloc>().add(LoadApprovals());

    stopwatch.stop();
  }

  Future<void> _onRefresh() async {
    // Reset pagination state
    _currentPage = 1;
    _hasMoreData = true;
    _isLoadingMore = false;

    _loadApprovals(forceRefresh: true);
    // Wait for the bloc to complete
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Start background sync timer
  void _startBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _performBackgroundSync();
    });

    // Also perform initial background sync after 30 seconds
    Timer(const Duration(seconds: 30), () {
      _performBackgroundSync();
    });
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      await locator<ApprovalRepository>().backgroundSync();

      // Trigger UI update if needed
      if (mounted) {
        context.read<ApprovalBloc>().add(LoadApprovals());
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Load more data for pagination
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || !_usePagination) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final repository = locator<ApprovalRepository>();
      final moreApprovals =
          await repository.getApprovalsWithPagination(page: nextPage);

      if (moreApprovals.isNotEmpty) {
        _currentPage = nextPage;
        // Trigger bloc to load more data
        context.read<ApprovalBloc>().add(LoadApprovals());
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      // Silent error handling for pagination
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _showApprovalModal(ApprovalEntity approval) async {
    // Check if current user is the creator of this order letter
    final currentUserName = await AuthService.getCurrentUserName() ?? '';
    final currentUserId = await AuthService.getCurrentUserId();
    final isCurrentUserCreator = _isNameMatch(
      approval.creator,
      currentUserName,
    );

    if (isCurrentUserCreator) {
      // Show approval timeline instead of modal
      _showApprovalTimeline(approval);
      return;
    }

    // Check if current user has already approved any discount in this order letter
    if (currentUserId != null) {
      try {
        final orderLetterService = locator<OrderLetterService>();
        final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
          orderLetterId: approval.id,
        );

        bool hasUserApproved = false;
        for (final discount in rawDiscounts) {
          final approverId = discount['approver'];
          final approverName = discount['approver_name'];
          final approved = discount['approved'];

          // Check if current user has approved this discount
          if ((approverId == currentUserId ||
                  _isNameMatch(approverName, currentUserName)) &&
              approved == true) {
            hasUserApproved = true;
            break;
          }
        }

        if (hasUserApproved) {
          // User has already approved, show timeline instead of modal
          _showApprovalTimeline(approval);
          return;
        }
      } catch (e) {
        // Continue to show approval modal if there's an error
      }
    }

    // Get pending discount count before showing modal
    int pendingCount = 0;
    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId != null) {
        final orderLetterService = locator<OrderLetterService>();
        final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
            orderLetterId: approval.id);

        // Get user's job level
        int jobLevelId = 1;
        for (final discount in rawDiscounts) {
          final approverId = discount['approver'];
          final approverName = discount['approver_name'];
          final approverLevelId = discount['approver_level_id'];

          if ((approverId == currentUserId ||
                  _isNameMatch(approverName,
                      await AuthService.getCurrentUserName() ?? '')) &&
              approverLevelId != null) {
            jobLevelId = approverLevelId;
            break;
          }
        }

        pendingCount = await orderLetterService.getPendingDiscountCount(
          orderLetterId: approval.id,
          leaderId: currentUserId,
          jobLevelId: jobLevelId,
        );
      }
    } catch (e) {
      // Continue with pendingCount = 0 if error
    }

    // Show approval modal for approvers who haven't approved yet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApprovalModal(
        approval: approval,
        pendingDiscountCount: pendingCount,
        onApprovalAction: (action, comment) async {
          try {
            // Get the discount that needs approval for current user
            final currentUserId = await AuthService.getCurrentUserId();
            final currentUserName =
                await AuthService.getCurrentUserName() ?? '';

            if (currentUserId == null) {
              _showErrorSnackBar('User information not available');
              return;
            }

            // Get raw discount data from repository to find pending approval
            final orderLetterService = locator<OrderLetterService>();
            final rawDiscounts = await orderLetterService
                .getOrderLetterDiscounts(orderLetterId: approval.id);

            // Check if current user can approve sequentially
            bool canApprove = _canUserApproveSequentially(
              rawDiscounts,
              currentUserId,
              currentUserName,
            );

            if (!canApprove) {
              _showErrorSnackBar(
                'Cannot approve: Previous levels must be approved first',
              );
              return;
            }

            // Get user's job level from discount data
            int jobLevelId = 1; // Default to user level

            // Find the discount for current user to get their job level
            for (final discount in rawDiscounts) {
              final approverId = discount['approver'];
              final approverName = discount['approver_name'];
              final approverLevelId = discount['approver_level_id'];

              if ((approverId == currentUserId ||
                      _isNameMatch(approverName, currentUserName)) &&
                  approverLevelId != null) {
                jobLevelId = approverLevelId;
                break;
              }
            }

            // Get count of pending discounts for better user feedback
            final pendingCount =
                await orderLetterService.getPendingDiscountCount(
              orderLetterId: approval.id,
              leaderId: currentUserId,
              jobLevelId: jobLevelId,
            );

            if (pendingCount == 0) {
              _showErrorSnackBar('No pending discounts found for approval');
              return;
            }

            // Use batch approval for all pending discounts at user's level
            final result =
                await orderLetterService.batchApproveOrderLetterDiscounts(
              orderLetterId: approval.id,
              leaderId: currentUserId,
              jobLevelId: jobLevelId,
            );

            // Show success message with count of approved discounts
            final approvedCount = result['approved_count'] ?? 0;
            if (result['success'] == true && approvedCount > 0) {
              _showSuccessSnackBar(
                  '$action - $approvedCount diskon berhasil disetujui');
            } else {
              _showErrorSnackBar(result['message'] ?? 'Approval failed');
            }

            // Send notification using unified notification service
            try {
              final coreNotificationService =
                  locator<CoreNotificationService>();

              // Get order details for notification
              String? orderDetails;
              String? customerName;
              double? totalAmount;

              // Try to get order details from approval data
              customerName = approval.customerName;
              totalAmount = approval.extendedAmount;

              // Handle approval flow notification
              await coreNotificationService.handleApprovalFlowNotification(
                orderLetterId: approval.id.toString(),
                approverUserId: currentUserId.toString(),
                approverName: currentUserName,
                approvalAction: action,
                approvalLevel: 'Level $jobLevelId',
                comment: '', // Could be added later if needed
                customerName: customerName,
                totalAmount: totalAmount,
              );
            } catch (e) {
              // Don't fail the approval if notification fails
            }

            // Refresh timeline data for this approval card
            final cardKey = _approvalCardKeys[approval.id];
            if (cardKey?.currentState != null) {
              final cardState = cardKey!.currentState as dynamic;
              if (cardState.refreshTimelineData != null) {
                await cardState.refreshTimelineData();
              }
            }

            // Update only this specific approval instead of full refresh
            context.read<ApprovalBloc>().add(UpdateSingleApproval(approval.id));
          } catch (e) {
            _showErrorSnackBar('Failed to process approval: $e');
          }
        },
      ),
    );
  }

  void _showApprovalTimeline(ApprovalEntity approval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildApprovalTimelineModal(context, approval),
    );
  }

  Widget _buildApprovalTimelineModal(
    BuildContext context,
    ApprovalEntity approval,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.timeline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Approval Timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Order #${approval.id} - ${approval.customerName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceVariant.withOpacity(
                      0.3,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),

          // Timeline Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildApprovalTimeline(context, approval),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalTimeline(BuildContext context, ApprovalEntity approval) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          locator<ApprovalRepository>().getDiscountsForTimeline(approval.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 300,
            child: Center(
              child: Text('Error loading timeline: ${snapshot.error}'),
            ),
          );
        }

        final rawDiscounts = snapshot.data ?? [];

        // Sort discounts by approver_level_id for sequential display
        final sortedDiscounts = List<Map<String, dynamic>>.from(rawDiscounts)
          ..sort((a, b) {
            final levelA = a['approver_level_id'] ?? 0;
            final levelB = b['approver_level_id'] ?? 0;
            return levelA.compareTo(levelB);
          });

        final Map<int, Map<String, dynamic>> approvalLevelsMap = {};

        // Add creator (User level) as the first level
        approvalLevelsMap[1] = {
          'level': 1,
          'title': 'User',
          'name': approval.creator,
          'status': 'completed',
        };

        // Add levels based on actual discount data with sequential logic
        bool previousLevelApproved = true; // User level is always approved

        for (final discount in sortedDiscounts) {
          final approverLevelId = discount['approver_level_id'];
          final approved = discount['approved'];
          final approverName = discount['approver_name'];
          final approverId = discount['approver'];

          if (approverLevelId != null) {
            String title = '';
            switch (approverLevelId) {
              case 1:
                title = 'User';
                break;
              case 2:
                title = 'Direct Leader';
                break;
              case 3:
                title = 'Indirect Leader';
                break;
              case 4:
                title = 'Controller';
                break;
              case 5:
                title = 'Analyst';
                break;
              default:
                title = 'Level $approverLevelId';
            }

            String status = 'pending';
            if (approved == true) {
              status = 'completed';
              previousLevelApproved = true;
            } else if (approved == false) {
              status = 'rejected';
              previousLevelApproved = false;
            } else if (approverId != null) {
              // Check if previous level is approved for sequential logic
              if (previousLevelApproved) {
                status = 'pending';
              } else {
                status =
                    'blocked'; // Cannot approve until previous level is approved
              }
            }

            approvalLevelsMap[approverLevelId] = {
              'level': approverLevelId,
              'title': title,
              'name': approverName ?? 'Pending',
              'status': status,
            };
          }
        }

        // Convert map to sorted list
        final approvalLevels = approvalLevelsMap.values.toList()
          ..sort(
            (a, b) => (a['level'] as int).compareTo(b['level'] as int),
          );

        // Ensure User level is always completed
        if (approvalLevels.isNotEmpty) {
          approvalLevels[0]['status'] = 'completed';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.timeline_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Approval Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timeline
              ...approvalLevels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;
                final isLast = index == approvalLevels.length - 1;

                Color statusColor;
                IconData statusIcon;
                String statusText;

                switch (level['status']) {
                  case 'completed':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Approved';
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    statusText = 'Rejected';
                    break;
                  case 'blocked':
                    statusColor = Colors.grey;
                    statusIcon = Icons.lock;
                    statusText = 'Blocked (Previous level not approved)';
                    break;
                  case 'pending':
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.schedule;
                    statusText = 'Pending';
                    break;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dot and line
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: statusColor, width: 2),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 60,
                            color: statusColor.withOpacity(0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Level info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level['name'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  bool _isNameMatch(String? name1, String name2) {
    if (name1 == null) return false;
    return name1.trim().toLowerCase() == name2.trim().toLowerCase();
  }

  void _showItemDetailsModal(ApprovalEntity approval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemDetailsModal(context, approval),
    );
  }

  /// Group approval details by kasur (like draft page) to combine all related items
  List<Map<String, dynamic>> _groupApprovalDetails(
      List<ApprovalDetailEntity> details) {
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (final detail in details) {
      // Group by kasur (desc1) - same as draft page
      final kasur = detail.desc1;

      if (groupedItems.containsKey(kasur)) {
        // If kasur already exists, add to quantity and total price
        final existingItem = groupedItems[kasur]!;
        final existingQty = existingItem['quantity'] as int;
        final existingTotalPrice = existingItem['totalPrice'] as double;

        groupedItems[kasur] = {
          ...existingItem,
          'quantity': existingQty + detail.qty,
          'totalPrice': existingTotalPrice + (detail.unitPrice * detail.qty),
        };
      } else {
        // Create new grouped item based on kasur
        groupedItems[kasur] = {
          'kasur': kasur,
          'ukuran': detail.desc2,
          'divan': '', // Will be filled from other details
          'headboard': '', // Will be filled from other details
          'sorong': '', // Will be filled from other details
          'bonus':
              <Map<String, dynamic>>[], // Will be filled from other details
          'quantity': detail.qty,
          'netPrice': detail.unitPrice,
          'totalPrice': detail.unitPrice * detail.qty,
        };
      }
    }

    return groupedItems.values.toList();
  }

  Widget _buildItemDetailsModal(BuildContext context, ApprovalEntity approval) {
    final items = _groupApprovalDetails(approval.details);
    final customerName = approval.customerName;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Header with Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.08),
                  colorScheme.primary.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Items',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              fontSize: 20,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            customerName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              approval.status,
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Enhanced Items List
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final kasur = item['kasur'] as String;
                final ukuran = item['ukuran'] as String;
                final divan = item['divan'] as String;
                final headboard = item['headboard'] as String;
                final sorong = item['sorong'] as String;
                final bonus = item['bonus'] as List<Map<String, dynamic>>;
                final quantity = item['quantity'] as int;
                final netPrice = item['netPrice'] as double;
                final totalPrice = item['totalPrice'] as double;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Item Header with gradient
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.05),
                              colorScheme.primary.withOpacity(0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bed_rounded,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Item ${index + 1}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    kasur.isNotEmpty ? kasur : 'Tanpa Kasur',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Qty: $quantity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Item Details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Specifications (same as draft page)
                            if (ukuran.isNotEmpty) ...[
                              _buildSpecificationRow('Ukuran', ukuran,
                                  Icons.straighten_rounded, colorScheme),
                              const SizedBox(height: 8),
                            ],
                            if (divan.isNotEmpty && divan != 'Tanpa Divan') ...[
                              _buildSpecificationRow('Divan', divan,
                                  Icons.chair_rounded, colorScheme),
                              const SizedBox(height: 8),
                            ],
                            if (headboard.isNotEmpty &&
                                headboard != 'Tanpa Headboard') ...[
                              _buildSpecificationRow('Headboard', headboard,
                                  Icons.headset_rounded, colorScheme),
                              const SizedBox(height: 8),
                            ],
                            if (sorong.isNotEmpty &&
                                sorong != 'Tanpa Sorong') ...[
                              _buildSpecificationRow('Sorong', sorong,
                                  Icons.drag_handle_rounded, colorScheme),
                              const SizedBox(height: 8),
                            ],

                            // Enhanced Bonus Items (same as draft page)
                            if (bonus.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.secondary.withOpacity(0.1),
                                      colorScheme.secondary.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        colorScheme.secondary.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondary
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.card_giftcard_rounded,
                                            color: colorScheme.secondary,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Bonus Items',
                                          style: TextStyle(
                                            color: colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ...bonus.map((bonusItem) {
                                      final name =
                                          bonusItem['name'] as String? ?? '';
                                      final qty =
                                          bonusItem['quantity'] as int? ?? 0;
                                      if (name.isNotEmpty && qty > 0) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: colorScheme.outline
                                                  .withOpacity(0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: colorScheme.secondary,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.onSurface,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.secondary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  '${qty}x',
                                                  style: TextStyle(
                                                    color:
                                                        colorScheme.secondary,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Enhanced Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceVariant.withOpacity(0.3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: AppColors.info,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Total Items',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${items.length} items',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.attach_money_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${_formatNumber(approval.extendedAmount.toInt())}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Widget _buildSpecificationRow(
      String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSuccessSnackBar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: action == 'approve' ? AppColors.success : AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                action == 'approve'
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action == 'approve' ? 'Approved!' : 'Rejected!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Order has been ${action}d successfully',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  List<ApprovalEntity> _filterApprovals(List<ApprovalEntity> approvals) {
    if (_selectedFilter == 'All') return approvals;
    return approvals
        .where(
          (approval) =>
              approval.status.toLowerCase() == _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            _buildCompactHeader(
              theme,
              colorScheme,
              size,
              _pendingCount,
              _approvedCount,
              _rejectedCount,
            ),

            // Compact Filter Section
            _buildCompactFilters(colorScheme),

            // Content Area
            Expanded(
              child: BlocConsumer<ApprovalBloc, ApprovalState>(
                listener: (context, state) {
                  if (state is ApprovalError) {
                    _showErrorSnackBar(state.message);
                  }
                },
                builder: (context, state) {
                  if (_isLoadingUserInfo) {
                    return _buildCompactLoadingState(colorScheme);
                  } else if (state is ApprovalLoading) {
                    return ApprovalSkeletonList(itemCount: 3);
                  } else if (state is ApprovalLoaded) {
                    // Calculate stats from API data
                    final pending = state.approvals
                        .where((a) => a.status.toLowerCase() == 'pending')
                        .length;
                    final approved = state.approvals
                        .where((a) => a.status.toLowerCase() == 'approved')
                        .length;
                    final rejected = state.approvals
                        .where((a) => a.status.toLowerCase() == 'rejected')
                        .length;

                    // Check pagination info
                    final paginationInfo =
                        locator<ApprovalRepository>().getPaginationInfo();

                    // Update state for header and pagination
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _pendingCount = pending;
                          _approvedCount = approved;
                          _rejectedCount = rejected;
                          _usePagination =
                              paginationInfo['should_use_pagination'] ?? false;
                        });
                      }
                    });

                    final filteredApprovals = _filterApprovals(state.approvals);
                    return RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: _buildPaginatedContentState(
                        context,
                        filteredApprovals,
                        colorScheme,
                        paginationInfo,
                      ),
                    );
                  } else if (state is ApprovalError) {
                    return _buildCompactErrorState(
                      context,
                      state.message,
                      colorScheme,
                    );
                  }
                  return _buildCompactEmptyState(colorScheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    Size size,
    int pending,
    int approved,
    int rejected,
  ) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Compact App Bar
                  Row(
                    children: [
                      // Back Button
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: () => context.go(RoutePaths.product),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colorScheme.primary,
                            size: 16,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Title Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Approval Hub',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              _isStaffLevel
                                  ? 'View Only - Staff Level'
                                  : 'Manage & Review Orders',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isStaffLevel
                                    ? AppColors.warning
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pull-to-refresh available, no need for button
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Mini Stats Section
                  _buildMiniStats(colorScheme, pending, approved, rejected),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStats(
    ColorScheme colorScheme,
    int pending,
    int approved,
    int rejected,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            'Pending',
            pending.toString(),
            Icons.pending_actions_rounded,
            AppColors.warning,
            colorScheme,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildMiniStatCard(
            'Approved',
            approved.toString(),
            Icons.check_circle_rounded,
            AppColors.success,
            colorScheme,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildMiniStatCard(
            'Rejected',
            rejected.toString(),
            Icons.cancel_rounded,
            AppColors.error,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ColorScheme colorScheme,
  ) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.1), width: 1),
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactFilters(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _filterOptions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final filter = entry.value;
                  final isSelected = _selectedFilter == filter;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceVariant.withOpacity(
                                  0.3,
                                ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getFilterIcon(filter),
                              color: isSelected
                                  ? Colors.white
                                  : colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return Icons.dashboard_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.filter_list_rounded;
    }
  }

  Widget _buildPaginatedContentState(
    BuildContext context,
    List<ApprovalEntity> approvals,
    ColorScheme colorScheme,
    Map<String, dynamic> paginationInfo,
  ) {
    if (paginationInfo['should_use_pagination'] == true) {
      return _buildPaginatedList(
          context, approvals, colorScheme, paginationInfo);
    } else {
      return _buildCompactContentState(context, approvals, colorScheme);
    }
  }

  Widget _buildPaginatedList(
    BuildContext context,
    List<ApprovalEntity> approvals,
    ColorScheme colorScheme,
    Map<String, dynamic> paginationInfo,
  ) {
    return Column(
      children: [
        // Pagination info header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Showing ${approvals.length} of ${paginationInfo['total_items']} items',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              if (_usePagination)
                Text(
                  'Page $_currentPage of ${paginationInfo['total_pages']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),

        // List with lazy loading
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo.metrics.pixels ==
                      scrollInfo.metrics.maxScrollExtent &&
                  _hasMoreData &&
                  !_isLoadingMore) {
                _loadMoreData();
              }
              return false;
            },
            child: _buildApprovalsList(approvals),
          ),
        ),

        // Loading more indicator
        if (_isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading more...',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactContentState(
    BuildContext context,
    List<ApprovalEntity> approvals,
    ColorScheme colorScheme,
  ) {
    if (approvals.isEmpty) {
      return _buildCompactEmptyState(colorScheme);
    }

    return _buildApprovalsList(approvals);
  }

  Widget _buildApprovalsList(List<ApprovalEntity> approvals) {
    // Check if loading new data
    final isLoadingNewData = ApprovalCache.isLoadingNewData();
    final totalItems = approvals.length + (isLoadingNewData ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Show skeleton at top if loading new data
        if (index == 0 && isLoadingNewData) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ApprovalSkeletonCard(),
          );
        }

        // Adjust index for actual approval data
        final approvalIndex = isLoadingNewData ? index - 1 : index;
        if (approvalIndex >= approvals.length) return const SizedBox.shrink();

        final approval = approvals[approvalIndex];

        // Create key for this approval card if not exists
        if (!_approvalCardKeys.containsKey(approval.id)) {
          _approvalCardKeys[approval.id] = GlobalKey();
        }

        // Optimized animation - only animate first few items
        if (index < 3) {
          return AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _slideAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ApprovalCard(
                key: _approvalCardKeys[approval.id],
                approval: approval,
                onTap: _isStaffLevel
                    ? () => _showItemDetailsModal(approval)
                    : () => _showApprovalModal(approval),
                onItemsTap: _isStaffLevel
                    ? null
                    : () => _showItemDetailsModal(approval),
                isStaffLevel: _isStaffLevel,
              ),
            ),
          );
        } else {
          // No animation for items beyond index 3 to improve performance
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ApprovalCard(
              key: _approvalCardKeys[approval.id],
              approval: approval,
              onTap: _isStaffLevel
                  ? () => _showItemDetailsModal(approval)
                  : () => _showApprovalModal(approval),
              onItemsTap:
                  _isStaffLevel ? null : () => _showItemDetailsModal(approval),
              isStaffLevel: _isStaffLevel,
            ),
          );
        }
      },
    );
  }

  Widget _buildCompactLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Approvals...',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactErrorState(
    BuildContext context,
    String message,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadApprovals,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Approvals Found',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are no approvals to display at the moment',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or try a different filter',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  bool _canUserApproveSequentially(
    List<Map<String, dynamic>> rawDiscounts,
    int currentUserId,
    String currentUserName,
  ) {
    // Sort discounts by approver_level_id to ensure sequential order
    final sortedDiscounts = List<Map<String, dynamic>>.from(rawDiscounts)
      ..sort((a, b) {
        final levelA = a['approver_level_id'] ?? 0;
        final levelB = b['approver_level_id'] ?? 0;
        return levelA.compareTo(levelB);
      });

    // Find current user's level and check if they have already approved
    int? currentUserLevel;
    bool hasUserApproved = false;

    for (final discount in sortedDiscounts) {
      final approverId = discount['approver'];
      final approverName = discount['approver_name'];
      final level = discount['approver_level_id'];
      final approved = discount['approved'];

      if (approverId == currentUserId ||
          _isNameMatch(approverName, currentUserName)) {
        currentUserLevel = level;
        hasUserApproved = approved == true;
        break;
      }
    }

    if (currentUserLevel == null) {
      return false;
    }

    // If user has already approved, they can always see the approval (for tracking)
    if (hasUserApproved) {
      return true;
    }

    // For level 1 (User), always allow (auto-approved)
    if (currentUserLevel == 1) {
      return true;
    }

    // For level 2-5, check if immediate previous level is approved
    bool foundPreviousLevel = false;
    for (final discount in sortedDiscounts) {
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

    // If no previous level found, allow approval (for new order letters)
    if (!foundPreviousLevel) {
      return true;
    }

    // Check if current user's level is pending
    for (final discount in sortedDiscounts) {
      final level = discount['approver_level_id'];
      final approved = discount['approved'];
      final approverId = discount['approver'];
      final approverName = discount['approver_name'];

      if (level != null &&
          level == currentUserLevel &&
          (approverId == currentUserId ||
              _isNameMatch(approverName, currentUserName))) {
        if (approved == null || approved == false) {
          return true;
        } else {
          return false;
        }
      }
    }

    return false;
  }
}
