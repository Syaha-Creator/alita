import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/log.dart';

/// iOS-only update checker menggunakan version manifest di Firebase Hosting.
///
/// **Kenapa tidak pakai `upgrader` atau iTunes Lookup API?**
/// - Aplikasi ini tidak tersedia di pencarian publik App Store (hanya via link
///   langsung / enterprise), sehingga iTunes API tidak reliable untuk lookup.
/// - `upgrader` menyimpan cache versi di SharedPreferences dan tidak selalu
///   mereset saat app diperbarui → dialog masih muncul setelah user sudah update.
///
/// **Cara kerja:**
/// 1. Fetch `version.json` dari Firebase Hosting (bukan iTunes API).
/// 2. Ambil versi terinstall via [PackageInfo.fromPlatform] — selalu fresh.
/// 3. Bandingkan `minimum_version` dari JSON vs versi terinstall secara numerik.
/// 4. Debounce 4 jam via SharedPreferences agar tidak spam request.
/// 5. Tampilkan [CupertinoAlertDialog] — buka `update_url` dari JSON.
///
/// **Cara update versi minimum:**
/// Edit `hosting/version.json`, naikkan `minimum_version`, lalu:
/// ```
/// firebase deploy --only hosting
/// ```
class IosUpdateChecker {
  IosUpdateChecker._();

  static const _manifestUrl =
      'https://alita-pricelist-12d76.web.app/version.json';

  static const _prefLastCheckKey = 'ios_upd_last_check_ms';
  static const _checkInterval = Duration(hours: 4);

  static bool _isShowing = false;

  /// Periksa update dari Firebase Hosting dan tampilkan dialog jika ada versi baru.
  ///
  /// Aman dipanggil berkali-kali — request di-debounce 4 jam dan concurrent
  /// call diabaikan. Tidak melempar exception keluar.
  static Future<void> checkAndShowIfNeeded(BuildContext context) async {
    if (!Platform.isIOS) return;
    if (_isShowing) return;
    if (!context.mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lastCheckMs = prefs.getInt(_prefLastCheckKey) ?? 0;

      if ((nowMs - lastCheckMs) < _checkInterval.inMilliseconds) return;

      final manifest = await _fetchManifest();
      if (manifest == null) return;

      await prefs.setInt(_prefLastCheckKey, nowMs);

      final iosSection = manifest['ios'] as Map<String, dynamic>?;
      if (iosSection == null) return;

      final minimumVersion = iosSection['minimum_version'] as String?;
      final updateUrl = iosSection['update_url'] as String?;
      if (minimumVersion == null || updateUrl == null) return;

      // Ambil versi terinstall selalu fresh — ini yang menghilangkan bug
      // "dialog muncul lagi setelah update": PackageInfo membaca dari binary.
      final packageInfo = await PackageInfo.fromPlatform();
      final installedVersion = packageInfo.version;

      if (!_isManifestNewer(minimumVersion, installedVersion)) return;

      final releaseNotes = iosSection['release_notes'] as String?;

      if (!context.mounted) return;
      _isShowing = true;
      await _showUpdateDialog(
        context: context,
        installedVersion: installedVersion,
        minimumVersion: minimumVersion,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
      );
    } catch (e, st) {
      Log.error(e, st, reason: 'IosUpdateChecker');
    } finally {
      _isShowing = false;
    }
  }

  // ── Private helpers ────────────────────────────────────────────

  /// Fetch dan parse `version.json` dari Firebase Hosting.
  /// Header `no-cache` dipasang di firebase.json sehingga selalu dapat versi terbaru.
  static Future<Map<String, dynamic>?> _fetchManifest() async {
    try {
      final response = await http.get(
        Uri.parse(_manifestUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        Log.warning(
          'IosUpdateChecker: manifest HTTP ${response.statusCode}',
          tag: 'IosUpdate',
        );
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return null;
      return data;
    } catch (e) {
      Log.warning('IosUpdateChecker: fetch manifest gagal: $e',
          tag: 'IosUpdate');
      return null;
    }
  }

  static Future<void> _showUpdateDialog({
    required BuildContext context,
    required String installedVersion,
    required String minimumVersion,
    required String updateUrl,
    String? releaseNotes,
  }) async {
    if (!context.mounted) return;

    final notes = (releaseNotes != null && releaseNotes.isNotEmpty)
        ? '\n\n$releaseNotes'
        : '';

    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Pembaruan Tersedia'),
        content: Text(
          'Versi baru aplikasi Alita Pricelist telah tersedia.$notes\n\n'
          'Terpasang: $installedVersion\n'
          'Diperlukan: $minimumVersion',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await _openUpdateUrl(updateUrl);
            },
            child: const Text('Perbarui Sekarang'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openUpdateUrl(String url) async {
    final uris = <Uri>[
      // Coba scheme itms-apps:// agar langsung buka App Store app
      Uri.parse(url.replaceFirst('https://apps.apple.com', 'itms-apps://itunes.apple.com')),
      // Fallback ke URL https asli (Safari → redirect ke App Store)
      Uri.parse(url),
    ];

    for (final uri in uris) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {
        continue;
      }
    }
    Log.warning('IosUpdateChecker: tidak bisa buka URL: $url',
        tag: 'IosUpdate');
  }

  /// Returns `true` jika [manifestVer] lebih baru dari [installedVer].
  /// Perbandingan numerik per segment: "1.7.10" > "1.7.9" ✓
  static bool _isManifestNewer(String manifestVer, String installedVer) {
    final manifest = _parseVersion(manifestVer);
    final installed = _parseVersion(installedVer);
    final len =
        manifest.length > installed.length ? manifest.length : installed.length;
    for (var i = 0; i < len; i++) {
      final m = i < manifest.length ? manifest[i] : 0;
      final c = i < installed.length ? installed[i] : 0;
      if (m > c) return true;
      if (m < c) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    return version
        .split('.')
        .map((seg) =>
            int.tryParse(seg.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
  }
}
