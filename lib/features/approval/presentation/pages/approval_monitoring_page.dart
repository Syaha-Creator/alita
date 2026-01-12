import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/order_letter_service.dart';
import '../../../../core/widgets/custom_toast.dart';
import '../../domain/entities/approval_entity.dart';
import '../../data/repositories/approval_repository.dart';
import '../../data/cache/approval_cache.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
import '../widgets/approval_skeleton_card.dart';
import '../widgets/monitoring/monitoring_widgets.dart';

class ApprovalMonitoringPage extends StatefulWidget {
  final ApprovalRepository? approvalRepository;
  final OrderLetterService? orderLetterService;

  const ApprovalMonitoringPage({
    super.key,
    this.approvalRepository,
    this.orderLetterService,
  });

  @override
  State<ApprovalMonitoringPage> createState() => _ApprovalMonitoringPageState();
}

class _ApprovalMonitoringPageState extends State<ApprovalMonitoringPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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

  // --- Date range filter state ---
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isDateFilterActive = false;
  bool _isLoadingDateFilter = false;

  // Add keys for approval cards to refresh timeline
  final Map<int, GlobalKey> _approvalCardKeys = {};

  // Pagination state
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _usePagination = false;

  // Background sync
  Timer? _backgroundSyncTimer;

  // Loading state for status updates
  bool _isUpdatingStatuses = false;

  // Flag to prevent duplicate initial load
  bool _hasInitialLoadCompleted = false;

  // Track previous app lifecycle state to detect resume from background
  AppLifecycleState? _previousLifecycleState;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadUserInfo();
    _loadApprovalsWithCache();
    _startBackgroundSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only check for new data if we're returning from another page (not initial load)
    if (_hasInitialLoadCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkForNewData();
      });
    }
  }

  /// Check for new data when returning to page
  Future<void> _checkForNewData() async {
    // Only check for new data if we already have loaded data
    final currentState = context.read<ApprovalBloc>().state;
    if (currentState is! ApprovalLoaded) {
      return; // Don't check if we're still loading or in error state
    }

    // If cache is older than 30 seconds, load new data incrementally
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) return;
    final cacheStats = ApprovalCache.getCacheStats(currentUserId);
    final cacheTimestamp = cacheStats['approval_cache_timestamp'] as String?;

    if (cacheTimestamp != null) {
      final cacheTime = DateTime.tryParse(cacheTimestamp);
      if (cacheTime != null) {
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference.inSeconds > 30) {
          // Update only approval statuses (lightweight operation)
          if (!mounted) return;
          setState(() {
            _isUpdatingStatuses = true;
          });

          if (!mounted) return;
          final bloc = context.read<ApprovalBloc>();
          bloc.add(const UpdateApprovalStatusesOnly());
          bloc.add(const LoadNewApprovalsIncremental());

          // Reset loading state after a delay
          Future.delayed(RetryDurations.uiRefreshDelay, () {
            if (mounted) {
              setState(() {
                _isUpdatingStatuses = false;
              });
            }
          });
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
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _mainController.dispose();
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background/paused/terminated, refresh approval data
    if (state == AppLifecycleState.resumed) {
      if (_previousLifecycleState != null &&
          _previousLifecycleState != AppLifecycleState.resumed) {
        _refreshApprovalsOnResume();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {}

    // Update previous state
    _previousLifecycleState = state;
  }

  /// Refresh approvals when app resumes from background
  void _refreshApprovalsOnResume() {
    if (!mounted) return;
    _loadApprovals(forceRefresh: true);
  }

  Future<void> _loadUserInfo() async {
    try {
      // Use injected repository or fallback to locator
      final repository =
          widget.approvalRepository ?? locator<ApprovalRepository>();

      // Check cache first
      final cachedUserInfo = await repository.getCachedUserInfo();
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
        await repository.cacheUserInfo(userInfo);

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

  void _loadApprovalsWithCache() async {
    final stopwatch = Stopwatch()..start();

    // Check if we have cached data
    final currentUserId = await AuthService.getCurrentUserId();
    if (currentUserId == null) {
      _loadApprovals(forceRefresh: true);
      return;
    }
    final cachedApprovals = ApprovalCache.getCachedApprovals(currentUserId);
    final cacheStats = ApprovalCache.getCacheStats(currentUserId);
    final cacheTimestamp = cacheStats['approval_cache_timestamp'] as String?;

    bool shouldForceRefresh = false;
    if (cachedApprovals != null &&
        cachedApprovals.isNotEmpty &&
        cacheTimestamp != null) {
      final cacheTime = DateTime.tryParse(cacheTimestamp);
      if (cacheTime != null) {
        final now = DateTime.now();
        final difference = now.difference(cacheTime);

        if (difference > RetryDurations.cacheStalenessThreshold) {
          shouldForceRefresh = true;
        } else {
          if (!mounted) return;
          context
              .read<ApprovalBloc>()
              .add(const LoadApprovals(forceRefresh: false));

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _isUpdatingStatuses = true;
              });

              context
                  .read<ApprovalBloc>()
                  .add(const UpdateApprovalStatusesOnly());

              // Reset loading state after a delay
              Future.delayed(RetryDurations.uiRefreshDelay, () {
                if (mounted) {
                  setState(() {
                    _isUpdatingStatuses = false;
                  });
                }
              });
            }
          });

          stopwatch.stop();
          return;
        }
      } else {
        shouldForceRefresh = true;
      }
    } else {
      shouldForceRefresh = true;
    }

    if (shouldForceRefresh) {
      _loadApprovals(forceRefresh: true);
    } else {
      if (!mounted) return;
      context
          .read<ApprovalBloc>()
          .add(const LoadApprovals(forceRefresh: false));
    }
    stopwatch.stop();
  }

  void _loadApprovals({bool forceRefresh = false}) {
    final stopwatch = Stopwatch()..start();

    if (!forceRefresh) {
      final repository =
          widget.approvalRepository ?? locator<ApprovalRepository>();
      repository.testCachePerformance();
    }

    context.read<ApprovalBloc>().add(LoadApprovals(forceRefresh: forceRefresh));

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
    _backgroundSyncTimer =
        Timer.periodic(RetryDurations.backgroundSyncInterval, (timer) {
      _performBackgroundSync();
    });

    // Also perform initial background sync after 30 seconds
    Timer(RetryDurations.shortUiDelay, () {
      _performBackgroundSync();
    });
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    try {
      // If date filter is active, sync with the filter parameters
      if (_isDateFilterActive && _dateFrom != null && _dateTo != null) {
        if (mounted) {
          final dateFromStr = _formatDateForApi(_dateFrom!);
          final dateToStr = _formatDateForApi(_dateTo!);
          context.read<ApprovalBloc>().add(LoadApprovals(
                forceRefresh: true,
                dateFrom: dateFromStr,
                dateTo: dateToStr,
              ));
        }
        return;
      }

      // Normal background sync (no filter)
      final repository =
          widget.approvalRepository ?? locator<ApprovalRepository>();
      await repository.backgroundSync();

      if (mounted) {
        final bloc = context.read<ApprovalBloc>();
        bloc.add(const LoadApprovals(forceRefresh: false));
        bloc.add(const LoadNewApprovalsIncremental());
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
      final repository =
          widget.approvalRepository ?? locator<ApprovalRepository>();
      final moreApprovals =
          await repository.getApprovalsWithPagination(page: nextPage);

      if (mounted) {
        if (moreApprovals.isNotEmpty) {
          _currentPage = nextPage;
          // Trigger bloc to load more data
          context
              .read<ApprovalBloc>()
              .add(const LoadApprovals(forceRefresh: false));
        } else {
          _hasMoreData = false;
        }
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
    // Check if current user is the creator of this order letter (user ID only)
    final currentUserId = await AuthService.getCurrentUserId();
    final isCurrentUserCreator =
        (currentUserId != null && approval.creator == currentUserId.toString());

    if (isCurrentUserCreator) {
      // Show approval timeline instead of modal
      _showApprovalTimeline(approval);
      return;
    }

    // Check if current user has already approved any discount in this order letter
    if (currentUserId != null) {
      try {
        final orderLetterService =
            widget.orderLetterService ?? locator<OrderLetterService>();
        final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
          orderLetterId: approval.id,
        );

        bool hasUserApproved = false;
        for (final discount in rawDiscounts) {
          final approverId = discount['approver'];
          final approved = discount['approved'];

          // Check if current user has approved this discount (user ID only)
          if (approverId == currentUserId && approved == true) {
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

    try {
      final currentUserId = await AuthService.getCurrentUserId();
      if (currentUserId != null) {
        final orderLetterService =
            widget.orderLetterService ?? locator<OrderLetterService>();
        final rawDiscounts = await orderLetterService.getOrderLetterDiscounts(
            orderLetterId: approval.id);

        // Get user's job level (user ID only)
        int jobLevelId = 1;
        for (final discount in rawDiscounts) {
          final approverId = discount['approver'];
          final approverLevelId = discount['approver_level_id'];

          if (approverId == currentUserId && approverLevelId != null) {
            jobLevelId = approverLevelId;
            break;
          }
        }

        // Get pending count (for future use or debugging)
        await orderLetterService.getPendingDiscountCount(
          orderLetterId: approval.id,
          leaderId: currentUserId,
          jobLevelId: jobLevelId,
        );
      }
    } catch (e) {
      // Continue if error
    }

    // Redirect to order letter document page for approval instead of showing modal
    if (mounted) {
      context.push(
        RoutePaths.orderLetterDocument,
        extra: approval.id,
      );
    }
  }

  void _showApprovalTimeline(ApprovalEntity approval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ApprovalTimelineModal(approval: approval),
    );
  }

  void _showItemDetailsModal(ApprovalEntity approval) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemDetailsModal(approval: approval),
    );
  }

  List<ApprovalEntity> _filterApprovals(List<ApprovalEntity> approvals) {
    // Remove duplicates based on ID first
    final uniqueApprovals = <int, ApprovalEntity>{};
    for (final approval in approvals) {
      if (!uniqueApprovals.containsKey(approval.id)) {
        uniqueApprovals[approval.id] = approval;
      }
    }
    final deduplicatedApprovals = uniqueApprovals.values.toList();

    // Apply filter
    if (_selectedFilter == 'All') return deduplicatedApprovals;
    return deduplicatedApprovals
        .where(
          (approval) =>
              approval.status.toLowerCase() == _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Status Update Loading Indicator
            if (_isUpdatingStatuses) _buildStatusUpdateIndicator(colorScheme),

            // Header
            ApprovalHeader(
              isStaffLevel: _isStaffLevel,
              isDateFilterActive: _isDateFilterActive,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              fadeAnimation: _fadeAnimation,
              slideAnimation: _slideAnimation,
              onDateRangePressed: _showDateRangePicker,
              onClearDateFilter: _clearDateFilter,
            ),

            // Filters with integrated stats
            ApprovalFilters(
              selectedFilter: _selectedFilter,
              filterOptions: _filterOptions,
              onFilterChanged: (filter) =>
                  setState(() => _selectedFilter = filter),
              fadeAnimation: _fadeAnimation,
              slideAnimation: _slideAnimation,
              pendingCount: _pendingCount,
              approvedCount: _approvedCount,
              rejectedCount: _rejectedCount,
            ),

            // Content Area
            Expanded(
              child: BlocConsumer<ApprovalBloc, ApprovalState>(
                listener: (context, state) {
                  if (state is ApprovalError) {
                    _showErrorSnackBar(state.message);
                    // Reset loading state on error
                    if (_isLoadingDateFilter) {
                      setState(() {
                        _isLoadingDateFilter = false;
                      });
                    }
                  } else if (state is ApprovalLoaded) {
                    // Reset loading state when data is loaded
                    if (_isLoadingDateFilter) {
                      setState(() {
                        _isLoadingDateFilter = false;
                      });
                    }
                  }
                },
                builder: (context, state) {
                  if (_isLoadingUserInfo) {
                    return const ApprovalLoadingState();
                  } else if (_isLoadingDateFilter || state is ApprovalLoading) {
                    return const ApprovalSkeletonList(itemCount: 3);
                  } else if (state is ApprovalLoaded) {
                    _updateStatsFromState(state);
                    final filteredApprovals = _filterApprovals(state.approvals);
                    return _buildContentArea(filteredApprovals);
                  } else if (state is ApprovalError) {
                    return ApprovalErrorState(
                      message: state.message,
                      onRetry: _loadApprovals,
                    );
                  }
                  return const ApprovalEmptyState();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateIndicator(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(width: AppPadding.p8),
          Text(
            'Memperbarui status approval...',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatsFromState(ApprovalLoaded state) {
    final pending = state.approvals
        .where((a) => a.status.toLowerCase() == 'pending')
        .length;
    final approved = state.approvals
        .where((a) => a.status.toLowerCase() == 'approved')
        .length;
    final rejected = state.approvals
        .where((a) => a.status.toLowerCase() == 'rejected')
        .length;

    final repository =
        widget.approvalRepository ?? locator<ApprovalRepository>();
    repository.getPaginationInfo().then((paginationInfo) {
      if (mounted) {
        setState(() {
          _pendingCount = pending;
          _approvedCount = approved;
          _rejectedCount = rejected;
          _usePagination = paginationInfo['should_use_pagination'] ?? false;
          _hasInitialLoadCompleted = true;
        });
      }
    });
  }

  Widget _buildContentArea(List<ApprovalEntity> filteredApprovals) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: FutureBuilder<Map<String, dynamic>>(
        future: (widget.approvalRepository ?? locator<ApprovalRepository>())
            .getPaginationInfo(),
        builder: (context, snapshot) {
          final paginationInfo = snapshot.data ??
              {
                'should_use_pagination': false,
                'total_pages': 0,
                'items_per_page': 20,
                'total_items': 0,
                'lazy_load_threshold': 50,
              };
          return PaginatedApprovalList(
            approvals: filteredApprovals,
            paginationInfo: paginationInfo,
            usePagination: _usePagination,
            currentPage: _currentPage,
            isLoadingMore: _isLoadingMore,
            hasMoreData: _hasMoreData,
            isStaffLevel: _isStaffLevel,
            approvalCardKeys: _approvalCardKeys,
            fadeAnimation: _fadeAnimation,
            slideAnimation: _slideAnimation,
            onApprovalTap: _showApprovalModal,
            onItemsTap: _showItemDetailsModal,
            onLoadMore: _loadMoreData,
          );
        },
      ),
    );
  }

  void _clearDateFilter() {
    // Close modal first if open
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Update state and show loading
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _isDateFilterActive = false;
      _isLoadingDateFilter = true;
    });

    // Show feedback toast
    CustomToast.showToast(
      'Filter tanggal dihapus',
      ToastType.success,
      duration: 2,
    );

    // Load approvals without filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovals(forceRefresh: true);
    });
  }

  void _showErrorSnackBar(String message) {
    CustomToast.showToast(message, ToastType.error, duration: 3);
  }

  /// Format date to API format (YYYY-M-D like "2025-11-1")
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Show date range picker dialog
  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateRangePickerModal(
        initialDateFrom: _dateFrom,
        initialDateTo: _dateTo,
        isDateFilterActive: _isDateFilterActive,
        onApply: (dateFrom, dateTo) {
          // Close modal first
          Navigator.of(context).pop();

          // Update state immediately for instant UI feedback and show loading
          setState(() {
            _dateFrom = dateFrom;
            _dateTo = dateTo;
            _isDateFilterActive = true;
            _isLoadingDateFilter = true;
          });

          // Show feedback toast
          final dateFromStr = _formatDateForDisplay(dateFrom);
          final dateToStr = _formatDateForDisplay(dateTo);
          CustomToast.showToast(
            'Filter diterapkan: $dateFromStr - $dateToStr',
            ToastType.success,
            duration: 2,
          );

          // Load approvals with filter
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadApprovalsWithDateFilter();
          });
        },
        onClear: _clearDateFilter,
      ),
    );
  }

  /// Format date for display (DD/MM/YYYY)
  String _formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Load approvals with date filter
  void _loadApprovalsWithDateFilter() {
    if (_dateFrom == null || _dateTo == null) {
      _loadApprovals(forceRefresh: true);
      return;
    }

    final dateFromStr = _formatDateForApi(_dateFrom!);
    final dateToStr = _formatDateForApi(_dateTo!);

    context.read<ApprovalBloc>().add(LoadApprovals(
          forceRefresh: true,
          dateFrom: dateFromStr,
          dateTo: dateToStr,
        ));
  }
}
