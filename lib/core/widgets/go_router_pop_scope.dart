import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mengalihkan tombol kembali sistem / gesture ke [GoRouter.pop], bukan hanya
/// [Navigator.maybePop]. Di Android (terutama release dengan [ShellRoute] +
/// widget yang memakai [navigatorKey] root), [BackButton] bawaan kadang
/// menarget navigator yang salah sehingga `maybePop` gagal dan activity selesai
/// — terasa seperti aplikasi "keluar" padahal user ingin kembali satu layar.
class GoRouterPopScope extends StatelessWidget {
  const GoRouterPopScope({
    super.key,
    required this.child,
    this.fallbackLocation,
  });

  final Widget child;

  /// Jika [GoRouter.canPop] false (mis. edge deep link), navigasi ke lokasi ini.
  final String? fallbackLocation;

  static void handlePop(BuildContext context, {String? fallbackLocation}) {
    if (!context.mounted) return;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else if (fallbackLocation != null && fallbackLocation.isNotEmpty) {
      router.go(fallbackLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        handlePop(context, fallbackLocation: fallbackLocation);
      },
      child: child,
    );
  }
}
