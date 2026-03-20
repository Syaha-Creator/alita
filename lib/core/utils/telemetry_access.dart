import '../../features/auth/logic/auth_provider.dart';

/// Admin allowlist for telemetry/debug UI access.
///
/// Background telemetry remains active for all users; this gate only controls
/// visibility/access of the debug UI page.
abstract final class TelemetryAccess {
  static const Set<int> _adminUserIds = {5206};

  static bool canAccess(AuthState auth) => _adminUserIds.contains(auth.userId);
}
