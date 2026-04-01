import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

import '../../../../core/utils/log.dart';
import '../dataconnect/generated/alita_connector.dart';
import '../models/customer_model.dart';

/// Repository pelanggan global via **Firebase Data Connect** (PostgreSQL).
///
/// Pastikan:
/// - `dataconnect/` sudah di-deploy (`firebase deploy --only dataconnect`)
/// - Cloud SQL `instanceId` di [dataconnect.yaml] valid
/// - Firebase Authentication **Anonymous** aktif (untuk `@auth(level: USER)`)
/// - **App Check**: Data Connect transport selalu menyertakan
///   [FirebaseAppCheck.instance]. Jika App Check **enforced** untuk Data Connect,
///   daftarkan token debug (Xcode log / logcat) di Firebase Console → App Check.
class CustomerRepository {
  CustomerRepository({AlitaConnectorConnector? connector})
      : _connector = connector ?? AlitaConnectorConnector.instance;

  final AlitaConnectorConnector _connector;

  /// Ensures a Firebase Auth user exists (anonymous sign-in if needed)
  /// and wires the auth instance into the Data Connect transport so the
  /// SDK can attach ID tokens to gRPC calls.
  ///
  /// Jika user saat ini stale (dihapus saat logout), [signOut] lalu buat baru.
  Future<void> _ensureAuth() async {
    final auth = FirebaseAuth.instance;
    _connector.dataConnect.auth = auth;
    _connector.dataConnect.appCheck = FirebaseAppCheck.instance;

    // Validasi user yang ada — token refresh bisa gagal jika record sudah dihapus.
    if (auth.currentUser != null) {
      try {
        await auth.currentUser!.getIdToken(true);
      } catch (_) {
        await auth.signOut();
      }
    }

    // Tidak ada user valid → buat anonim baru.
    if (auth.currentUser == null) {
      try {
        final cred = await auth.signInAnonymously();
        if (cred.user == null) {
          throw StateError(
            'Firebase Auth: tidak ada user setelah sign-in '
            '(periksa Anonymous auth di Console).',
          );
        }
        await cred.user!.getIdToken(true);
      } catch (e, st) {
        Log.error(e, st, reason: 'DataConnect anonymous sign-in');
        rethrow;
      }
    }

    // Jangan panggil FirebaseAppCheck.getToken di loop di sini: setiap panggilan
    // menambah beban ke backend dan memperparah "Too many attempts" di emulator.
    // Transport Data Connect mengambil token saat execute; debug/profile sudah
    // memakai debug provider lewat main.dart (!kReleaseMode).
    if (kReleaseMode) {
      try {
        await FirebaseAppCheck.instance.getToken(false);
      } catch (e, st) {
        Log.error(e, st, reason: 'DataConnect App Check getToken (release)');
      }
    }
  }

  /// Normalisasi nomor untuk primary key & pencarian (digit, prefiks 62…).
  static String normalizePhoneKey(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('62')) return digits;
    if (digits.startsWith('0') && digits.length > 1) {
      return '62${digits.substring(1)}';
    }
    if (digits.length >= 9 && digits.length <= 12) {
      return '62$digits';
    }
    return digits;
  }

  /// Mencari pelanggan berdasarkan nomor HP (setelah normalisasi).
  Future<CustomerModel?> getCustomerByPhone(String phoneNumber) async {
    final key = normalizePhoneKey(phoneNumber);
    if (key.isEmpty) return null;

    await _ensureAuth();
    final result =
        await _connector.getCustomerByPhone(phoneNumber: key).execute();
    final row = result.data.customer;
    if (row == null) return null;

    return CustomerModel(
      phoneNormalized: row.phoneNumber,
      name: row.name,
      email: row.email ?? '',
      region: row.region ?? '',
      address: row.address ?? '',
      provinsi: row.provinsi,
      kota: row.kota,
      kecamatan: row.kecamatan,
    );
  }

  /// Upsert berdasarkan [CustomerModel.phoneNormalized].
  Future<void> upsertCustomer(CustomerModel customer) async {
    if (customer.phoneNormalized.isEmpty || customer.name.isEmpty) return;

    await _ensureAuth();
    await _connector
        .upsertCustomer(
          phoneNumber: customer.phoneNormalized,
          name: customer.name,
        )
        .email(customer.email)
        .region(customer.region)
        .address(customer.address)
        .provinsi(customer.provinsi ?? '')
        .kota(customer.kota ?? '')
        .kecamatan(customer.kecamatan ?? '')
        .execute();
  }

  /// Membangun [CustomerModel] dari map kontak checkout lalu [upsertCustomer].
  Future<void> upsertFromCheckoutContactMap(Map<String, dynamic> map) async {
    final rawPhone = (map['phone'] as String?)?.trim() ?? '';
    final key = normalizePhoneKey(rawPhone);
    if (key.isEmpty) return;

    final name = (map['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) return;

    final wilayah = (map['wilayah'] as String?)?.trim() ?? '';
    final alamat = (map['alamat_detail'] as String?)?.trim() ??
        (map['address'] as String?)?.trim() ??
        '';

    final model = CustomerModel(
      phoneNormalized: key,
      name: name,
      email: (map['email'] as String?)?.trim() ?? '',
      region: wilayah,
      address: alamat,
      provinsi: (map['provinsi'] as String?)?.trim(),
      kota: (map['kota'] as String?)?.trim(),
      kecamatan: (map['kecamatan'] as String?)?.trim(),
    );
    await upsertCustomer(model);
  }

  /// Upsert latar belakang; error hanya di-log (tidak mengganggu checkout).
  static Future<void> upsertFromCheckoutContactMapQuiet(
    CustomerRepository repo,
    Map<String, dynamic>? map,
  ) async {
    if (map == null) return;
    try {
      await repo.upsertFromCheckoutContactMap(map);
    } catch (e, st) {
      Log.error(
        e,
        st,
        reason: 'CustomerRepository.upsertFromCheckoutContactMapQuiet',
      );
    }
  }
}
