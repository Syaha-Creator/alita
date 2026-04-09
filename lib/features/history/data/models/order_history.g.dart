// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderHistoryImpl _$$OrderHistoryImplFromJson(Map<String, dynamic> json) =>
    _$OrderHistoryImpl(
      id: (json['id'] as num).toInt(),
      noSp: json['noSp'] as String,
      orderDate: json['orderDate'] as String,
      requestDate: json['requestDate'] as String,
      note: json['note'] as String,
      customerName: json['customerName'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      email: json['email'] as String,
      shipToName: json['shipToName'] as String? ?? '',
      addressShipTo: json['addressShipTo'] as String? ?? '',
      noPo: json['noPo'] as String?,
      channel: json['channel'] as String?,
      isTakeAway: json['isTakeAway'] as bool,
      workPlaceName: json['workPlaceName'] as String,
      companyName: json['companyName'] as String,
      totalAmount: _parseDouble(json['totalAmount']),
      postage: json['postage'] == null ? 0 : _parseDouble(json['postage']),
      status: json['status'] as String,
      creator: json['creator'] as String? ?? '',
      creatorName: json['creatorName'] as String? ?? '',
      salesCode: json['salesCode'] as String? ?? '',
      salesName: json['salesName'] as String? ?? '',
      details: (json['details'] as List<dynamic>?)
              ?.map((e) => OrderDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderDetail>[],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => OrderPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderPayment>[],
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      orderLetterContacts: json['order_letter_contacts'] == null
          ? const <Map<String, dynamic>>[]
          : _orderLetterContactsFromJson(json['order_letter_contacts']),
    );

Map<String, dynamic> _$$OrderHistoryImplToJson(_$OrderHistoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noSp': instance.noSp,
      'orderDate': instance.orderDate,
      'requestDate': instance.requestDate,
      'note': instance.note,
      'customerName': instance.customerName,
      'phone': instance.phone,
      'address': instance.address,
      'email': instance.email,
      'shipToName': instance.shipToName,
      'addressShipTo': instance.addressShipTo,
      'noPo': instance.noPo,
      'channel': instance.channel,
      'isTakeAway': instance.isTakeAway,
      'workPlaceName': instance.workPlaceName,
      'companyName': instance.companyName,
      'totalAmount': instance.totalAmount,
      'postage': instance.postage,
      'status': instance.status,
      'creator': instance.creator,
      'creatorName': instance.creatorName,
      'salesCode': instance.salesCode,
      'salesName': instance.salesName,
      'details': instance.details,
      'payments': instance.payments,
      'createdAt': instance.createdAt?.toIso8601String(),
      'order_letter_contacts':
          _orderLetterContactsToJson(instance.orderLetterContacts),
    };

_$OrderDetailImpl _$$OrderDetailImplFromJson(Map<String, dynamic> json) =>
    _$OrderDetailImpl(
      id: (json['id'] as num).toInt(),
      noSp: json['noSp'] as String? ?? '-',
      itemDescription: json['itemDescription'] as String,
      desc1: json['desc1'] as String,
      desc2: json['desc2'] as String? ?? '',
      itemType: json['itemType'] as String,
      qty: (json['qty'] as num).toInt(),
      customerPrice: _parseDouble(json['customerPrice']),
      netPrice: _parseDouble(json['netPrice']),
      brand: json['brand'] as String,
      unitPrice: _parseDouble(json['unitPrice']),
      extendedPrice: json['extendedPrice'] == null
          ? 0
          : _parseDouble(json['extendedPrice']),
      discounts: (json['discounts'] as List<dynamic>?)
              ?.map((e) => OrderDiscount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderDiscount>[],
      isTakeAway: json['isTakeAway'] as bool? ?? false,
    );

Map<String, dynamic> _$$OrderDetailImplToJson(_$OrderDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'noSp': instance.noSp,
      'itemDescription': instance.itemDescription,
      'desc1': instance.desc1,
      'desc2': instance.desc2,
      'itemType': instance.itemType,
      'qty': instance.qty,
      'customerPrice': instance.customerPrice,
      'netPrice': instance.netPrice,
      'brand': instance.brand,
      'unitPrice': instance.unitPrice,
      'extendedPrice': instance.extendedPrice,
      'discounts': instance.discounts,
      'isTakeAway': instance.isTakeAway,
    };

_$OrderDiscountImpl _$$OrderDiscountImplFromJson(Map<String, dynamic> json) =>
    _$OrderDiscountImpl(
      id: (json['id'] as num).toInt(),
      discountVal: json['discountVal'] as String,
      approverName: json['approverName'] as String,
      approverLevel: json['approverLevel'] as String,
      approverId: json['approverId'] as String?,
      approvedStatus: json['approvedStatus'] as String,
      approvedAt: json['approvedAt'] as String?,
    );

Map<String, dynamic> _$$OrderDiscountImplToJson(_$OrderDiscountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'discountVal': instance.discountVal,
      'approverName': instance.approverName,
      'approverLevel': instance.approverLevel,
      'approverId': instance.approverId,
      'approvedStatus': instance.approvedStatus,
      'approvedAt': instance.approvedAt,
    };

_$OrderPaymentImpl _$$OrderPaymentImplFromJson(Map<String, dynamic> json) =>
    _$OrderPaymentImpl(
      method: json['method'] as String,
      bank: json['bank'] as String,
      amount: _parseDouble(json['amount']),
      image: json['image'] as String,
      paymentDate: json['paymentDate'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );

Map<String, dynamic> _$$OrderPaymentImplToJson(_$OrderPaymentImpl instance) =>
    <String, dynamic>{
      'method': instance.method,
      'bank': instance.bank,
      'amount': instance.amount,
      'image': instance.image,
      'paymentDate': instance.paymentDate,
      'createdAt': instance.createdAt,
    };
