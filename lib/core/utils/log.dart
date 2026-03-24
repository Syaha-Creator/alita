import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralised logging helper that routes errors to Firebase Crashlytics
/// in release builds and prints to console in debug builds.
///
/// Usage:
/// ```dart
/// try {
///   await riskyOperation();
/// } catch (e, st) {
///   Log.error(e, st, reason: 'riskyOperation failed');
/// }
/// ```
class Log {
  Log._();

  static bool _crashlyticsReady = false;

  /// Call once after Firebase.initializeApp() succeeds.
  static void enableCrashlytics() => _crashlyticsReady = true;

  /// Non-fatal error — recorded in Crashlytics dashboard under "Non-Fatals".
  static void error(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
  }) {
    final tag = reason ?? 'untagged';
    debugPrint('[Log.error] ($tag) $exception');
    if (!kDebugMode && _crashlyticsReady) {
      FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        reason: tag,
      );
    }
  }

  /// Warning-level log — breadcrumb only, no error entry.
  /// Useful for expected failures (e.g., optional notification that failed).
  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    debugPrint('[Log.warning] $prefix$message');
    if (!kDebugMode && _crashlyticsReady) {
      FirebaseCrashlytics.instance.log('$prefix$message');
    }
  }

  /// Attach contextual key-value pairs that appear on the next crash report.
  /// Example: `Log.setContext('current_screen', 'ApprovalDetail');`
  static void setContext(String key, String value) {
    if (!_crashlyticsReady) return;
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Identify the current user in crash reports.
  static void setUser(String userId) {
    if (!_crashlyticsReady) return;
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
}
