import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_constant.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/cart/presentation/pages/cart_page.dart';
import '../features/cart/presentation/pages/checkout_pages.dart';
import '../features/product/presentation/pages/product_page.dart';
import '../services/auth_service.dart';
import 'navigation_service.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    refreshListenable: AuthService.authChangeNotifier,
    initialLocation: AuthService.authChangeNotifier.value
        ? RoutePaths.product
        : RoutePaths.login,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.product,
        builder: (context, state) => const ProductPage(),
      ),
      GoRoute(
        path: RoutePaths.cart,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CartPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: RoutePaths.checkout,
        builder: (context, state) => const CheckoutPages(),
      )
    ],
    redirect: (context, state) {
      final isLoggedIn = AuthService.authChangeNotifier.value;
      final isLoggingIn = state.matchedLocation == RoutePaths.login;

      if (!isLoggedIn && !isLoggingIn) {
        return RoutePaths.login;
      }

      if (isLoggedIn && isLoggingIn) {
        return RoutePaths.product;
      }

      return null;
    },
  );
}
