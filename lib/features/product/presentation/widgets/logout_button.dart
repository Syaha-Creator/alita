import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/navigation_service.dart';
import '../../../../navigation/route_path.dart';
import '../../../../services/auth_service.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/event/auth_event.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});
  Future<void> _logout(BuildContext context) async {
    if (!context.mounted) return;

    bool confirmLogout = await _showLogoutDialog(context);
    if (!confirmLogout || !context.mounted) return;

    context.read<AuthBloc>().add(AuthLogoutRequested());
    await AuthService.logout();

    if (context.mounted) {
      NavigationService.navigateAndReplace(RoutePaths.login);
    }
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: colorScheme.surface,
            title: Text(
              "Konfirmasi Logout",
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            content: Text(
              "Apakah Anda yakin ingin keluar?",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDarkMode ? Colors.cyanAccent : colorScheme.secondary,
                ),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? Colors.red.shade700 : colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
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
