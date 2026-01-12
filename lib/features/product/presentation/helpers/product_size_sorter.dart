/// Helper untuk sorting ukuran produk dari terkecil ke terbesar
class ProductSizeSorter {
  /// Mengurutkan list ukuran dari terkecil ke terbesar
  /// Format ukuran biasanya: "90x200", "120x200", "160x200", dll
  static List<String> sortSizes(List<String> sizes) {
    final sortedSizes = List<String>.from(sizes);

    sortedSizes.sort((a, b) {
      // Parse ukuran untuk mendapatkan dimensi pertama (lebar)
      final aWidth = _parseSize(a);
      final bWidth = _parseSize(b);

      // Jika salah satu tidak bisa di-parse, letakkan di akhir
      if (aWidth == null && bWidth == null) {
        return a.compareTo(b); // Sort alphabetically as fallback
      }
      if (aWidth == null) return 1;
      if (bWidth == null) return -1;

      // Sort berdasarkan lebar dari terkecil ke terbesar
      return aWidth.compareTo(bWidth);
    });

    return sortedSizes;
  }

  /// Parse ukuran untuk mendapatkan dimensi pertama (lebar)
  /// Format: "90x200" -> 90, "120x200" -> 120
  static int? _parseSize(String size) {
    if (size.isEmpty) return null;

    // Cari angka pertama sebelum 'x' atau spasi
    final match = RegExp(r'^(\d+)').firstMatch(size);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }

    return null;
  }
}
