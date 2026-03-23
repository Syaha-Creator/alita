import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_warning_row.dart';

enum ApprovalBarState { pendingAction, completed, viewer, loading }

/// Bottom bar for approval detail actions and completion state.
class ApprovalDetailBottomBar extends ConsumerWidget {
  final ApprovalBarState state;
  final bool isLoading;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const ApprovalDetailBottomBar({
    super.key,
    required this.state,
    required this.isLoading,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state) {
      ApprovalBarState.loading => const SizedBox.shrink(),
      ApprovalBarState.pendingAction => _buildActionButtons(context, ref),
      ApprovalBarState.completed => _buildBanner(
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.success,
          text: 'Anda sudah menyelesaikan persetujuan ini',
          textColor: AppColors.success,
          bgColor: AppColors.success.withValues(alpha: 0.08),
          borderColor: AppColors.success.withValues(alpha: 0.4),
        ),
      ApprovalBarState.viewer => _buildBanner(
          icon: Icons.hourglass_top_rounded,
          iconColor: AppColors.warning,
          text: 'Menunggu persetujuan pihak terkait',
          textColor: AppColors.warning,
          bgColor: AppColors.warning.withValues(alpha: 0.08),
          borderColor: AppColors.warning.withValues(alpha: 0.3),
        ),
    };
  }

  Widget _buildBanner({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final disabled = isLoading || isOffline;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline) const OfflineWarningRow(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () {
                            hapticDestructive();
                            onReject();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'TOLAK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: disabled
                        ? null
                        : () {
                            hapticConfirm();
                            onApprove();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SETUJUI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
