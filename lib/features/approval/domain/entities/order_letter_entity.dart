import 'package:equatable/equatable.dart';

class OrderLetterEntity extends Equatable {
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

  const OrderLetterEntity({
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
