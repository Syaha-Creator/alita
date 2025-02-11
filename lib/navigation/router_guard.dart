import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_path.dart';
import '../services/auth_service.dart';

class RouterGuard {
  static Timer? _authCheckTimer;

  static Future<String?> redirect(
      BuildContext context, GoRouterState state) async {
    bool isAuthenticated = await AuthService.isLoggedIn();

    if (!isAuthenticated && state.matchedLocation != RoutePaths.login) {
      return RoutePaths.login;
    }

    _authCheckTimer?.cancel();
    _authCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        if (!await AuthService.isLoggedIn()) {
          timer.cancel();

          if (context.mounted) {
            GoRouter.of(context).go(RoutePaths.login);
          }
        }
      },
    );

    return null;
  }
}
