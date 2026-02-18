import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_constant.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../navigation/navigation_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../product/presentation/widgets/logout_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          NavigationService.navigateAndReplace(RoutePaths.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
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
          toolbarHeight: ResponsiveHelper.getAppBarHeight(context),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryDark.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.home_rounded,
                  color: isDark ? AppColors.primaryDark : Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppPadding.p10),
              Text(
                'Alita Pricelist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            ],
          ),
          actions: [
            LogoutButton(
              iconColor: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppPadding.p24),
                Text(
                  'Pilih Tipe Pricelist',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPadding.p8),
                Text(
                  'Silakan pilih jenis pricelist yang ingin Anda lihat',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppPadding.p40),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWideScreen = constraints.maxWidth > 600;
                      if (isWideScreen) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _PricelistTypeCard(
                                title: 'Direct',
                                subtitle: 'Pricelist untuk penjualan langsung',
                                icon: Icons.store_rounded,
                                color: AppColors.primaryLight,
                                onTap: () => context.go(RoutePaths.product),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: AppPadding.p16),
                            Flexible(
                              child: _PricelistTypeCard(
                                title: 'Indirect',
                                subtitle:
                                    'Pricelist untuk penjualan tidak langsung',
                                icon: Icons.business_rounded,
                                color: AppColors.purple,
                                onTap: () =>
                                    context.go(RoutePaths.productIndirect),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: _PricelistTypeCard(
                              title: 'Direct',
                              subtitle: 'Pricelist untuk penjualan langsung',
                              icon: Icons.store_rounded,
                              color: AppColors.primaryLight,
                              onTap: () => context.go(RoutePaths.product),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(height: AppPadding.p16),
                          Expanded(
                            child: _PricelistTypeCard(
                              title: 'Indirect',
                              subtitle:
                                  'Pricelist untuk penjualan tidak langsung',
                              icon: Icons.business_rounded,
                              color: AppColors.purple,
                              onTap: () =>
                                  context.go(RoutePaths.productIndirect),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppPadding.p24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricelistTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _PricelistTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isDark ? 2 : 4,
      shadowColor: color.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.all(AppPadding.p24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.surfaceDark,
                      color.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white,
                      color.withValues(alpha: 0.05),
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: AppPadding.p16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : color,
                    ),
              ),
              const SizedBox(height: AppPadding.p8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppPadding.p16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Produk',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
