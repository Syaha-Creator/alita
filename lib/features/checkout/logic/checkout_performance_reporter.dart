import '../../../core/utils/app_telemetry.dart';

/// Reports checkout list performance for long-item lists.
///
/// Throttles reports to avoid spam; only fires when item count >= 12.
class CheckoutPerformanceReporter {
  CheckoutPerformanceReporter._();

  static DateTime? _lastReportAt;

  static void reportIfNeeded({
    required int itemCount,
    required int bonusRows,
    required int paymentCount,
    required int frameBuildMs,
  }) {
    if (itemCount < 12) return;
    final now = DateTime.now();
    final last = _lastReportAt;
    if (last != null && now.difference(last).inSeconds < 6) return;
    _lastReportAt = now;
    AppTelemetry.event(
      'checkout_long_list_frame',
      data: {
        'items': itemCount,
        'bonus_rows': bonusRows,
        'payments': paymentCount,
        'build_ms': frameBuildMs,
      },
      tag: 'CheckoutPerf',
    );
  }
}
