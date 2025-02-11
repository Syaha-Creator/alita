import 'package:flutter/material.dart';

import 'app_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static void navigateTo(String routeName, {Map<String, String>? params}) {
    if (params != null) {
      AppRouter.router.goNamed(routeName, pathParameters: params);
    } else {
      AppRouter.router.go(routeName);
    }
  }

  static void goBack() {
    AppRouter.router.pop();
  }
}
