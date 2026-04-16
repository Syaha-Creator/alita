/// Gate opsional untuk PDF **Surat Pesanan (Internal)**: melewati pengecekan
/// “semua approval diskon di timeline harus disetujui”.
///
/// **Sekarang (uji coba):** aktifkan bypass dengan mengisi [_bypassUserIds]
/// (tambahkan `userId` sesuai kebutuhan QA).
///
/// **Kedepannya:** set [_approvalBypassEnabled] ke `false` agar **tidak ada**
/// pengecualian — semua pengguna wajib approval lengkap sebelum PDF internal
/// (set [_bypassUserIds] boleh dibiarkan; tidak dipakai saat flag mati).
abstract final class InternalPdfAccess {
  /// `false` = matikan pengecualian untuk semua user (produksi ketat).
  static const bool _approvalBypassEnabled = true;

  /// User ID yang boleh bypass cek timeline diskon untuk PDF internal.
  static const Set<int> _bypassUserIds = {
    5206,
  };

  /// `true` jika [userId] diizinkan membuka alur PDF internal tanpa syarat
  /// approval diskon penuh (hanya jika [_approvalBypassEnabled]).
  static bool bypassesItemDiscountApprovalGate(int? userId) =>
      _approvalBypassEnabled &&
      userId != null &&
      userId > 0 &&
      _bypassUserIds.contains(userId);
}
