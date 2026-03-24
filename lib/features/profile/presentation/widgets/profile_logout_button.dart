import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart'
    show hapticTap, showAdaptiveAlert, AdaptiveAction;
import '../../../auth/logic/auth_provider.dart';

/// Logout button for profile page.
///
/// Owns the confirmation dialog and logout logic.
class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text('Keluar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    hapticTap();
    showAdaptiveAlert(
      context: context,
      title: 'Keluar',
      content: 'Apakah Anda yakin ingin keluar dari akun?',
      actions: [
        const AdaptiveAction(
          label: 'Batal',
          color: AppColors.textSecondary,
          popResult: false,
        ),
        AdaptiveAction(
          label: 'Keluar',
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            ref.read(authProvider.notifier).logout();
          },
        ),
      ],
    );
  }
}
