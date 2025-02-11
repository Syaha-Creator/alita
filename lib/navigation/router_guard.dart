import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'route_path.dart';
import 'services/auth_service.dart';

class RouterGuard {
  static Future<String?> redirect(
      BuildContext context, GoRouterState state) async {
    bool isAuthenticated = await AuthService.isLoggedIn();

    if (!isAuthenticated && state.matchedLocation != RoutePaths.login) {
      return RoutePaths.login;
    }
    return null;
  }
}
