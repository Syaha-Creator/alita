/// Client-side approver role check based on `work_title` (e.g. SPV, Manager).
///
/// Backend tidak mengembalikan field role/is_admin — ini heuristik dari
/// jabatan, sama seperti yang sudah dipakai [ProfilePage]. In-memory cache
/// di sini memungkinkan router redirect membaca role secara sinkron tanpa
/// menunggu [profileProvider] (async).
abstract final class ApproverAccess {
  static String _cachedWorkTitle = '';

  static const _approverKeywords = [
    'manager',
    'supervisor',
    'spv',
    'rsm',
    'analyst',
    'head',
    'director',
    'gm',
    'chief',
    'kepala',
  ];

  /// Dipanggil setiap kali work title terbaru diketahui (boot dari cache
  /// disk, atau setelah [profileProvider] fetch sukses).
  static void updateCache(String workTitle) {
    if (workTitle.isNotEmpty) _cachedWorkTitle = workTitle;
  }

  /// Reset saat logout — cache work title tidak boleh terbawa ke user
  /// berikutnya yang login di perangkat sama.
  static void reset() => _cachedWorkTitle = '';

  static bool isApproverTitle(String? workTitle) {
    final t = (workTitle ?? '').trim().toLowerCase();
    if (t.isEmpty) return false;
    return _approverKeywords.any(t.contains);
  }

  /// `true` kalau kita sudah pernah tahu work title user ini (dari sesi
  /// sebelumnya atau fetch profil di sesi ini).
  static bool get hasCachedTitle => _cachedWorkTitle.isNotEmpty;

  /// Role approver berdasarkan cache in-memory saat ini.
  static bool get isApproverCached => isApproverTitle(_cachedWorkTitle);
}
