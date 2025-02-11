import 'package:flutter/material.dart';

import 'app_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateTo(String routeName, {Map<String, String>? params}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (params != null) {
      AppRouter.router.goNamed(routeName, pathParameters: params);
    } else {
      AppRouter.router.go(routeName);
    }
  }

  static void navigateAndReplace(String routeName) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    AppRouter.router.replace(routeName);
  }

  static void push(String routeName, {Map<String, String>? params}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (params != null) {
      AppRouter.router.pushNamed(routeName, pathParameters: params);
    } else {
      AppRouter.router.push(routeName);
    }
  }

  static void goBack() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (AppRouter.router.canPop()) {
      AppRouter.router.pop();
    }
  }
}
