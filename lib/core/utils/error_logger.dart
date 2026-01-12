import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../services/firebase_error_service.dart';

/// Centralized error logging utility
/// 
/// Semua error harus di-log melalui ErrorLogger ini untuk:
/// - Consistent logging format
/// - Easy debugging
/// - Firebase error tracking
class ErrorLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      noBoxingByDefault: false,
    ),
  );

  static final FirebaseErrorService _firebaseErrorService =
      FirebaseErrorService();

  /// Log error dengan context
  /// 
  /// [error] - Error object atau exception
  /// [stackTrace] - Stack trace (optional, tapi sangat disarankan)
  /// [context] - Context string untuk menjelaskan dimana error terjadi
  /// [extra] - Extra context data (Map)
  /// [fatal] - Apakah error ini fatal (default: false)
  /// 
  /// Contoh:
  /// ```dart
  /// try {
  ///   await someOperation();
  /// } catch (e, stackTrace) {
  ///   await ErrorLogger.logError(
  ///     e,
  ///     stackTrace: stackTrace,
  ///     context: 'Failed to perform someOperation',
  ///     extra: {'operation': 'someOperation', 'userId': userId},
  ///   );
  ///   rethrow;
  /// }
  /// ```
  static Future<void> logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extra,
    bool fatal = false,
  }) async {
    // Log ke console (debug mode)
    if (kDebugMode) {
      _logger.e(
        context ?? 'Error occurred',
        error: error,
        stackTrace: stackTrace,
      );
      if (extra != null && extra.isNotEmpty) {
        _logger.d('Extra context: $extra');
      }
    }

    // Log ke Firebase (production)
    try {
      await _firebaseErrorService.logError(
        error,
        stackTrace: stackTrace,
        fatal: fatal,
        reason: context,
        context: extra,
      );
    } catch (e) {
      // Don't fail if Firebase logging fails
      if (kDebugMode) {
        _logger.w('Failed to log error to Firebase: $e');
      }
    }
  }

  /// Log warning (non-fatal error)
  /// 
  /// Contoh:
  /// ```dart
  /// ErrorLogger.logWarning(
  ///   'API returned empty data',
  ///   extra: {'endpoint': '/api/products'},
  /// );
  /// ```
  static void logWarning(
    String message, {
    Map<String, dynamic>? extra,
  }) {
    if (kDebugMode) {
      _logger.w(message, error: extra);
    }
  }

  /// Log info (informational message)
  /// 
  /// Contoh:
  /// ```dart
  /// ErrorLogger.logInfo(
  ///   'User logged in successfully',
  ///   extra: {'userId': userId},
  /// );
  /// ```
  static void logInfo(
    String message, {
    Map<String, dynamic>? extra,
  }) {
    if (kDebugMode) {
      _logger.i(message, error: extra);
    }
  }

  /// Log debug (debugging message)
  /// 
  /// Contoh:
  /// ```dart
  /// ErrorLogger.logDebug(
  ///   'Fetching products',
  ///   extra: {'area': area, 'channel': channel},
  /// );
  /// ```
  static void logDebug(
    String message, {
    Map<String, dynamic>? extra,
  }) {
    if (kDebugMode) {
      _logger.d(message, error: extra);
    }
  }

  /// Log API error dengan context
  /// 
  /// Contoh:
  /// ```dart
  /// try {
  ///   await apiClient.get('/products');
  /// } on DioException catch (e, stackTrace) {
  ///   await ErrorLogger.logApiError(
  ///     e,
  ///     stackTrace: stackTrace,
  ///     endpoint: '/products',
  ///     method: 'GET',
  ///     statusCode: e.response?.statusCode,
  ///   );
  /// }
  /// ```
  static Future<void> logApiError(
    dynamic error, {
    StackTrace? stackTrace,
    required String endpoint,
    String? method,
    int? statusCode,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) async {
    final extra = <String, dynamic>{
      'endpoint': endpoint,
      if (method != null) 'method': method,
      if (statusCode != null) 'statusCode': statusCode,
      if (requestData != null) 'requestData': requestData,
      if (responseData != null) 'responseData': responseData,
    };

    await logError(
      error,
      stackTrace: stackTrace,
      context: 'API Error: $method $endpoint',
      extra: extra,
      fatal: statusCode != null && statusCode >= 500,
    );
  }

  /// Log database/cache error
  /// 
  /// Contoh:
  /// ```dart
  /// try {
  ///   await saveToCache(data);
  /// } catch (e, stackTrace) {
  ///   await ErrorLogger.logCacheError(
  ///     e,
  ///     stackTrace: stackTrace,
  ///     operation: 'saveToCache',
  ///     key: 'products_cache',
  ///   );
  /// }
  /// ```
  static Future<void> logCacheError(
    dynamic error, {
    StackTrace? stackTrace,
    required String operation,
    String? key,
    Map<String, dynamic>? extra,
  }) async {
    final context = <String, dynamic>{
      'operation': operation,
      if (key != null) 'key': key,
      if (extra != null) ...extra,
    };

    await logError(
      error,
      stackTrace: stackTrace,
      context: 'Cache Error: $operation',
      extra: context,
      fatal: false,
    );
  }
}

