import '../../../../core/utils/validators.dart';

/// Entity untuk order letter detail data
/// 
/// Represents data yang diperlukan untuk create order letter detail
class OrderLetterDetailDataEntity {
  final String? itemNumber;
  final String? itemDescription;
  final String desc1;
  final String desc2;
  final String brand;
  final double unitPrice;
  final double? customerPrice;
  final double netPrice;
  final int qty;
  final String itemType;
  final String? takeAway;
  final int? orderLetterId;
  final String? noSp;

  OrderLetterDetailDataEntity({
    this.itemNumber,
    this.itemDescription,
    required this.desc1,
    required this.desc2,
    required this.brand,
    required this.unitPrice,
    this.customerPrice,
    required this.netPrice,
    required this.qty,
    required this.itemType,
    this.takeAway,
    this.orderLetterId,
    this.noSp,
  }) {
    // Validate required fields
    Validators.validateRequired(desc1, 'Desc 1');
    Validators.validateRequired(desc2, 'Desc 2');
    Validators.validateRequired(brand, 'Brand');
    Validators.validateNonNegative(unitPrice, 'Unit price');
    if (customerPrice != null) {
      Validators.validateNonNegative(customerPrice!, 'Customer price');
    }
    Validators.validateNonNegative(netPrice, 'Net price');
    Validators.validatePositive(qty, 'Quantity');
    Validators.validateRequired(itemType, 'Item type');
    if (orderLetterId != null) {
      Validators.validatePositive(orderLetterId!, 'Order letter ID');
    }
  }

  /// Convert to Map untuk API request
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'desc_1': desc1,
      'desc_2': desc2,
      'brand': brand,
      'unit_price': unitPrice,
      'net_price': netPrice,
      'qty': qty,
      'item_type': itemType,
    };

    if (itemNumber != null) {
      map['item_number'] = itemNumber;
    }
    if (itemDescription != null) {
      map['item_description'] = itemDescription;
    }
    if (customerPrice != null) {
      map['customer_price'] = customerPrice;
    }
    if (takeAway != null) {
      map['take_away'] = takeAway;
    }
    if (orderLetterId != null) {
      map['order_letter_id'] = orderLetterId;
    }
    if (noSp != null) {
      map['no_sp'] = noSp;
    }

    return map;
  }

  /// Create from Map (untuk backward compatibility)
  factory OrderLetterDetailDataEntity.fromMap(Map<String, dynamic> map) {
    return OrderLetterDetailDataEntity(
      itemNumber: map['item_number'] as String?,
      itemDescription: map['item_description'] as String?,
      desc1: map['desc_1'] as String? ?? '',
      desc2: map['desc_2'] as String? ?? '',
      brand: map['brand'] as String? ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      customerPrice: (map['customer_price'] as num?)?.toDouble(),
      netPrice: (map['net_price'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      itemType: map['item_type'] as String? ?? '',
      takeAway: map['take_away'] as String?,
      orderLetterId: (map['order_letter_id'] as num?)?.toInt(),
      noSp: map['no_sp'] as String?,
    );
  }

  /// Create copy with updated order letter ID and no_sp
  OrderLetterDetailDataEntity copyWith({
    int? orderLetterId,
    String? noSp,
  }) {
    return OrderLetterDetailDataEntity(
      itemNumber: itemNumber,
      itemDescription: itemDescription,
      desc1: desc1,
      desc2: desc2,
      brand: brand,
      unitPrice: unitPrice,
      customerPrice: customerPrice,
      netPrice: netPrice,
      qty: qty,
      itemType: itemType,
      takeAway: takeAway,
      orderLetterId: orderLetterId ?? this.orderLetterId,
      noSp: noSp ?? this.noSp,
    );
  }
}

