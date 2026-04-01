import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Layar ringan saat session dari storage belum selesai dibaca.
/// Menghindari kilas [ProductListPage] sebelum redirect ke login/home.
class AuthBootPage extends StatelessWidget {
  const AuthBootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
