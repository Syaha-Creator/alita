import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/telemetry_access.dart';
import '../../logic/auth_provider.dart';
import '../../../indirect/logic/sales_mode_bootstrap.dart';

/// Saat session dari storage selesai dibaca: admin → hub pilih mode; non-admin → sync mode dari `address_number` lalu home.
class AuthBootPage extends ConsumerStatefulWidget {
  const AuthBootPage({super.key});

  @override
  ConsumerState<AuthBootPage> createState() => _AuthBootPageState();
}

class _AuthBootPageState extends ConsumerState<AuthBootPage> {
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authProvider, (previous, next) {
      unawaited(_tryNavigate(next));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_tryNavigate(ref.read(authProvider)));
    });
  }

  Future<void> _tryNavigate(AuthState auth) async {
    if (!mounted || _didNavigate || auth.isLoading) return;
    _didNavigate = true;

    if (!auth.isLoggedIn) {
      context.go('/login');
      return;
    }

    if (TelemetryAccess.canChooseSalesMode(auth.userId)) {
      context.go('/sales_hub');
      return;
    }

    await syncSalesModeForNonAdminUser(
      ref,
      userId: auth.userId,
      addressNumber: auth.addressNumber,
    );
    if (!mounted) return;
    context.go('/');
  }

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
