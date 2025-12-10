import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../config/app_constant.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.dominantDark, // 60% - Background utama
                    AppColors.secondaryDark, // 30% - Surface
                  ]
                : [
                    AppColors.accentLight, // 10% - Primary untuk gradient
                    AppColors.accentLight.withValues(alpha: 0.8),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: AppPadding.p40),

                // Logo & Welcome Section
                _buildLogoSection(isDark, screenWidth),
                const SizedBox(height: AppPadding.p24),

                // Welcome Text
                _buildWelcomeText(isDark),

                const SizedBox(height: AppPadding.p32),

                // Login Card
                _buildLoginCard(context, colorScheme, isDark, screenHeight),

                const SizedBox(height: AppPadding.p24),

                // Footer
                _buildFooter(isDark),

                const SizedBox(height: AppPadding.p20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark, double screenWidth) {
    return Column(
      children: [
        // App Icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceLight
                    .withValues(alpha: 0.1) // 30% dengan opacity
                : AppColors.surfaceLight
                    .withValues(alpha: 0.2), // 30% dengan opacity
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              isDark
                  ? 'assets/images/login_dark.png'
                  : 'assets/images/login.png',
              width: screenWidth * 0.35,
              height: screenWidth * 0.25,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Column(
      children: [
        Text(
          'Alita Pricelist',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.surfaceLight, // 30% - White untuk kontras
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppPadding.p8),
        Text(
          'Silakan masuk untuk melanjutkan',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.surfaceLight
                .withValues(alpha: 0.85), // 30% dengan opacity
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(BuildContext context, ColorScheme colorScheme,
      bool isDark, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : AppColors.surfaceLight, // 30% - Card/Surface
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.login_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppPadding.p12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Masukkan email dan password',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppPadding.p24),

          // Divider
          Divider(
            color: isDark
                ? AppColors.borderDark // 30% - Border
                : AppColors.borderLight, // 30% - Border
          ),

          const SizedBox(height: AppPadding.p20),

          // Login Form
          const LoginForm(),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String versionText = AppConstants.version;
        if (snapshot.hasData) {
          versionText =
              '${snapshot.data!.version} (${snapshot.data!.buildNumber})';
        }

        return Column(
          children: [
            Text(
              '© ${DateTime.now().year} Alita. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.surfaceLight
                    .withValues(alpha: 0.6), // 30% dengan opacity
              ),
            ),
            const SizedBox(height: AppPadding.p4),
            Text(
              'Version $versionText',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.surfaceLight
                    .withValues(alpha: 0.4), // 30% dengan opacity
              ),
            ),
          ],
        );
      },
    );
  }
}
