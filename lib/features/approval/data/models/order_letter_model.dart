import 'package:equatable/equatable.dart';

class OrderLetterModel extends Equatable {
  final int? id;
  final String? noSp;
  final String? orderDate;
  final String? requestDate;
  final String? creator;
  final String? createdAt;
  final String? updatedAt;
  final String? note;
  final double? extendedAmount;
  final String? customerMaster;
  final String? customerName;
  final String? phone;
  final String? address;
  final String? addressShipTo;
  final String? shipToCode;
  final String? shipToName;
  final String? noPo;
  final String? discount;
  final String? discountDetail;
  final int? hargaAwal;
  final String? keterangan;
  final String? status;

  const OrderLetterModel({
    this.id,
    this.noSp,
    this.orderDate,
    this.requestDate,
    this.creator,
    this.createdAt,
    this.updatedAt,
    this.note,
    this.extendedAmount,
    this.customerMaster,
    this.customerName,
    this.phone,
    this.address,
    this.addressShipTo,
    this.shipToCode,
    this.shipToName,
    this.noPo,
    this.discount,
    this.discountDetail,
    this.hargaAwal,
    this.keterangan,
    this.status,
  });

  factory OrderLetterModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterModel(
      id: json['id'],
      noSp: json['no_sp'],
      orderDate: json['order_date'],
      requestDate: json['request_date'],
      creator: json['creator'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      note: json['note'],
      extendedAmount: json['extended_amount']?.toDouble(),
      customerMaster: json['customer_master'],
      customerName: json['customer_name'],
      phone: json['phone'],
      address: json['address'],
      addressShipTo: json['address_ship_to'],
      shipToCode: json['ship_to_code'],
      shipToName: json['ship_to_name'],
      noPo: json['no_po'],
      discount: json['discount']?.toString(),
      discountDetail: json['discount_detail'],
      hargaAwal: json['harga_awal'],
      keterangan: json['keterangan'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_date': orderDate,
      'creator': creator,
      'customer_name': customerName,
      'phone': phone,
      'discount': discount,
      'discount_detail': discountDetail,
      'harga_awal': hargaAwal,
      'keterangan': keterangan,
      'extended_amount': extendedAmount,
      'status': status ?? 'Pending',
    };
  }

  @override
  List<Object?> get props => [
        id,
        noSp,
        orderDate,
        requestDate,
        creator,
        createdAt,
        updatedAt,
        note,
        extendedAmount,
        customerMaster,
        customerName,
        phone,
        address,
        addressShipTo,
        shipToCode,
        shipToName,
        noPo,
        discount,
        discountDetail,
        hargaAwal,
        keterangan,
        status,
      ];
}
