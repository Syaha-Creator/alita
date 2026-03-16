import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/connectivity_service.dart';

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
          iconColor: const Color(0xFF16A34A),
          text: 'Anda sudah menyelesaikan persetujuan ini',
          textColor: const Color(0xFF15803D),
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFF86EFAC),
        ),
      ApprovalBarState.viewer => _buildBanner(
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFF59E0B),
          text: 'Menunggu persetujuan pihak terkait',
          textColor: const Color(0xFF92400E),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFDE68A),
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
          color: Colors.white,
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
          color: Colors.white,
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
            if (isOffline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(
                      'Fungsi ini membutuhkan internet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            onReject();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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
                            HapticFeedback.mediumImpact();
                            onApprove();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
