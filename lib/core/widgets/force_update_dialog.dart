import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../theme/app_colors.dart';

/// Dialog untuk menampilkan force update
class ForceUpdateDialog extends StatelessWidget {
  final String? message;
  final bool isForceUpdate;

  const ForceUpdateDialog({
    super.key,
    this.message,
    this.isForceUpdate = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForceUpdate, // Prevent back button if force update
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppColors.warning), // Status color
            const SizedBox(width: 8),
            const Text('Update Diperlukan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message ??
                  'Versi aplikasi Anda sudah tidak didukung. Silakan update aplikasi ke versi terbaru untuk melanjutkan.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return Text(
                    'Versi saat ini: ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          if (!isForceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Nanti'),
            ),
          ElevatedButton(
            onPressed: () => _openStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary, // 10% - Accent
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _openStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      String storeUrl;
      if (Platform.isAndroid) {
        storeUrl = 'https://play.google.com/store/apps/details?id=$packageName';
      } else if (Platform.isIOS) {
        // App Store URL dengan ID yang sudah diisi
        storeUrl =
            'https://apps.apple.com/us/app/alita-pricelist-v2/id6740308588';
      } else {
        return;
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening store: $e');
    }
  }
}
