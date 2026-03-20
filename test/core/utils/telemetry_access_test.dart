import 'package:flutter_test/flutter_test.dart';
import 'package:alitapricelist/core/utils/telemetry_access.dart';
import 'package:alitapricelist/features/auth/logic/auth_provider.dart';

void main() {
  group('TelemetryAccess.canAccess', () {
    test('returns true for admin userId 5206', () {
      const auth = AuthState(userId: 5206);
      expect(TelemetryAccess.canAccess(auth), isTrue);
    });

    test('returns false for non-admin userId', () {
      const auth = AuthState(userId: 1234);
      expect(TelemetryAccess.canAccess(auth), isFalse);
    });

    test('returns false for default userId 0', () {
      const auth = AuthState();
      expect(TelemetryAccess.canAccess(auth), isFalse);
    });
  });
}
