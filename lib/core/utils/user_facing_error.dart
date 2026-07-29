import 'network_error.dart';

/// Converts a caught error into a short, user-friendly Indonesian message —
/// never the raw `e.toString()` (which can leak stack internals, package
/// names, or technical jargon like `Instance of 'NotInitializedError'`).
///
/// Use this everywhere an error is shown via `AppFeedback.show(message: ...)`
/// instead of `'$e'` / `e.toString()`.
String userFacingErrorMessage(
  Object error, {
  String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
}) {
  if (isNetworkError(error)) {
    return 'Periksa koneksi internet Anda, lalu coba lagi.';
  }

  // Exception yang sengaja dilempar dengan pesan ramah (mis. AuthService,
  // validasi form) — aman ditampilkan setelah prefix `Exception: ` dibuang.
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    final cleaned = raw.replaceFirst('Exception: ', '').trim();
    if (cleaned.isNotEmpty && !cleaned.contains("Instance of '")) {
      return cleaned;
    }
  }
  if (error is String && error.trim().isNotEmpty) {
    return error;
  }

  return fallback;
}
