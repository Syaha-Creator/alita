import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'log.dart';

/// Structured telemetry helper with basic PII-safe sanitization.
///
/// This helper is intentionally lightweight and routes through [Log.warning]
/// so it remains non-fatal and safe in production.
class AppTelemetry {
  AppTelemetry._();

  static const _piiKeys = <String>{
    'name',
    'full_name',
    'customer_name',
    'email',
    'phone',
    'address',
    'note',
    'message',
    'password',
    'token',
    'payload',
  };

  static Map<String, dynamic> _sanitize(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const {};
    final out = <String, dynamic>{};
    data.forEach((key, value) {
      final k = key.toLowerCase();
      if (_piiKeys.contains(k) ||
          k.contains('email') ||
          k.contains('phone') ||
          k.contains('address') ||
          k.contains('token') ||
          k.contains('password')) {
        out[key] = '[redacted]';
      } else if (value is Map<String, dynamic>) {
        out[key] = _sanitize(value);
      } else if (value is Iterable) {
        out[key] = value.length;
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  static void event(
    String name, {
    Map<String, dynamic>? data,
    String tag = 'Telemetry',
  }) {
    final safe = _sanitize(data);
    final payload = safe.isEmpty ? '' : ' ${jsonEncode(safe)}';
    Log.warning('event:$name$payload', tag: tag);
  }

  static void error(
    String name, {
    Map<String, dynamic>? data,
    String tag = 'Telemetry',
  }) {
    final safe = _sanitize(data);
    final payload = safe.isEmpty ? '' : ' ${jsonEncode(safe)}';
    Log.warning('error:$name$payload', tag: tag);
  }

  /// Optional Crashlytics context (release only through [Log.setContext]).
  static void context(String key, String value) {
    if (!kDebugMode) {
      Log.setContext(key, value);
    }
  }
}
