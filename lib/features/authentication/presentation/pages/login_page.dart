import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppPadding.p24,
            vertical: AppPadding.p20,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppPadding.p16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withAlpha(60)
                          : Colors.black.withAlpha(30),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Alita Pricelist',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Log in now to continue',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w300,
                        color: colorScheme.onPrimary.withAlpha(230),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Login Image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    isDark
                        ? 'assets/images/login_dark.png'
                        : 'assets/images/login.png',
                    width: screenWidth * 0.7,
                    height: screenWidth * 0.5,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Spacer untuk memberikan jarak yang proporsional
              const Spacer(),

              // Login Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppPadding.p20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withAlpha(60)
                          : Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const LoginForm(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
