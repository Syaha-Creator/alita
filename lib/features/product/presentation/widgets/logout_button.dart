// lib/features/product/presentation/widgets/logout_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../bloc/product_event.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

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
    // ... (kode dialog Anda tidak perlu diubah, sudah bagus)
    final theme = Theme.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text("Konfirmasi Logout", style: theme.textTheme.titleLarge),
            content: const Text("Apakah Anda yakin ingin keluar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                child: const Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () => _logout(context),
    );
  }
}
