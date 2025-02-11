import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../navigation/navigation_service.dart';
import '../../../../navigation/route_path.dart';
import '../../../../services/auth_service.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/event/auth_event.dart';
import '../../../authentication/presentation/bloc/state/auth_state.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Future<void> _logout() async {
    bool confirmLogout = await _showLogoutDialog();
    if (!confirmLogout || !mounted) return;

    context.read<AuthBloc>().add(AuthLogoutRequested());
    await AuthService.logout();

    if (!mounted) return;
    NavigationService.navigateAndReplace(RoutePaths.login);
  }

  Future<bool> _showLogoutDialog() async {
    if (!mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Konfirmasi Logout"),
            content: const Text("Apakah Anda yakin ingin keluar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          if (!mounted) return;
          NavigationService.navigateAndReplace(RoutePaths.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Product Page"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),
        body: const Center(
          child: Text(
            "Selamat Datang di Product Page!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
