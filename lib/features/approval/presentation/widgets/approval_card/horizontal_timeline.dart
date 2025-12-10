import 'package:flutter/material.dart';
import '../../../../../config/app_constant.dart';
import '../../../../../theme/app_colors.dart';

/// Clean horizontal timeline for approval flow
class HorizontalTimeline extends StatelessWidget {
  final List<Map<String, dynamic>>? discountData;
  final bool isLoading;
  final String? error;
  final String? creatorName;
  final String fallbackCreator;

  const HorizontalTimeline({
    super.key,
    required this.discountData,
    required this.isLoading,
    this.error,
    this.creatorName,
    required this.fallbackCreator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    }

    if (error != null || discountData == null || discountData!.isEmpty) {
      return const SizedBox.shrink();
    }

    final approvalLevels = _buildApprovalLevels();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: approvalLevels.asMap().entries.map((entry) {
          final index = entry.key;
          final level = entry.value;
          final isLast = index == approvalLevels.length - 1;
          final status = level['status'] as String;

          return Expanded(
            child: Row(
              children: [
                // Node
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNode(status, isDark),
                      const SizedBox(height: AppPadding.p4),
                      Text(
                        level['title'],
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status, isDark),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Connector
                if (!isLast) _buildConnector(status, isDark),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNode(String status, bool isDark) {
    final color = _getStatusColor(status, isDark);
    final icon = _getStatusIcon(status);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status == 'completed' ? color : color.withValues(alpha: 0.15),
        border:
            status != 'completed' ? Border.all(color: color, width: 1.5) : null,
      ),
      child: Icon(
        icon,
        size: 12,
        color: status == 'completed' ? Colors.white : color,
      ),
    );
  }

  Widget _buildConnector(String status, bool isDark) {
    final color = _getStatusColor(status, isDark);
    final isCompleted = status == 'completed';

    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isCompleted ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'blocked':
        return isDark ? AppColors.disabledDark : AppColors.disabledLight;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check;
      case 'rejected':
        return Icons.close;
      case 'blocked':
        return Icons.lock_outline;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  List<Map<String, dynamic>> _buildApprovalLevels() {
    final sortedDiscounts = List<Map<String, dynamic>>.from(discountData!)
      ..sort((a, b) {
        final levelA = a['approver_level_id'] ?? 0;
        final levelB = b['approver_level_id'] ?? 0;
        return levelA.compareTo(levelB);
      });

    final Map<int, Map<String, dynamic>> approvalLevelsMap = {};

    approvalLevelsMap[1] = {
      'level': 1,
      'title': 'User',
      'name': creatorName ?? fallbackCreator,
      'status': 'completed'
    };

    bool previousLevelApproved = true;

    for (final discount in sortedDiscounts) {
      final approverLevelId = discount['approver_level_id'];
      final approved = discount['approved'];
      final approverName = discount['approver_name'];
      final approverId = discount['approver'];

      if (approverLevelId != null) {
        String title = _getLevelTitle(approverLevelId);
        String status =
            _determineStatus(approved, approverId, previousLevelApproved);

        if (approved == true) {
          previousLevelApproved = true;
        } else if (approved == false) {
          previousLevelApproved = false;
        }

        approvalLevelsMap[approverLevelId] = {
          'level': approverLevelId,
          'title': title,
          'name': approverName ?? 'Pending',
          'status': status
        };
      }
    }

    final approvalLevels = approvalLevelsMap.values.toList()
      ..sort((a, b) => (a['level'] as int).compareTo(b['level'] as int));

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
        return 'Direct';
      case 3:
        return 'Indirect';
      case 4:
        return 'Analyst';
      case 5:
        return 'Controller';
      default:
        return 'Lv$levelId';
    }
  }

  String _determineStatus(
      dynamic approved, dynamic approverId, bool previousLevelApproved) {
    if (approved == true) return 'completed';
    if (approved == false) return 'rejected';
    if (approverId != null) {
      return previousLevelApproved ? 'pending' : 'blocked';
    }
    return 'pending';
  }
}
