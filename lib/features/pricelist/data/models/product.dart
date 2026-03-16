import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

double? _parseDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Product model - immutable with freezed
@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    @JsonKey(fromJson: _parseDouble) required double price,
    required String imageUrl,
    required String category,
    @Default('') String description,
    @Default(true) bool isAvailable,
    @Default('') String channel,
    @Default('') String brand,
    @Default('-') String program,

    // Specs for Sibling Grouping / Konfigurator Varian
    required String kasur,
    required String ukuran,
    required String divan,
    required String headboard,
    required String sorong,
    required bool isSet,
    @JsonKey(fromJson: _parseDouble) required double pricelist,
    @JsonKey(fromJson: _parseDouble) required double eupKasur,
    @JsonKey(fromJson: _parseDouble) required double eupDivan,
    @JsonKey(fromJson: _parseDouble) required double eupHeadboard,
    @JsonKey(fromJson: _parseDouble) required double eupSorong,

    // Pricelist per komponen (breakdown)
    @JsonKey(fromJson: _parseDouble) required double plKasur,
    @JsonKey(fromJson: _parseDouble) required double plDivan,
    @JsonKey(fromJson: _parseDouble) required double plHeadboard,
    @JsonKey(fromJson: _parseDouble) required double plSorong,

    // Bonus (nullable)
    String? bonus1,
    int? qtyBonus1,
    String? bonus2,
    int? qtyBonus2,
    String? bonus3,
    int? qtyBonus3,
    String? bonus4,
    int? qtyBonus4,
    String? bonus5,
    int? qtyBonus5,
    String? bonus6,
    int? qtyBonus6,
    String? bonus7,
    int? qtyBonus7,
    String? bonus8,
    int? qtyBonus8,

    // Pricelist bonus (nilai Rupiah per bonus, nullable)
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus1,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus2,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus3,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus4,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus5,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus6,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus7,
    @JsonKey(fromJson: _parseDoubleNullable) double? plBonus8,

    // Batas harga bawah analyst: total jual tidak boleh melebihi nilai ini
    @JsonKey(fromJson: _parseDouble) @Default(0) double bottomPriceAnalyst,

    // Batas maksimal diskon (limit) per tingkat — dari database
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc1,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc2,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc3,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc4,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc5,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc6,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc7,
    @JsonKey(fromJson: _parseDouble) @Default(0) double disc8,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
