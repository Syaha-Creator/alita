// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CartBonusSnapshotImpl _$$CartBonusSnapshotImplFromJson(
        Map<String, dynamic> json) =>
    _$CartBonusSnapshotImpl(
      name: json['name'] as String? ?? '',
      qty: json['qty'] == null ? 0 : _parseInt(json['qty']),
      sku: json['sku'] as String? ?? '',
    );

Map<String, dynamic> _$$CartBonusSnapshotImplToJson(
        _$CartBonusSnapshotImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'qty': instance.qty,
      'sku': instance.sku,
    };

_$CartItemImpl _$$CartItemImplFromJson(Map<String, dynamic> json) =>
    _$CartItemImpl(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      masterProduct: json['masterProduct'] == null
          ? null
          : Product.fromJson(json['masterProduct'] as Map<String, dynamic>),
      quantity: json['quantity'] == null ? 1 : _parseInt(json['quantity']),
      kasurSku: json['kasurSku'] as String? ?? '',
      divanSku: json['divanSku'] as String? ?? '',
      sandaranSku: json['sandaranSku'] as String? ?? '',
      sorongSku: json['sorongSku'] as String? ?? '',
      divanKain: json['divanKain'] as String? ?? '',
      divanWarna: json['divanWarna'] as String? ?? '',
      sandaranKain: json['sandaranKain'] as String? ?? '',
      sandaranWarna: json['sandaranWarna'] as String? ?? '',
      sorongKain: json['sorongKain'] as String? ?? '',
      sorongWarna: json['sorongWarna'] as String? ?? '',
      originalEupKasur: json['originalEupKasur'] == null
          ? 0.0
          : _parseDouble(json['originalEupKasur']),
      originalEupDivan: json['originalEupDivan'] == null
          ? 0.0
          : _parseDouble(json['originalEupDivan']),
      originalEupHeadboard: json['originalEupHeadboard'] == null
          ? 0.0
          : _parseDouble(json['originalEupHeadboard']),
      originalEupSorong: json['originalEupSorong'] == null
          ? 0.0
          : _parseDouble(json['originalEupSorong']),
      discount1:
          json['discount1'] == null ? 0.0 : _parseDouble(json['discount1']),
      discount2:
          json['discount2'] == null ? 0.0 : _parseDouble(json['discount2']),
      discount3:
          json['discount3'] == null ? 0.0 : _parseDouble(json['discount3']),
      discount4:
          json['discount4'] == null ? 0.0 : _parseDouble(json['discount4']),
      bonusSnapshots: (json['bonusSnapshots'] as List<dynamic>?)
              ?.map(
                  (e) => CartBonusSnapshot.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CartBonusSnapshot>[],
      indirectStoreAddressNumber:
          _parseIntNullable(json['indirectStoreAddressNumber']),
      indirectStoreAlphaName: json['indirectStoreAlphaName'] as String? ?? '',
      indirectStoreAddress: json['indirectStoreAddress'] as String? ?? '',
      indirectStorePhone: json['indirectStorePhone'] as String? ?? '',
      indirectStoreDiscounts: json['indirectStoreDiscounts'] == null
          ? const <double>[]
          : _parseDoubleList(json['indirectStoreDiscounts']),
      indirectStoreDiscountDisplay:
          json['indirectStoreDiscountDisplay'] as String? ?? '',
      isFocVoucher: json['isFocVoucher'] == null
          ? false
          : _parseBoolDefaultFalse(json['isFocVoucher']),
    );

Map<String, dynamic> _$$CartItemImplToJson(_$CartItemImpl instance) =>
    <String, dynamic>{
      'product': instance.product,
      'masterProduct': instance.masterProduct,
      'quantity': instance.quantity,
      'kasurSku': instance.kasurSku,
      'divanSku': instance.divanSku,
      'sandaranSku': instance.sandaranSku,
      'sorongSku': instance.sorongSku,
      'divanKain': instance.divanKain,
      'divanWarna': instance.divanWarna,
      'sandaranKain': instance.sandaranKain,
      'sandaranWarna': instance.sandaranWarna,
      'sorongKain': instance.sorongKain,
      'sorongWarna': instance.sorongWarna,
      'originalEupKasur': instance.originalEupKasur,
      'originalEupDivan': instance.originalEupDivan,
      'originalEupHeadboard': instance.originalEupHeadboard,
      'originalEupSorong': instance.originalEupSorong,
      'discount1': instance.discount1,
      'discount2': instance.discount2,
      'discount3': instance.discount3,
      'discount4': instance.discount4,
      'bonusSnapshots': instance.bonusSnapshots,
      'indirectStoreAddressNumber': instance.indirectStoreAddressNumber,
      'indirectStoreAlphaName': instance.indirectStoreAlphaName,
      'indirectStoreAddress': instance.indirectStoreAddress,
      'indirectStorePhone': instance.indirectStorePhone,
      'indirectStoreDiscounts': instance.indirectStoreDiscounts,
      'indirectStoreDiscountDisplay': instance.indirectStoreDiscountDisplay,
      'isFocVoucher': instance.isFocVoucher,
    };
