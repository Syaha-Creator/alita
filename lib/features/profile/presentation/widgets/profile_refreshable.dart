import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../approval/logic/approval_inbox_provider.dart';
import '../../logic/profile_provider.dart';

/// Wraps [child] in [RefreshIndicator] with profile refresh logic.
///
/// Owns the refresh behavior: invalidates profile, fetches approval inbox,
/// handles offline state and errors.
class ProfileRefreshable extends ConsumerWidget {
  const ProfileRefreshable({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator.adaptive(
      color: AppColors.accent,
      onRefresh: () => _onRefresh(context, ref),
      child: child,
    );
  }

  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      if (context.mounted) {
        AppFeedback.show(context,
            message: 'Sedang offline — tidak bisa memuat ulang.',
            type: AppFeedbackType.warning);
      }
      return;
    }
    ref.invalidate(profileProvider);
    unawaited(ref.read(approvalInboxProvider.notifier).fetchInbox());
    try {
      await ref.read(profileProvider.future);
    } catch (_) {
      if (context.mounted) {
        AppFeedback.show(context,
            message: 'Gagal memuat ulang profil.',
            type: AppFeedbackType.warning);
      }
    }
  }
}
