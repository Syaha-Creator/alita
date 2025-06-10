import 'package:flutter/material.dart';
import 'app_router.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Menggunakan push akan menumpuk halaman baru (ada tombol kembali)
  static void push(String routeName) {
    AppRouter.router.push(routeName);
  }

  // Menggunakan go akan "melompat" ke halaman, bisa jadi mengganti stack
  static void go(String routeName) {
    AppRouter.router.go(routeName);
  }

  static void goBack() {
    if (AppRouter.router.canPop()) {
      AppRouter.router.pop();
    }
  }

  // navigateAndReplace sudah benar
  static void navigateAndReplace(String routeName) {
    AppRouter.router.replace(routeName);
  }
}
