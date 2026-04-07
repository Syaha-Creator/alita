import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/go_router_pop_scope.dart';
import '../../logic/approval_order_wrap_provider.dart';
import 'approval_detail_page.dart';

/// Memuat SP dari API lalu menampilkan [ApprovalDetailPage] (tema sama dengan app).
///
/// Dipakai saat navigasi dari notifikasi FCM yang hanya membawa `order_letter_id`.
class ApprovalDetailLoaderPage extends ConsumerWidget {
  const ApprovalDetailLoaderPage({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(approvalOrderWrapProvider(orderId));

    return async.when(
      loading: () => GoRouterPopScope(
        fallbackLocation: '/approval_inbox',
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Persetujuan Diskon',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => GoRouterPopScope.handlePop(
                context,
                fallbackLocation: '/approval_inbox',
              ),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => GoRouterPopScope(
        fallbackLocation: '/approval_inbox',
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Persetujuan Diskon',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => GoRouterPopScope.handlePop(
                context,
                fallbackLocation: '/approval_inbox',
              ),
            ),
          ),
          body: ErrorStateView(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat',
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () =>
                ref.invalidate(approvalOrderWrapProvider(orderId)),
            iconColor: AppColors.error,
            buttonColor: AppColors.accent,
            buttonTextColor: AppColors.onPrimary,
          ),
        ),
      ),
      data: (wrap) => ApprovalDetailPage(orderData: wrap),
    );
  }
}
