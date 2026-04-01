import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/app_formatters.dart';

part 'store_model.freezed.dart';
part 'store_model.g.dart';

String _storeDisplayTitleCase(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  return AppFormatters.titleCase(t);
}

@freezed
class StoreModel with _$StoreModel {
  const factory StoreModel({
    required int id,
    @Default('') String name,
    @Default('') String category,
    @Default('') String address,
    @Default('') String city,
    @Default('') String area,
    @Default('') String image,
  }) = _StoreModel;

  factory StoreModel.fromJson(Map<String, dynamic> json) =>
      _$StoreModelFromJson(json);
}

/// Display helpers when API returns empty [StoreModel.name].
extension StoreModelDisplay on StoreModel {
  /// [name] untuk UI — [AppFormatters.titleCase]. Kosong jika [name] kosong.
  String get displayNameTitleCase {
    final n = name.trim();
    if (n.isEmpty) return '';
    return _storeDisplayTitleCase(n);
  }

  /// Kota · area dengan title case per segmen.
  String get displayLocLine {
    return [city, area]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_storeDisplayTitleCase)
        .join(' · ');
  }

  /// Kategori dengan title case.
  String get displayCategoryTitleCase =>
      _storeDisplayTitleCase(category);

  /// Label shown in UI when [name] is blank: kota/area, kategori, alamat, atau ID.
  /// Semua teks manusia memakai [AppFormatters.titleCase] kecuali `Toko #id`.
  String get displayLabelOrFallback {
    final n = name.trim();
    if (n.isNotEmpty) return _storeDisplayTitleCase(n);
    final loc = [city, area]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_storeDisplayTitleCase)
        .join(' · ');
    if (loc.isNotEmpty) return loc;
    final c = category.trim();
    if (c.isNotEmpty) return _storeDisplayTitleCase(c);
    final a = address.trim();
    if (a.isNotEmpty) {
      final formatted = _storeDisplayTitleCase(a);
      return formatted.length > 48
          ? '${formatted.substring(0, 45)}…'
          : formatted;
    }
    return 'Toko #$id';
  }
}
