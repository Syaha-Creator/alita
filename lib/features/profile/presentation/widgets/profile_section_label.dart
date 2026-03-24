import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Section label for profile menu groups (Aktivitas, Lainnya).
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
      ),
    );
  }
}
