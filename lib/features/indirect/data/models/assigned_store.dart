import 'package:freezed_annotation/freezed_annotation.dart';

part 'assigned_store.freezed.dart';
part 'assigned_store.g.dart';

/// Satu baris dari API `address_number_by_sales_code`.
@freezed
class AssignedStore with _$AssignedStore {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory AssignedStore({
    required int addressNumber,
    int? parentNumber,
    String? longAddressNumber,
    String? taxNumber,
    required String alphaName,
    required String address,
    String? branch,
    String? searchType,
    @JsonKey(name: 'catcode_27') String? catcode27,
  }) = _AssignedStore;

  factory AssignedStore.fromJson(Map<String, dynamic> json) =>
      _$AssignedStoreFromJson(json);
}

extension AssignedStoreX on AssignedStore {
  /// True jika [searchType] menandai customer baru (`new_customer` / `new`).
  static bool isNewCustomerSearchType(String? searchType) {
    final t = searchType?.trim().toLowerCase() ?? '';
    return t == 'new_customer' || t == 'new';
  }

  /// True jika toko ini ditandai sebagai customer baru oleh API (search_type == 'new_customer').
  /// Order indirect ke customer baru wajib mendapat persetujuan ASM meskipun tanpa diskon tambahan.
  bool get isNewCustomer => isNewCustomerSearchType(searchType);
}
