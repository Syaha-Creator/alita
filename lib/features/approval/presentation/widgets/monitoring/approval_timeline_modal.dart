import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import 'package:go_router/go_router.dart';
import '../../../../../config/dependency_injection.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../theme/app_colors.dart';
import '../../../data/repositories/approval_repository.dart';
import '../../../domain/entities/approval_entity.dart';

/// Modal untuk menampilkan timeline approval
class ApprovalTimelineModal extends StatelessWidget {
  final ApprovalEntity approval;

  const ApprovalTimelineModal({
    super.key,
    required this.approval,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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
              color: isDark
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppPadding.p12),
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
                    backgroundColor:
                        colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
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
              child: _ApprovalTimelineContent(approval: approval),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalTimelineContent extends StatelessWidget {
  final ApprovalEntity approval;

  const _ApprovalTimelineContent({required this.approval});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future:
          locator<ApprovalRepository>().getDiscountsForTimeline(approval.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: LoadingState(),
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

        final approvalLevels = _buildApprovalLevels(sortedDiscounts);

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, color: AppColors.warning),
                  const SizedBox(width: AppPadding.p8),
                  Text(
                    'Approval Timeline',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppPadding.p20),

              // Timeline
              ...approvalLevels.asMap().entries.map((entry) {
                final index = entry.key;
                final level = entry.value;
                final isLast = index == approvalLevels.length - 1;

                return _TimelineItem(
                  level: level,
                  isLast: isLast,
                  isDark: isDark,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildApprovalLevels(
      List<Map<String, dynamic>> sortedDiscounts) {
    final Map<int, Map<String, dynamic>> approvalLevelsMap = {};

    // Initialize User level with creator info
    String userLevelName = approval.creator;

    // Check if we have User level (level 1) in discount data to get the real name
    final userLevelDiscount = sortedDiscounts.firstWhere(
      (d) => d['approver_level_id'] == 1,
      orElse: () => {},
    );

    if (userLevelDiscount.isNotEmpty &&
        userLevelDiscount['approver_name'] != null) {
      userLevelName = userLevelDiscount['approver_name'];
    }

    // Add creator (User level) as the first level
    approvalLevelsMap[1] = {
      'level': 1,
      'title': 'User',
      'name': userLevelName,
      'status': 'completed',
    };

    // Add levels based on actual discount data with sequential logic
    bool previousLevelApproved = true;

    for (final discount in sortedDiscounts) {
      final approverLevelId = discount['approver_level_id'];
      final approved = discount['approved'];
      final approverName = discount['approver_name'];
      final approverId = discount['approver'];

      if (approverLevelId != null) {
        String title = _getLevelTitle(approverLevelId);
        String status = _getStatus(approved, approverId, previousLevelApproved);

        if (approved == true) {
          previousLevelApproved = true;
        } else if (approved == false) {
          previousLevelApproved = false;
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
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

    // Ensure User level is always completed
    if (approvalLevels.isNotEmpty) {
      approvalLevels[0]['status'] = 'completed';
    }

    return approvalLevels;
  }

  String _getLevelTitle(int levelId) {
    switch (levelId) {
      case 1:
        return 'User';
      case 2:
        return 'Supervisor';
      case 3:
        return 'RSM';
      case 4:
        return 'Analyst';
      case 5:
        return 'Controller';
      default:
        return 'Level $levelId';
    }
  }

  String _getStatus(
      dynamic approved, dynamic approverId, bool previousApproved) {
    if (approved == true) {
      return 'completed';
    } else if (approved == false) {
      return 'rejected';
    } else if (approverId != null) {
      if (previousApproved) {
        return 'pending';
      } else {
        return 'blocked';
      }
    }
    return 'pending';
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> level;
  final bool isLast;
  final bool isDark;

  const _TimelineItem({
    required this.level,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusInfo = _getStatusInfo(level['status'] as String);

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
                color: statusInfo.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: statusInfo.color, width: 2),
              ),
              child: Icon(statusInfo.icon, color: statusInfo.color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: statusInfo.color.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: AppPadding.p16),

        // Level info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusInfo.color,
                ),
              ),
              const SizedBox(height: AppPadding.p4),
              Text(
                level['name'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppPadding.p4),
              Text(
                statusInfo.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusInfo.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'completed':
        return _StatusInfo(
          color: Colors.green,
          icon: Icons.check_circle,
          text: 'Approved',
        );
      case 'rejected':
        return _StatusInfo(
          color: Colors.red,
          icon: Icons.cancel,
          text: 'Rejected',
        );
      case 'blocked':
        return _StatusInfo(
          color: isDark ? AppColors.textSecondaryDark : Colors.grey,
          icon: Icons.lock,
          text: 'Blocked (Previous level not approved)',
        );
      case 'pending':
      default:
        return _StatusInfo(
          color: Colors.orange,
          icon: Icons.schedule,
          text: 'Pending',
        );
    }
  }
}

class _StatusInfo {
  final Color color;
  final IconData icon;
  final String text;

  _StatusInfo({
    required this.color,
    required this.icon,
    required this.text,
  });
}
