// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assigned_store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AssignedStoreImpl _$$AssignedStoreImplFromJson(Map<String, dynamic> json) =>
    _$AssignedStoreImpl(
      addressNumber: (json['address_number'] as num).toInt(),
      parentNumber: (json['parent_number'] as num?)?.toInt(),
      longAddressNumber: json['long_address_number'] as String?,
      taxNumber: json['tax_number'] as String?,
      alphaName: json['alpha_name'] as String,
      address: json['address'] as String,
      branch: json['branch'] as String?,
      searchType: json['search_type'] as String?,
      catcode27: json['catcode_27'] as String?,
    );

Map<String, dynamic> _$$AssignedStoreImplToJson(_$AssignedStoreImpl instance) =>
    <String, dynamic>{
      'address_number': instance.addressNumber,
      'parent_number': instance.parentNumber,
      'long_address_number': instance.longAddressNumber,
      'tax_number': instance.taxNumber,
      'alpha_name': instance.alphaName,
      'address': instance.address,
      'branch': instance.branch,
      'search_type': instance.searchType,
      'catcode_27': instance.catcode27,
    };
