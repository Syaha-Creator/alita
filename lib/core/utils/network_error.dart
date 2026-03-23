import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Detects transient network errors (timeout, DNS, socket, connection reset).
///
/// Uses two-layer detection:
/// 1. Dart type check — [SocketException], [TimeoutException], [http.ClientException]
/// 2. String fallback — catches wrapped exceptions where type check fails
///    (e.g. [http.ClientException] wrapping [SocketException] inside [Future.wait])
bool isNetworkError(Object e) {
  if (e is SocketException ||
      e is TimeoutException ||
      e is http.ClientException) {
    return true;
  }
  final msg = e.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('host lookup') ||
      msg.contains('connection closed') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('network is unreachable');
}
