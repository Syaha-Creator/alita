/// Result from the region picker
/// (Provinsi → Kota/Kab → Kecamatan → Kelurahan/Desa + kode pos).
class RegionResult {
  const RegionResult({
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.kelurahan,
    this.kodepos = '',
  });

  final String provinsi;
  final String kota;
  final String kecamatan;
  final String kelurahan;
  final String kodepos;
}
