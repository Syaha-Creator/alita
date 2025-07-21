import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/app_constant.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 4,
        shadowColor: theme.brightness == Brightness.dark
            ? Colors.black.withAlpha(80)
            : Colors.black.withAlpha(50),
        backgroundColor: theme.primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to Alita Pricelist',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.white,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Log in now to continue',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w300,
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppPadding.p24, vertical: AppPadding.p20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/images/login_dark.png'
                          : 'assets/images/login.png',
                      width: screenWidth * 0.7,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Login Form dengan Card dan Shadow
              Container(
                padding: const EdgeInsets.all(AppPadding.p20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.dark
                          ? Colors.black.withAlpha(60)
                          : Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const LoginForm(),
              ),

              // const SizedBox(height: 20),

              // Register & Forgot Password Links
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       "Don't have an account?",
              //       style: GoogleFonts.montserrat(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w400,
              //       ),
              //     ),
              //     TextButton(
              //       onPressed: () {},
              //       child: Text(
              //         "Sign up",
              //         style: GoogleFonts.montserrat(
              //           fontSize: 14,
              //           fontWeight: FontWeight.bold,
              //           color: theme.primaryColor,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              // TextButton(
              //   onPressed: () {},
              //   child: Text(
              //     "Forgot Password?",
              //     style: GoogleFonts.montserrat(
              //       fontSize: 14,
              //       fontWeight: FontWeight.bold,
              //       color: theme.primaryColor,
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
