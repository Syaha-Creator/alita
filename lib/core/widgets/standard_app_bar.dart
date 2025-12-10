import 'package:flutter/material.dart';
import '../../config/app_constant.dart';
import '../../core/utils/responsive_helper.dart';
import '../../theme/app_colors.dart';

/// Standard AppBar widget untuk konsistensi di seluruh aplikasi
class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? icon;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final VoidCallback? onBack;
  final String? subtitle;

  const StandardAppBar({
    super.key,
    required this.title,
    this.icon,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.onBack,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.surfaceDark,
                    AppColors.surfaceDark.withValues(alpha: 0.95),
                  ]
                : [
                    AppColors.primaryLight,
                    AppColors.primaryLight.withValues(alpha: 0.85),
                  ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: leading ??
          (onBack != null
              ? IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? AppColors.textPrimaryDark : Colors.white,
                  ),
                )
              : null),
      title: Row(
        mainAxisSize: centerTitle ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryDark.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.primaryDark : Colors.white,
              ),
            ),
            const SizedBox(width: AppPadding.p10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      centerTitle: centerTitle,
      actions: actions,
      toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

