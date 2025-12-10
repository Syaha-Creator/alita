import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

/// Service untuk logging error ke Firebase Crashlytics dan Analytics
/// Memungkinkan monitoring error di Firebase Console
class FirebaseErrorService {
  static final FirebaseErrorService _instance =
      FirebaseErrorService._internal();
  factory FirebaseErrorService() => _instance;
  FirebaseErrorService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Reduced for performance
      errorMethodCount: 3, // Reduced for performance
      lineLength: 80, // Reduced for performance
      colors: true,
      printEmojis: false, // Disabled for performance
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  bool _isInitialized = false;

  /// Initialize Firebase Error Service
  /// Harus dipanggil setelah Firebase.initializeApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup Crashlytics untuk production
      if (kReleaseMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
      } else {
        // Di debug mode, tetap log ke console
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          _logger.e('Flutter Error',
              error: details.exception, stackTrace: details.stack);
        };
      }

      // Setup uncaught errors
      PlatformDispatcher.instance.onError = (error, stack) {
        if (kReleaseMode) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } else {
          _logger.e('Uncaught Error', error: error, stackTrace: stack);
        }
        return true;
      };

      _isInitialized = true;
      if (kDebugMode) {
        _logger.i('FirebaseErrorService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Error initializing FirebaseErrorService: $e');
      }
    }
  }

  /// Log error ke Firebase Crashlytics dan Analytics
  ///
  /// [error] - Error object atau exception
  /// [stackTrace] - Stack trace (optional)
  /// [fatal] - Apakah error ini fatal (default: false)
  /// [reason] - Alasan error (optional)
  /// [context] - Context tambahan untuk error (optional)
  Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    bool fatal = false,
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Log ke console untuk debug (non-blocking)
      if (kDebugMode) {
        _logger.e(
          reason ?? 'Error occurred',
          error: error,
          stackTrace: stackTrace,
        );
        if (context != null) {
          _logger.d('Error context: $context');
        }
      }

      // Log ke Firebase Crashlytics (production) - non-blocking
      if (kReleaseMode) {
        // Use unawaited to prevent blocking
        FirebaseCrashlytics.instance
            .recordError(
          error,
          stackTrace,
          fatal: fatal,
          reason: reason,
        )
            .catchError((e) {
          // Silent fail - don't block app
        });

        // Add custom keys untuk context (limit to 5 keys for performance)
        if (context != null && context.length <= 5) {
          context.forEach((key, value) {
            try {
              FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
            } catch (e) {
              // Silent fail
            }
          });
        }
      }

      // Log ke Firebase Analytics hanya untuk error fatal atau penting
      // Skip Analytics untuk error non-fatal untuk mengurangi overhead
      if (fatal) {
        try {
          await FirebaseAnalytics.instance.logEvent(
            name: 'fatal_error_occurred',
            parameters: {
              'error_type': error.runtimeType.toString(),
              'fatal': true,
              if (reason != null) 'reason': reason,
            },
          );
        } catch (e) {
          // Don't fail if analytics fails
          if (kDebugMode) {
            _logger.w('Failed to log error to Analytics: $e');
          }
        }
      }
    } catch (e) {
      // Don't fail if error logging fails
      if (kDebugMode) {
        _logger.e('Failed to log error to Firebase: $e');
      }
    }
  }

  /// Log non-fatal error (warning)
  Future<void> logWarning(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    await logError(
      message,
      fatal: false,
      reason: 'Warning',
      context: context,
    );
  }

  /// Log FCM-specific errors (non-blocking)
  void logFcmError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    // Fire and forget - don't block
    logError(
      error,
      stackTrace: stackTrace,
      fatal: false,
      reason: 'FCM Error: $operation',
      context: {
        'operation': operation,
        'service': 'FCM',
        if (context != null) ...context,
      },
    ).catchError((_) {
      // Silent fail
    });
  }

  /// Log API errors (non-blocking, skip for common 4xx errors)
  void logApiError(
    String endpoint,
    dynamic error, {
    int? statusCode,
    Map<String, dynamic>? context,
  }) {
    // Skip logging common client errors (4xx) to reduce overhead
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      // Only log in debug mode
      if (kDebugMode) {
        _logger.w('API Error ($statusCode): $endpoint');
      }
      return;
    }

    // Fire and forget - don't block
    logError(
      error,
      fatal: false,
      reason: 'API Error: $endpoint',
      context: {
        'endpoint': endpoint,
        'service': 'API',
        if (statusCode != null) 'status_code': statusCode,
        if (context != null) ...context,
      },
    ).catchError((_) {
      // Silent fail
    });
  }

  /// Log notification errors (non-blocking)
  void logNotificationError(
    String operation,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    // Fire and forget - don't block
    logError(
      error,
      stackTrace: stackTrace,
      fatal: false,
      reason: 'Notification Error: $operation',
      context: {
        'operation': operation,
        'service': 'Notification',
        if (context != null) ...context,
      },
    ).catchError((_) {
      // Silent fail
    });
  }

  /// Set user identifier untuk tracking
  Future<void> setUserId(String userId) async {
    try {
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
      await FirebaseAnalytics.instance.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        _logger.w('Failed to set user ID: $e');
      }
    }
  }

  /// Set custom key untuk tracking
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
      }
    } catch (e) {
      if (kDebugMode) {
        _logger.w('Failed to set custom key: $e');
      }
    }
  }

  /// Log custom event ke Analytics
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Convert Map<String, dynamic> to Map<String, Object>
      Map<String, Object>? analyticsParams;
      if (parameters != null) {
        analyticsParams = parameters.map(
          (key, value) => MapEntry(key, value as Object),
        );
      }

      await FirebaseAnalytics.instance.logEvent(
        name: eventName,
        parameters: analyticsParams,
      );
    } catch (e) {
      if (kDebugMode) {
        _logger.w('Failed to log event to Analytics: $e');
      }
    }
  }
}
