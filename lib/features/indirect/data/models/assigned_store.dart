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
