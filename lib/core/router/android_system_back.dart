/// Keputusan tombol/gesture back sistem Android untuk [GoRouter] + [ShellRoute].
///
/// Diekstrak agar bisa diuji tanpa widget tree — mencegah regresi "back menutup
/// app" padahal masih ada layar sebelumnya / user belum konfirmasi keluar.
enum AndroidSystemBackDecision {
  /// Ada entri di stack GoRouter → [GoRouter.pop].
  popRouter,

  /// Admin di home tanpa stack → kembali ke hub pilih mode.
  goSalesHub,

  /// Halaman non-root tanpa stack (deep link / go) → ke home katalog.
  goHome,

  /// Root (`/` non-admin atau `/sales_hub`) → minta tekan lagi untuk keluar.
  confirmExit,

  /// Keluar activity (setelah konfirmasi, atau dari login/boot).
  exitApp,
}

/// Path yang dianggap "akar" aplikasi (boleh exit, bukan push ke home).
const androidSystemBackRootPaths = {
  '/',
  '/sales_hub',
  '/login',
  '/auth_boot',
};

/// Resolusi back Android. [exitPromptActive] true jika user baru saja mendapat
/// toast "tekan lagi" dalam jendela waktu (mis. 2 detik).
AndroidSystemBackDecision resolveAndroidSystemBack({
  required bool routerCanPop,
  required String matchedLocation,
  required bool canChooseSalesMode,
  required bool exitPromptActive,
}) {
  if (routerCanPop) {
    return AndroidSystemBackDecision.popRouter;
  }

  // Admin di katalog tanpa history: jangan exit — kembalikan ke sales hub.
  if (matchedLocation == '/' && canChooseSalesMode) {
    return AndroidSystemBackDecision.goSalesHub;
  }

  if (matchedLocation == '/login' || matchedLocation == '/auth_boot') {
    return AndroidSystemBackDecision.exitApp;
  }

  if (matchedLocation == '/' || matchedLocation == '/sales_hub') {
    return exitPromptActive
        ? AndroidSystemBackDecision.exitApp
        : AndroidSystemBackDecision.confirmExit;
  }

  // Orphan non-root (stack kosong setelah go/deep link).
  return AndroidSystemBackDecision.goHome;
}
