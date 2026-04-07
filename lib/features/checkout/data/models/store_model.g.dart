// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreModelImpl _$$StoreModelImplFromJson(Map<String, dynamic> json) =>
    _$StoreModelImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      address: json['address'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      image: json['image'] as String? ?? '',
    );

Map<String, dynamic> _$$StoreModelImplToJson(_$StoreModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'category': instance.category,
      'address': instance.address,
      'state': instance.state,
      'city': instance.city,
      'area': instance.area,
      'phone': instance.phone,
      'image': instance.image,
    };
