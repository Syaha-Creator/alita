import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:screen_protector/screen_protector.dart';

import '../utils/log.dart';

/// Proteksi layar sensitif (screenshot hitam / mitigasi rekam layar & app switcher),
/// khususnya untuk **Detail Pesanan**. Aktifkan dengan [enter] dan **selalu**
/// pasangkan [leave] di `dispose` agar halaman lain tidak tertinggal terkunci.
///
/// **Android:** `protectDataLeakageOn` + `preventScreenshotOn` (setara prinsip
/// `FLAG_SECURE` + pratinjau recents).
///
/// **iOS:** `protectDataLeakageWithBlur` (app ke background) +
/// `preventScreenshotOn`. Simulator sering tidak merepresentasikan perilaku
/// perangkat fisik — uji di iPhone sungguhan.
///
/// [onScreenshotAttempt] / [onScreenRecord] (opsional): hanya relevan di **iOS**
/// menurut dokumentasi plugin; di Android callback tidak dipanggil.
///
/// Mendukung **nesting** lewat penghitung depth: proteksi native hanya dinyalakan
/// pada transisi depth 0→1 dan dimatikan pada 1→0.
abstract final class ScreenCaptureGuardService {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static int _depth = 0;
  static bool _listenersRegistered = false;

  /// Nyalakan proteksi. Panggil dari `initState` + post-frame setelah [mounted].
  static Future<void> enter({
    void Function()? onScreenshotAttempt,
    void Function(bool isRecording)? onScreenRecord,
  }) async {
    if (!_supported) return;
    if (_depth == 0) {
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          await ScreenProtector.protectDataLeakageWithBlur();
        } else {
          await ScreenProtector.protectDataLeakageOn();
        }
        await ScreenProtector.preventScreenshotOn();

        final wantListener = onScreenshotAttempt != null ||
            onScreenRecord != null;
        if (wantListener) {
          // Plugin mendeklarasikan `addListener` sebagai `void async` — jangan await.
          ScreenProtector.addListener(
            onScreenshotAttempt ?? () {},
            onScreenRecord ?? (_) {},
          );
          _listenersRegistered = true;
        }
      } catch (e, st) {
        Log.error(e, st, reason: 'ScreenCaptureGuardService.enter');
        await _safeTearDownPartial();
        return;
      }
    }
    _depth++;
  }

  /// Matikan proteksi. Panggil dari `dispose` (biasanya `unawaited(leave())`).
  static Future<void> leave() async {
    if (!_supported) return;
    if (_depth <= 0) return;
    _depth--;
    if (_depth > 0) return;
    await _tearDownFully();
  }

  static Future<void> _tearDownFully() async {
    try {
      if (_listenersRegistered) {
        ScreenProtector.removeListener();
        _listenersRegistered = false;
      }
      await ScreenProtector.preventScreenshotOff();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
      await ScreenProtector.protectDataLeakageOff();
    } catch (e, st) {
      Log.error(e, st, reason: 'ScreenCaptureGuardService.leave');
    }
  }

  /// Setelah [enter] gagal di tengah jalan — cegah layar tertinggal “setengah”.
  static Future<void> _safeTearDownPartial() async {
    try {
      if (_listenersRegistered) {
        ScreenProtector.removeListener();
        _listenersRegistered = false;
      }
      await ScreenProtector.preventScreenshotOff();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await ScreenProtector.protectDataLeakageWithBlurOff();
      }
      await ScreenProtector.protectDataLeakageOff();
    } catch (e, st) {
      Log.error(e, st, reason: 'ScreenCaptureGuardService.partialTeardown');
    }
  }
}
