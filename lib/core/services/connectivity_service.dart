import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams `true` when online, `false` when offline.
/// Disposes the subscription automatically when the provider is disposed.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  final controller = StreamController<bool>();

  // Emit current status immediately
  connectivity.checkConnectivity().then((results) {
    if (!controller.isClosed) {
      controller.add(_isOnline(results));
    }
  });

  // Listen to changes
  final sub = connectivity.onConnectivityChanged.listen((results) {
    if (!controller.isClosed) {
      controller.add(_isOnline(results));
    }
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

bool _isOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

/// Synchronous convenience — `true` when confirmed offline.
/// Returns `false` (assume online) while loading.
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).whenData((v) => !v).value ?? false;
});
