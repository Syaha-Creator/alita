import 'dart:io';

import 'package:in_app_update/in_app_update.dart';

import '../utils/log.dart';

/// Handles mandatory app updates using the native Google Play in-app update
/// API on Android. iOS tidak memakai in-app update di sini.
///
/// [performImmediateUpdate] shows a full-screen Google Play UI that blocks
/// the app until the user installs the update. This is the most reliable
/// force-update mechanism on Android because the UI is owned by the OS.
class ForceUpdateService {
  ForceUpdateService._();

  static bool _checking = false;

  /// Check for an available update and trigger the native immediate update
  /// flow if one exists. Safe to call repeatedly — concurrent calls are
  /// deduplicated and all errors are caught gracefully.
  static Future<void> checkAndForceUpdate() async {
    if (!Platform.isAndroid) return;
    if (_checking) return;
    _checking = true;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable &&
          info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      // Expected failures: not installed from Play Store, emulator, API error.
      Log.warning('In-app update check failed: $e', tag: 'ForceUpdate');
    } finally {
      _checking = false;
    }
  }
}
