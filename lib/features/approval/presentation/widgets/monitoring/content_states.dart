import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../theme/app_colors.dart';
import '../../../domain/entities/approval_entity.dart';
import '../approval_card.dart';

/// Widget untuk menampilkan loading state
class ApprovalLoadingState extends StatelessWidget {
  const ApprovalLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppPadding.p20),
          Text(
            'Loading Approvals...',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppPadding.p8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Widget untuk menampilkan error state
class ApprovalErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ApprovalErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppPadding.p20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppPadding.p12),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppPadding.p24),
            ElevatedButton(
              onPressed: onRetry,
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white),
                  SizedBox(width: AppPadding.p8),
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
}

/// Widget untuk menampilkan empty state
class ApprovalEmptyState extends StatelessWidget {
  const ApprovalEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState.noData(
      title: 'No Approvals Found',
      subtitle:
          'There are no approvals to display at the moment.\nCheck back later or try a different filter.',
    );
  }
}

/// Widget untuk menampilkan list approval dengan pagination
class PaginatedApprovalList extends StatelessWidget {
  final List<ApprovalEntity> approvals;
  final Map<String, dynamic> paginationInfo;
  final bool usePagination;
  final int currentPage;
  final bool isLoadingMore;
  final bool hasMoreData;
  final bool isStaffLevel;
  final Map<int, GlobalKey> approvalCardKeys;
  final Animation<double> fadeAnimation;
  final Animation<double> slideAnimation;
  final void Function(ApprovalEntity) onApprovalTap;
  final void Function(ApprovalEntity) onItemsTap;
  final VoidCallback onLoadMore;

  const PaginatedApprovalList({
    super.key,
    required this.approvals,
    required this.paginationInfo,
    required this.usePagination,
    required this.currentPage,
    required this.isLoadingMore,
    required this.hasMoreData,
    required this.isStaffLevel,
    required this.approvalCardKeys,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onApprovalTap,
    required this.onItemsTap,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (paginationInfo['should_use_pagination'] == true) {
      return _buildPaginatedList(colorScheme);
    } else {
      return _buildSimpleList();
    }
  }

  Widget _buildPaginatedList(ColorScheme colorScheme) {
    return Column(
      children: [
        // Pagination info header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
              const SizedBox(width: AppPadding.p8),
              Text(
                'Showing ${approvals.length} of ${paginationInfo['total_items']} items',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (usePagination)
                Text(
                  'Page $currentPage of ${paginationInfo['total_pages']}',
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
                  hasMoreData &&
                  !isLoadingMore) {
                onLoadMore();
              }
              return false;
            },
            child: _buildApprovalsList(),
          ),
        ),

        // Loading more indicator
        if (isLoadingMore)
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
                const SizedBox(width: AppPadding.p12),
                Text(
                  'Loading more...',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSimpleList() {
    if (approvals.isEmpty) {
      return const ApprovalEmptyState();
    }
    return _buildApprovalsList();
  }

  Widget _buildApprovalsList() {
    final totalItems = approvals.length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index >= approvals.length) return const SizedBox.shrink();

        final approval = approvals[index];

        // Optimized animation - only animate first few items
        if (index < 3) {
          return AnimatedBuilder(
            animation: Listenable.merge([fadeAnimation, slideAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - slideAnimation.value)),
                child: Opacity(
                  opacity: fadeAnimation.value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ApprovalCard(
                key: approvalCardKeys[approval.id] ?? ValueKey('approval_${approval.id}_$index'),
                approval: approval,
                onTap: isStaffLevel
                    ? () => onItemsTap(approval)
                    : () => onApprovalTap(approval),
                onItemsTap: isStaffLevel ? null : () => onItemsTap(approval),
                isStaffLevel: isStaffLevel,
              ),
            ),
          );
        } else {
          // No animation for items beyond index 3 to improve performance
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ApprovalCard(
              key: approvalCardKeys[approval.id] ?? ValueKey('approval_${approval.id}_$index'),
              approval: approval,
              onTap: isStaffLevel
                  ? () => onItemsTap(approval)
                  : () => onApprovalTap(approval),
              onItemsTap: isStaffLevel ? null : () => onItemsTap(approval),
              isStaffLevel: isStaffLevel,
            ),
          );
        }
      },
    );
  }
}

