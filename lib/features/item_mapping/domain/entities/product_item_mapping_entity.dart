/// Entity untuk product item mapping
/// Representasi mapping antara product dan item lookup
class ProductItemMappingEntity {
  final int productId;
  final String brand;
  final String? kasurItemNumber;
  final String? divanItemNumber;
  final String? headboardItemNumber;
  final String? sorongItemNumber;
  final String? accessoriesItemNumber;
  final List<String?> bonusItemNumbers;

  const ProductItemMappingEntity({
    required this.productId,
    required this.brand,
    this.kasurItemNumber,
    this.divanItemNumber,
    this.headboardItemNumber,
    this.sorongItemNumber,
    this.accessoriesItemNumber,
    required this.bonusItemNumbers,
  });

  /// Cek apakah ada item yang tidak ditemukan di lookup
  bool get hasUnmappedItems {
    return kasurItemNumber == null ||
        divanItemNumber == null ||
        headboardItemNumber == null ||
        sorongItemNumber == null ||
        bonusItemNumbers.any((item) => item == null);
  }

  /// Dapatkan daftar item yang tidak ditemukan
  List<String> get unmappedItems {
    final List<String> unmapped = [];

    if (kasurItemNumber == null) unmapped.add('Kasur');
    if (divanItemNumber == null) unmapped.add('Divan');
    if (headboardItemNumber == null) unmapped.add('Headboard');
    if (sorongItemNumber == null) unmapped.add('Sorong');

    for (int i = 0; i < bonusItemNumbers.length; i++) {
      if (bonusItemNumbers[i] == null) {
        unmapped.add('Bonus ${i + 1}');
      }
    }

    return unmapped;
  }
}

