import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:alitapricelist/core/utils/user_facing_error.dart';

void main() {
  group('userFacingErrorMessage', () {
    test('never leaks raw "Instance of" for a custom error class', () {
      final msg = userFacingErrorMessage(StateError("Instance of 'Foo'"));
      expect(msg, isNot(contains("Instance of '")));
    });

    test('network errors get a friendly connectivity message', () {
      expect(
        userFacingErrorMessage(const SocketException('failed')),
        contains('koneksi internet'),
      );
      expect(
        userFacingErrorMessage(TimeoutException('timeout')),
        contains('koneksi internet'),
      );
    });

    test('keeps a deliberately-thrown friendly Exception message', () {
      final msg = userFacingErrorMessage(Exception('Nama pelanggan wajib diisi'));
      expect(msg, 'Nama pelanggan wajib diisi');
    });

    test('falls back to a generic message for unrecognised errors', () {
      final msg = userFacingErrorMessage(ArgumentError('some internal detail'));
      expect(msg, 'Terjadi kesalahan. Silakan coba lagi.');
    });

    test('supports a custom fallback message', () {
      final msg = userFacingErrorMessage(
        ArgumentError('detail'),
        fallback: 'Gagal memuat data.',
      );
      expect(msg, 'Gagal memuat data.');
    });
  });
}
