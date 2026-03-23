import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/log.dart';

/// Streams `true` when online, `false` when offline.
///
/// When `connectivity_plus` reports offline, a DNS lookup is performed to guard
/// against false negatives (known issue on certain iOS/Android devices).
/// While in offline state, a periodic re-check runs every 15 s.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  final controller = StreamController<bool>();
  Timer? retryTimer;

  void emit(bool online) {
    if (controller.isClosed) return;
    controller.add(online);
    retryTimer?.cancel();
    if (!online) {
      retryTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
        if (controller.isClosed) {
          retryTimer?.cancel();
          return;
        }
        final verified = await _verifiedOnline(connectivity);
        if (controller.isClosed) return;
        controller.add(verified);
        if (verified) retryTimer?.cancel();
      });
    }
  }

  _verifiedOnline(connectivity).then(emit);

  final sub = connectivity.onConnectivityChanged.listen((results) async {
    if (_isOnline(results)) {
      emit(true);
    } else {
      emit(await _verifiedOnline(connectivity));
    }
  });

  ref.onDispose(() {
    retryTimer?.cancel();
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

/// When the platform reports offline, double-check with a real DNS lookup
/// to avoid false negatives from `connectivity_plus`.
Future<bool> _verifiedOnline(Connectivity connectivity) async {
  final results = await connectivity.checkConnectivity();
  if (_isOnline(results)) return true;

  try {
    final lookup = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 3));
    final reachable = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    if (reachable) {
      Log.warning(
        'connectivity_plus reported offline but DNS lookup succeeded',
        tag: 'Connectivity',
      );
    }
    return reachable;
  } catch (_) {
    return false;
  }
}

/// Synchronous convenience — `true` when confirmed offline.
/// Returns `false` (assume online) while loading.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).whenData((v) => !v).value ?? false;
});
