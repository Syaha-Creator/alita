import 'package:equatable/equatable.dart';

class OrderLetterDetailModel extends Equatable {
  final int? id;
  final int? qty;
  final String? createdAt;
  final String? updatedAt;
  final int? orderLetterId;
  final String? noSp;
  final int? unitPrice;
  final String? itemNumber;
  final String? desc1;
  final String? desc2;
  final String? brand;
  final String? itemType;

  const OrderLetterDetailModel({
    this.id,
    this.qty,
    this.createdAt,
    this.updatedAt,
    this.orderLetterId,
    this.noSp,
    this.unitPrice,
    this.itemNumber,
    this.desc1,
    this.desc2,
    this.brand,
    this.itemType,
  });

  factory OrderLetterDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterDetailModel(
      id: json['id'],
      qty: json['qty'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      orderLetterId: json['order_letter_id'],
      noSp: json['no_sp'],
      unitPrice: json['unit_price'],
      itemNumber: json['item_number'],
      desc1: json['desc_1'],
      desc2: json['desc_2'],
      brand: json['brand'],
      itemType: json['item_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_letter_id': orderLetterId,
      'no_sp': noSp,
      'item_number': itemNumber,
      'desc_1': desc1,
      'desc_2': desc2,
      'brand': brand,
      'unit_price': unitPrice,
      'qty': qty,
    };
  }

  @override
  List<Object?> get props => [
        id,
        qty,
        createdAt,
        updatedAt,
        orderLetterId,
        noSp,
        unitPrice,
        itemNumber,
        desc1,
        desc2,
        brand,
        itemType,
      ];
}
