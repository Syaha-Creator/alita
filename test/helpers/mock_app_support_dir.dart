import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mocks [path_provider] so [getApplicationSupportDirectory] resolves in unit tests.
void setMockApplicationSupportDirectory(String path) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall call) async {
      switch (call.method) {
        case 'getApplicationSupportDirectory':
        case 'getTemporaryDirectory':
        case 'getApplicationDocumentsDirectory':
          return path;
        default:
          return null;
      }
    },
  );
}
