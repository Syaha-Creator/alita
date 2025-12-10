// lib/features/product/presentation/widgets/logout_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../theme/app_colors.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../bloc/product_event.dart';

class LogoutButton extends StatelessWidget {
  final Color? iconColor;

  const LogoutButton({super.key, this.iconColor});

  Future<void> _logout(BuildContext context) async {
    // Dialog konfirmasi tetap sama
    bool confirmLogout = await _showLogoutDialog(context);
    if (!confirmLogout || !context.mounted) return;

    // 1. Reset state produk terlebih dahulu.
    context.read<ProductBloc>().add(ResetProductState());

    // 2. Kirim event untuk proses logout di AuthBloc.
    context.read<AuthBloc>().add(AuthLogoutRequested());
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    // Menggunakan ConfirmationDialog untuk konsistensi UI
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Konfirmasi Logout',
      message: 'Apakah Anda yakin ingin keluar?',
      confirmText: 'Logout',
      type: ConfirmationType.warning,
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        Icons.logout_rounded,
        color: iconColor ??
            (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
        size: 22,
      ),
      onPressed: () => _logout(context),
      tooltip: 'Logout',
      splashRadius: 20,
    );
  }
}
