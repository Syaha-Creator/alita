import '../../../../core/utils/validators.dart';

/// Entity untuk order letter data
/// 
/// Represents data yang diperlukan untuk create order letter
class OrderLetterDataEntity {
  final String orderDate;
  final String requestDate;
  final String creator;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String shipToName;
  final String addressShipTo;
  final double extendedAmount;
  final int hargaAwal;
  final double discount;
  final String note;
  final String status;
  final String salesCode;
  final int workPlaceId;
  final bool takeAway;
  final double postage;
  final String? channel;

  OrderLetterDataEntity({
    required this.orderDate,
    required this.requestDate,
    required this.creator,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.shipToName,
    required this.addressShipTo,
    required this.extendedAmount,
    required this.hargaAwal,
    required this.discount,
    required this.note,
    required this.status,
    required this.salesCode,
    required this.workPlaceId,
    required this.takeAway,
    required this.postage,
    this.channel,
    bool skipPhoneEmailValidation = false, // For indirect checkout
  }) {
    // Validate required fields
    Validators.validateDateString(orderDate, 'Order date');
    Validators.validateDateString(requestDate, 'Request date');
    Validators.validateRequired(creator, 'Creator ID');
    Validators.validateRequired(customerName, 'Customer name');
    
    // Skip phone/email validation for indirect checkout (store data format may differ)
    if (!skipPhoneEmailValidation) {
      Validators.validatePhone(phone);
      Validators.validateEmail(email);
    }
    
    Validators.validateRequired(address, 'Customer address');
    Validators.validateRequired(shipToName, 'Ship to name');
    Validators.validateRequired(addressShipTo, 'Address ship to');
    Validators.validateNonNegative(extendedAmount, 'Extended amount');
    Validators.validateNonNegative(hargaAwal, 'Harga awal');
    Validators.validateNonNegative(discount, 'Discount');
    Validators.validateNonNegative(postage, 'Postage');
    Validators.validateNonNegative(workPlaceId, 'Work place ID');
    Validators.validateStringLength(customerName, 'Customer name', 2, 100);
    Validators.validateStringLength(note, 'Note', 0, 500);
  }

  /// Convert to Map untuk API request
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'order_date': orderDate,
      'request_date': requestDate,
      'creator': creator,
      'customer_name': customerName,
      'phone': phone,
      'email': email,
      'address': address,
      'ship_to_name': shipToName,
      'address_ship_to': addressShipTo,
      'extended_amount': extendedAmount,
      'harga_awal': hargaAwal,
      'discount': discount,
      'note': note,
      'status': status,
      'sales_code': salesCode,
      'work_place_id': workPlaceId,
      'take_away': takeAway,
      'postage': postage,
    };
    
    if (channel != null && channel!.isNotEmpty) {
      map['channel'] = channel;
    }
    
    return map;
  }

  /// Create from Map (untuk backward compatibility)
  factory OrderLetterDataEntity.fromMap(Map<String, dynamic> map) {
    return OrderLetterDataEntity(
      orderDate: map['order_date'] as String? ?? '',
      requestDate: map['request_date'] as String? ?? '',
      creator: map['creator'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      shipToName: map['ship_to_name'] as String? ?? '',
      addressShipTo: map['address_ship_to'] as String? ?? '',
      extendedAmount: (map['extended_amount'] as num?)?.toDouble() ?? 0.0,
      hargaAwal: (map['harga_awal'] as num?)?.toInt() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String? ?? '',
      status: map['status'] as String? ?? 'Pending',
      salesCode: map['sales_code'] as String? ?? '',
      workPlaceId: (map['work_place_id'] as num?)?.toInt() ?? 0,
      takeAway: map['take_away'] as bool? ?? false,
      postage: (map['postage'] as num?)?.toDouble() ?? 0.0,
      channel: map['channel'] as String?,
    );
  }
}
