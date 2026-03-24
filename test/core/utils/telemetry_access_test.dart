import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/telemetry_access.dart';

void main() {
  group('TelemetryAccess.canAccess', () {
    test('returns true for admin userId 5206', () {
      expect(TelemetryAccess.canAccess(5206), isTrue);
    });

    test('returns false for non-admin userId', () {
      expect(TelemetryAccess.canAccess(1234), isFalse);
    });

    test('returns false for userId 0', () {
      expect(TelemetryAccess.canAccess(0), isFalse);
    });

    test('returns false for null userId', () {
      expect(TelemetryAccess.canAccess(null), isFalse);
    });
  });
}
