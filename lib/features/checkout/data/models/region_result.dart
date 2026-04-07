/// Result from the 3-step region picker (Provinsi → Kota/Kab → Kecamatan).
class RegionResult {
  const RegionResult({
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
  });

  final String provinsi;
  final String kota;
  final String kecamatan;
}
