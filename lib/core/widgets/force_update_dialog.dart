import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

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
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.orange),
            SizedBox(width: 8),
            Text('Update Diperlukan'),
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
                  return Text(
                    'Versi saat ini: ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
              backgroundColor: Colors.blue,
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
