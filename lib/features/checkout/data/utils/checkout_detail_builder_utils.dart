import '../../../pricelist/data/models/item_lookup.dart';

/// Shared helpers for building checkout detail payloads.
class CheckoutDetailBuilderUtils {
  const CheckoutDetailBuilderUtils._();

  /// Builds item_description in consistent format:
  /// `Nama - Kode - Warna` (without dangling separators).
  static String buildCleanItemDescription(
    String baseName, {
    String? code,
    String? color,
  }) {
    final parts = <String>[];

    if (baseName.trim().isNotEmpty) {
      parts.add(baseName.trim());
    }
    if (code != null && code.trim().isNotEmpty && code.trim() != '-') {
      parts.add(code.trim());
    }
    if (color != null && color.trim().isNotEmpty && color.trim() != '-') {
      parts.add(color.trim());
    }

    return parts.join(' - ');
  }

  /// Builds item_description enriched by fabric/color information.
  /// Priority: lookup API data by SKU, then fallback to stored cart snapshot.
  static String buildDescription({
    required String baseDesc,
    required String sku,
    required Map<String, ItemLookup> lookupByItemNum,
    String? storedKain,
    String? storedWarna,
  }) {
    final lookup = lookupByItemNum[sku];

    String? kain;
    String? warna;

    if (lookup != null) {
      kain = lookup.jenisKain;
      warna = lookup.warnaKain;
    } else {
      kain = (storedKain != null && storedKain.isNotEmpty && storedKain != 'null')
          ? storedKain
          : null;
      warna = (storedWarna != null &&
              storedWarna.isNotEmpty &&
              storedWarna != 'null')
          ? storedWarna
          : null;
    }

    final safeBase = baseDesc.isNotEmpty ? baseDesc : sku;
    final safeCode =
        (kain != null && kain.isNotEmpty && kain != 'null') ? kain : null;
    final safeColor =
        (warna != null && warna.isNotEmpty && warna != 'null') ? warna : null;

    return buildCleanItemDescription(
      safeBase,
      code: safeCode,
      color: safeColor,
    );
  }

  /// Throws [Exception] when required field is null/empty/zero.
  static void validateRequiredField(String fieldName, dynamic value) {
    if (value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is num && value == 0)) {
      throw Exception('Data "$fieldName" tidak valid atau kosong.');
    }
  }
}
