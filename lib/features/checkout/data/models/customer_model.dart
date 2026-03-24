/// Pelanggan global (Firebase Data Connect / PostgreSQL).
class CustomerModel {
  const CustomerModel({
    required this.phoneNormalized,
    required this.name,
    this.email = '',
    this.region = '',
    this.address = '',
    this.provinsi,
    this.kota,
    this.kecamatan,
  });

  /// Kunci utama: nomor HP ternormalisasi (mis. 62…).
  final String phoneNormalized;
  final String name;
  final String email;
  final String region;
  final String address;
  final String? provinsi;
  final String? kota;
  final String? kecamatan;
}
