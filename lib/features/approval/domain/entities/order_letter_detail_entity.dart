import 'package:equatable/equatable.dart';

class OrderLetterDetailEntity extends Equatable {
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

  const OrderLetterDetailEntity({
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
