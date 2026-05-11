import 'package:flutter/material.dart';

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
  protector,
  aksesori,
  sprei,
  lainnya,
}

extension PricelistCustomComponentTypeLabel on PricelistCustomComponentType {
  String get shortLabel => switch (this) {
        PricelistCustomComponentType.mattress => 'Kasur',
        PricelistCustomComponentType.divan => 'Divan',
        PricelistCustomComponentType.headboard => 'Headboard',
        PricelistCustomComponentType.sorong => 'Sorong',
        PricelistCustomComponentType.protector => 'Protector',
        PricelistCustomComponentType.aksesori => 'Aksesori',
        PricelistCustomComponentType.sprei => 'Sprei',
        PricelistCustomComponentType.lainnya => 'Lainnya',
      };

  /// Nilai `item_type` yang dikirim ke API order_letter_details.
  String get apiItemType => switch (this) {
        PricelistCustomComponentType.mattress => 'Mattress',
        PricelistCustomComponentType.divan => 'Divan',
        PricelistCustomComponentType.headboard => 'Headboard',
        PricelistCustomComponentType.sorong => 'Sorong',
        PricelistCustomComponentType.protector => 'Protector',
        PricelistCustomComponentType.aksesori => 'Aksesori',
        PricelistCustomComponentType.sprei => 'Sprei',
        PricelistCustomComponentType.lainnya => 'Lainnya',
      };

  /// True jika tipe ini adalah komponen bundle set (divan/headboard/sorong).
  bool get isBundleComponent => this == PricelistCustomComponentType.divan ||
      this == PricelistCustomComponentType.headboard ||
      this == PricelistCustomComponentType.sorong;

  /// True jika tipe ini adalah item mandiri (non-bundle, bukan komponen set kasur).
  bool get isStandalone =>
      this == PricelistCustomComponentType.protector ||
      this == PricelistCustomComponentType.aksesori ||
      this == PricelistCustomComponentType.sprei ||
      this == PricelistCustomComponentType.lainnya;

  /// Deskripsi singkat tampil di bawah chip selector saat tipe ini aktif.
  String get hint => switch (this) {
        PricelistCustomComponentType.mattress =>
          'Produk kasur — dikirim ke laporan sebagai Mattress.',
        PricelistCustomComponentType.divan =>
          'Produk divan — dikirim ke laporan sebagai Divan.',
        PricelistCustomComponentType.headboard =>
          'Produk headboard / sandaran — dikirim ke laporan sebagai Headboard.',
        PricelistCustomComponentType.sorong =>
          'Produk laci sorong — dikirim ke laporan sebagai Sorong.',
        PricelistCustomComponentType.protector =>
          'Mattress protector atau alas pelindung.',
        PricelistCustomComponentType.aksesori =>
          'Aksesori seperti bantal, guling, dan sejenisnya.',
        PricelistCustomComponentType.sprei =>
          'Sprei, bed cover, linen, dan sejenisnya.',
        PricelistCustomComponentType.lainnya =>
          'Produk lain yang tidak masuk kategori di atas.',
      };

  /// Icon untuk chip selector.
  IconData get icon => switch (this) {
        PricelistCustomComponentType.mattress => Icons.king_bed_outlined,
        PricelistCustomComponentType.divan => Icons.weekend_outlined,
        PricelistCustomComponentType.headboard => Icons.chair_outlined,
        PricelistCustomComponentType.sorong => Icons.inbox_outlined,
        PricelistCustomComponentType.protector => Icons.shield_outlined,
        PricelistCustomComponentType.aksesori => Icons.compress_outlined,
        PricelistCustomComponentType.sprei => Icons.layers_outlined,
        PricelistCustomComponentType.lainnya => Icons.more_horiz,
      };
}

extension ProductPricelistCustomX on Product {
  bool get isPricelistCustomPlaceholder =>
      id == kPricelistCustomPlaceholderProductId;

  bool get isPricelistCustomCartLine =>
      id.startsWith(kPricelistCustomCartLineIdPrefix);
}
