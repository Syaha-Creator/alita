import 'product.dart';

/// Id kartu sintetis di grid pricelist (bukan id baris keranjang).
const kPricelistCustomPlaceholderProductId = '__pricelist_custom_placeholder__';

/// Awalan id unik per baris keranjang custom.
const kPricelistCustomCartLineIdPrefix = 'pricelist_custom_line_';

/// Batas diskon tambahan (nilai fraksi 0–1, sama konvensi [Product.disc1]).
const double kPricelistCustomDisc1Max = 0.10;
const double kPricelistCustomDisc2Max = 0.05;
const double kPricelistCustomDisc3Max = 0.05;
const double kPricelistCustomDisc4Max = 0.50;

/// Komponen tunggal untuk satu baris `order_letter_details`.
enum PricelistCustomComponentType {
  mattress,
  divan,
  headboard,
  sorong,
}

extension PricelistCustomComponentTypeLabel on PricelistCustomComponentType {
  String get shortLabel => switch (this) {
        PricelistCustomComponentType.mattress => 'Kasur',
        PricelistCustomComponentType.divan => 'Divan',
        PricelistCustomComponentType.headboard => 'Headboard',
        PricelistCustomComponentType.sorong => 'Sorong',
      };
}

extension ProductPricelistCustomX on Product {
  bool get isPricelistCustomPlaceholder =>
      id == kPricelistCustomPlaceholderProductId;

  bool get isPricelistCustomCartLine =>
      id.startsWith(kPricelistCustomCartLineIdPrefix);
}
