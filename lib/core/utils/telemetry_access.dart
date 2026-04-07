/// Admin allowlist for telemetry/debug UI access.
///
/// Background telemetry remains active for all users; this gate only controls
/// visibility/access of the debug UI page.
///
/// Callers pass [userId] from auth state; core does not depend on auth feature.
abstract final class TelemetryAccess {
  static const Set<int> _adminUserIds = {5206};

  static bool canAccess(int? userId) =>
      userId != null && userId > 0 && _adminUserIds.contains(userId);

  /// User may open the Direct / Indirect pricelist picker manually.
  /// Same allowlist as [canAccess]; add IDs to [_adminUserIds] as needed.
  static bool canChooseSalesMode(int? userId) => canAccess(userId);
}
