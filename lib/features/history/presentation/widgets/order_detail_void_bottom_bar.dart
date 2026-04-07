import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_layout_tokens.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/offline_warning_row.dart';

/// Footer tetap untuk void SP dari konteks Persetujuan diskon (mirip [ApprovalDetailBottomBar]).
class OrderDetailVoidBottomBar extends ConsumerWidget {
  const OrderDetailVoidBottomBar({
    super.key,
    required this.isLoading,
    required this.onVoid,
  });

  final bool isLoading;
  final VoidCallback onVoid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    final disabled = isLoading || isOffline;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppLayoutTokens.space16,
          AppLayoutTokens.space12,
          AppLayoutTokens.space16,
          AppLayoutTokens.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline) const OfflineWarningRow(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: disabled
                    ? null
                    : () {
                        hapticDestructive();
                        onVoid();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLoading ? 'Memproses…' : 'VOID SURAT PESANAN',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
