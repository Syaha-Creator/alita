import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/platform_utils.dart';

/// Reusable body for About app dialog (iOS & Android).
class AboutDialogContent extends StatelessWidget {
  /// Tutup route dialog tanpa [Navigator.of] (!) — aman dengan nested / shell navigator.
  static void _popDialogRoute(BuildContext dialogContext) {
    final root = Navigator.maybeOf(dialogContext, rootNavigator: true);
    if (root != null && root.canPop()) {
      root.pop();
      return;
    }
    final nested = Navigator.maybeOf(dialogContext, rootNavigator: false);
    if (nested != null && nested.canPop()) {
      nested.pop();
    }
  }

  /// Shows the About dialog. Call from menu item or button.
  static Future<void> show(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionLabel = 'Alita Pricelist v${packageInfo.version}';

    if (!context.mounted) return;
    if (isIOS) {
      unawaited(showCupertinoDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Tentang Aplikasi'),
          content: AboutDialogContent(versionLabel: versionLabel),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => _popDialogRoute(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ));
      return;
    }

    unawaited(showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: AboutDialogContent(versionLabel: versionLabel),
        actions: [
          TextButton(
            onPressed: () => _popDialogRoute(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    ));
  }

  const AboutDialogContent({
    super.key,
    required this.versionLabel,
  });

  static const String description =
      'Aplikasi resmi manajemen katalog produk, kalkulasi harga, '
      'dan pembuatan pesanan untuk jaringan penjualan Massindo Group.';
  static const String copyright = '© 2026 Massindo Group. All rights reserved.';

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          versionLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          description,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        const Text(
          copyright,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
