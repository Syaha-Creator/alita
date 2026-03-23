import '../data/models/item_lookup.dart';
import '../data/models/product.dart';

/// Validation result from [ProductCartValidator.validate].
class CartValidationResult {
  final bool isValid;
  final String? errorMessage;

  const CartValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  const CartValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Validates product configuration before adding to cart.
///
/// Extracted from [ProductDetailPage._onAddToCartTap] to reduce file size.
class ProductCartValidator {
  ProductCartValidator._();

  static List<ItemLookup> lookupsFor(
    String name,
    String effectiveSize,
    Map<String, List<ItemLookup>> groupedLookups,
  ) {
    final key = name.trim().toLowerCase();
    if (key.isEmpty || key.contains('tanpa')) return [];
    final all = groupedLookups[key] ?? [];
    final filtered = all.where((l) => l.ukuran == effectiveSize).toList();
    return filtered.isNotEmpty ? filtered : all;
  }

  static CartValidationResult validate({
    required Product activeProduct,
    required String effectiveSize,
    required Map<String, List<ItemLookup>> groupedLookups,
    required ItemLookup? selectedKasurLookup,
    required bool isKasurCustom,
    required bool isKasurOnly,
    required String? selectedHeadboard,
    required ItemLookup? selectedDivanLookup,
    required bool isDivanCustom,
    required ItemLookup? selectedHeadboardLookup,
    required bool isHeadboardCustom,
  }) {
    final kLookups =
        lookupsFor(activeProduct.kasur, effectiveSize, groupedLookups);
    if (kLookups.length > 1 && selectedKasurLookup == null && !isKasurCustom) {
      return const CartValidationResult.invalid(
          'Pilih Warna / Kain Kasur terlebih dahulu');
    }

    final savingAsSet = !isKasurOnly;
    if (savingAsSet) {
      final hasHeadboardSelection = selectedHeadboard != null &&
          selectedHeadboard.trim().isNotEmpty;
      if (!hasHeadboardSelection) {
        return const CartValidationResult.invalid(
            'Pilih model Sandaran terlebih dahulu.');
      }

      final dLookups =
          lookupsFor(activeProduct.divan, effectiveSize, groupedLookups);
      if (dLookups.length > 1 && selectedDivanLookup == null && !isDivanCustom) {
        return const CartValidationResult.invalid(
            'Pilih Warna / Kain Divan terlebih dahulu');
      }
      final hbLookups =
          lookupsFor(activeProduct.headboard, effectiveSize, groupedLookups);
      if (hbLookups.isNotEmpty &&
          selectedHeadboardLookup == null &&
          !isHeadboardCustom) {
        return const CartValidationResult.invalid(
            'Pilih Warna / Kain Sandaran terlebih dahulu');
      }
    }

    return const CartValidationResult.valid();
  }
}
