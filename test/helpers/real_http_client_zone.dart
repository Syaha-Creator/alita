import 'dart:io';

/// [HttpClient] factory memanggil [HttpOverrides.current]; override ini
/// mendelegasikan ke implementasi bawaan dart:io (bukan factory publik
/// [HttpClient]) sehingga tidak rekursif.
class _RealNetworkHttpOverrides extends HttpOverrides {
  // Subclass wajib: factory [HttpClient] memanggil [HttpOverrides.current];
  // [super.createHttpClient] memakai implementasi socket dart:io.
  @override
  // ignore: unnecessary_overrides
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context);
}

/// [TestWidgetsFlutterBinding] mengganti [HttpClient] global dengan mock 400.
/// Zona ini memakai client jaringan sungguhan agar [HttpServer] lokal / error
/// socket bisa diuji.
Future<T> runWithRealHttpClient<T>(Future<T> Function() body) {
  final overrides = _RealNetworkHttpOverrides();
  return HttpOverrides.runZoned(
    body,
    createHttpClient: overrides.createHttpClient,
  );
}
