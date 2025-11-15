import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  AppUpdateInfo? _updateInfo;

  // Hardcoded minimum version untuk force update (iOS)
  // Update nilai ini setiap kali release versi baru yang wajib di-update
  // Versi saat ini: 1.7.4+32
  // Versi minimum yang wajib di-update: 1.7.4+32
  // Jika user menggunakan versi < 1.7.4+32, akan di-force update
  static const String _minRequiredVersion = '1.7.4';
  static const int _minRequiredBuildNumber = 32;

  /// Check if app update is required
  /// Returns true if update is required (force update)
  /// Returns false if no update needed
  Future<bool> checkForUpdate() async {
    try {
      // Untuk Android, cek langsung dari Play Store menggunakan in_app_update
      if (Platform.isAndroid) {
        return await _checkAndroidUpdate();
      }

      // Untuk iOS, gunakan hardcoded version check
      if (Platform.isIOS) {
        return await _checkIOSVersion();
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
      return false;
    }
  }

  /// Check Android update menggunakan in_app_update (langsung dari Play Store)
  /// Sama seperti implementasi di kode lama
  Future<bool> _checkAndroidUpdate() async {
    try {
      _updateInfo = await InAppUpdate.checkForUpdate();

      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (kDebugMode) {
          print('Update available from Play Store');
        }
        // Jika ada update tersedia, langsung perform immediate update
        await performImmediateUpdate();
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking Android update: $e');
      }
      return false;
    }
  }

  /// Check iOS version menggunakan hardcoded version
  Future<bool> _checkIOSVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      if (kDebugMode) {
        print('Current iOS version: $currentVersion ($currentBuildNumber)');
        print(
            'Min required version: $_minRequiredVersion ($_minRequiredBuildNumber)');
      }

      // Cek apakah current version lebih kecil dari minimum required
      if (currentBuildNumber < _minRequiredBuildNumber) {
        if (kDebugMode) {
          print(
              'Force update required! Current: $currentVersion ($currentBuildNumber), Required: $_minRequiredVersion ($_minRequiredBuildNumber)');
        }
        return true;
      }

      // Bandingkan version string juga
      final needsUpdate = _compareVersions(
        currentVersion,
        currentBuildNumber,
        _minRequiredVersion,
        _minRequiredBuildNumber,
      );

      if (needsUpdate) {
        if (kDebugMode) {
          print('Force update required based on version comparison!');
        }
        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking iOS version: $e');
      }
      return false;
    }
  }

  /// Perform an immediate update (Android)
  /// Sama seperti implementasi di kode lama
  Future<void> performImmediateUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      try {
        if (kDebugMode) {
          print('Performing immediate update...');
        }
        await InAppUpdate.performImmediateUpdate();
        // No need to call completeUpdate() for immediate updates, as the app restarts automatically.
      } catch (e) {
        if (kDebugMode) {
          print('Update failed: $e');
        }
        // Fallback to Play Store if immediate update fails
        await _openPlayStore();
      }
    } else {
      // If no update info, open Play Store
      await _openPlayStore();
    }
  }

  /// Perform a flexible update (Android - optional)
  Future<void> performFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate(); // Ensures proper cleanup
    } catch (e) {
      if (kDebugMode) {
        print('Flexible update failed: $e');
      }
      // Fallback to Play Store
      await _openPlayStore();
    }
  }

  /// Compare two versions
  /// Returns true if current version is older than required version
  bool _compareVersions(
    String currentVersion,
    int currentBuildNumber,
    String requiredVersion,
    int requiredBuildNumber,
  ) {
    // First compare build numbers (more reliable)
    if (currentBuildNumber < requiredBuildNumber) {
      return true;
    }

    // If build numbers are equal, compare version strings
    if (currentBuildNumber == requiredBuildNumber) {
      final currentParts = currentVersion.split('.').map(int.tryParse).toList();
      final requiredParts =
          requiredVersion.split('.').map(int.tryParse).toList();

      for (int i = 0;
          i < currentParts.length && i < requiredParts.length;
          i++) {
        final current = currentParts[i] ?? 0;
        final required = requiredParts[i] ?? 0;

        if (current < required) {
          return true;
        } else if (current > required) {
          return false;
        }
      }

      // If all parts are equal, check if required has more parts
      if (requiredParts.length > currentParts.length) {
        return true;
      }
    }

    return false;
  }

  /// Handle app update based on platform
  Future<void> handleUpdate({bool forceUpdate = true}) async {
    if (Platform.isAndroid) {
      // Android akan langsung perform immediate update dari checkForUpdate
      // Jika sampai sini berarti perlu fallback ke Play Store
      await _openPlayStore();
    } else if (Platform.isIOS) {
      await _handleIOSUpdate();
    }
  }

  /// Handle iOS update by opening App Store
  Future<void> _handleIOSUpdate() async {
    try {
      // App Store URL dengan ID yang sudah diisi
      final appStoreUrl =
          'https://apps.apple.com/us/app/alita-pricelist-v2/id6740308588';

      final uri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (kDebugMode) {
          print('Could not launch App Store URL');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening App Store: $e');
      }
    }
  }

  /// Open Play Store for Android
  Future<void> _openPlayStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      // Play Store URL format
      final playStoreUrl =
          'https://play.google.com/store/apps/details?id=$packageName';

      final uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (kDebugMode) {
          print('Could not launch Play Store URL');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening Play Store: $e');
      }
    }
  }

  /// Get current app version info
  Future<Map<String, String>> getCurrentVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
      'appName': packageInfo.appName,
    };
  }
}
