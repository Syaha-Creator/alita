import 'package:go_router/go_router.dart';

import 'route_path.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: RoutePaths.login,
        // builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.product,
        // builder: (context, state) => const ProductPage(),
      ),
      GoRoute(
        path: RoutePaths.cart,
        // builder: (context, state) => const CartPage(),
        // pageBuilder: (context, state) => CustomTransitionPage(
        //   key: state.pageKey,
        //   child: const CartPage(),
        //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
        //     return FadeTransition(opacity: animation, child: child);
        //   },
        // ),
      ),
    ],
  );
}
