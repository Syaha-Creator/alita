import 'dart:async';
import 'dart:math';

import '../utils/log.dart';

/// Retries [action] up to [maxAttempts] times with exponential backoff.
///
/// The first attempt executes immediately. On failure, waits
/// `baseDelay * 2^(attempt - 1)` (capped at [maxDelay]) before retrying.
///
/// Only retries if [retryIf] returns true for the thrown error (defaults to
/// retrying all errors).
///
/// Throws the last error if all attempts are exhausted.
Future<T> retry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(milliseconds: 500),
  Duration maxDelay = const Duration(seconds: 8),
  bool Function(Object error)? retryIf,
  String? tag,
}) async {
  assert(maxAttempts >= 1);

  Object? lastError;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;

      if (attempt == maxAttempts) break;

      if (retryIf != null && !retryIf(e)) break;

      final delayMs = min(
        baseDelay.inMilliseconds * pow(2, attempt - 1).toInt(),
        maxDelay.inMilliseconds,
      );
      final jitter = Random().nextInt((delayMs * 0.2).ceil() + 1);

      Log.warning(
        'Attempt $attempt/$maxAttempts failed, retrying in ${delayMs + jitter}ms',
        tag: tag ?? 'retry',
      );

      await Future<void>.delayed(Duration(milliseconds: delayMs + jitter));
    }
  }

  throw lastError ?? StateError('retry: no attempts executed');
}
