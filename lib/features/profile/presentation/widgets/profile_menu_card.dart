import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Single menu item for [ProfileMenuCard].
class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
}

/// Menu card with list of [ProfileMenuItem].
class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    super.key,
    required this.items,
  });

  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                const Divider(height: 1, indent: 72, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}
