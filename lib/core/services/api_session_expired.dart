/// API mengembalikan 401/403 padahal user dianggap sudah login
/// (token kedaluwarsa, dicabut server, atau kredensial client tidak cocok).
class ApiSessionExpiredException implements Exception {
  const ApiSessionExpiredException([this.detail]);

  /// Opsional untuk log internal (jangan tampilkan mentah ke user).
  final String? detail;

  @override
  String toString() =>
      'Sesi login telah berakhir. Silakan login kembali untuk melanjutkan.';
}
