class OrderLetterDocumentModel {
  final int id;
  final String noSp;
  final String status;
  final String creator;
  final String createdAt;
  final String updatedAt;
  final String orderDate;
  final String requestDate;
  final String customerName;
  final String phone;
  final String address;
  final String addressShipTo;
  final String shipToName;
  final double extendedAmount;
  final double hargaAwal;
  final String email;
  final String note;
  final String? spgCode;
  final String? workPlaceName;
  final String? workPlaceAddress;
  final bool? takeAway; // Boolean (global untuk semua items)
  final double? postage;
  final List<OrderLetterDetailModel> details;
  final List<OrderLetterDiscountModel> discounts;
  final List<OrderLetterApproveModel> approvals;
  final List<OrderLetterContactModel> contacts;
  final List<OrderLetterPaymentModel> payments;

  OrderLetterDocumentModel({
    required this.id,
    required this.noSp,
    required this.status,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    required this.orderDate,
    required this.requestDate,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.addressShipTo,
    required this.shipToName,
    required this.email,
    required this.note,
    this.spgCode,
    this.workPlaceName,
    this.workPlaceAddress,
    this.takeAway,
    this.postage,
    required this.extendedAmount,
    required this.hargaAwal,
    required this.details,
    required this.discounts,
    required this.approvals,
    required this.contacts,
    required this.payments,
  });

  /// Helper method to parse take_away field from various formats
  static bool? _parseTakeAway(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' ||
          lowerValue == 'take away' ||
          lowerValue == '1') {
        return true;
      } else if (lowerValue == 'false' || lowerValue == '0') {
        return false;
      }
    }
    return null;
  }

  /// Helper method to safely convert value to String
  static String _toString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Helper method to safely convert value to nullable String
  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  factory OrderLetterDocumentModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterDocumentModel(
      id: json['id'] ?? 0,
      noSp: _toString(json['no_sp']),
      status: _toString(json['status']),
      creator: _toString(json['creator']),
      createdAt: _toString(json['created_at']),
      updatedAt: _toString(json['updated_at']),
      orderDate: _toString(json['order_date']),
      requestDate: _toString(json['request_date']),
      customerName: _toString(json['customer_name']),
      phone: _toString(json['phone']),
      address: _toString(json['address']),
      addressShipTo: _toString(json['address_ship_to']),
      shipToName: _toString(json['ship_to_name']),
      email: _toString(json['email']),
      note: _toString(json['note']),
      spgCode: _toNullableString(json['sales_code']),
      workPlaceName: _toNullableString(json['work_place_name']),
      workPlaceAddress: _toNullableString(json['work_place_address']),
      takeAway: _parseTakeAway(json['take_away']),
      postage: json['postage'] != null
          ? double.tryParse(json['postage'].toString())
          : null,
      extendedAmount:
          double.tryParse(json['extended_amount']?.toString() ?? '0.0') ?? 0.0,
      hargaAwal:
          double.tryParse(json['harga_awal']?.toString() ?? '0.0') ?? 0.0,
      details: (json['details'] as List<dynamic>?)
              ?.map((detail) => OrderLetterDetailModel.fromJson(detail))
              .toList() ??
          [],
      discounts: (json['discounts'] as List<dynamic>?)
              ?.map((discount) => OrderLetterDiscountModel.fromJson(discount))
              .toList() ??
          [],
      approvals: (json['approvals'] as List<dynamic>?)
              ?.map((approval) => OrderLetterApproveModel.fromJson(approval))
              .toList() ??
          [],
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((contact) => OrderLetterContactModel.fromJson(contact))
              .toList() ??
          [],
      payments: (json['payments'] as List<dynamic>?)
              ?.map((payment) => OrderLetterPaymentModel.fromJson(payment))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_sp': noSp,
      'status': status,
      'creator': creator,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'order_date': orderDate,
      'request_date': requestDate,
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'address_ship_to': addressShipTo,
      'ship_to_name': shipToName,
      'email': email,
      'note': note,
      'take_away': takeAway,
      'postage': postage,
      'extended_amount': extendedAmount,
      'harga_awal': hargaAwal,
      'details': details.map((detail) => detail.toJson()).toList(),
      'discounts': discounts.map((discount) => discount.toJson()).toList(),
      'approvals': approvals.map((approval) => approval.toJson()).toList(),
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }
}

class OrderLetterDetailModel {
  final int id;
  final int orderLetterId;
  final String noSp;
  final int qty;
  final double unitPrice; // Pricelist (harga asli)
  final double? netPrice; // Harga setelah discount (nullable)
  final double? customerPrice;
  final String itemNumber;
  final String desc1;
  final String desc2;
  final String brand;
  final String itemType;
  final String status;
  final String createdAt;
  final String updatedAt;
  final bool? takeAway;
  final List<OrderLetterDiscountModel> discounts;

  OrderLetterDetailModel({
    required this.id,
    required this.orderLetterId,
    required this.noSp,
    required this.qty,
    required this.unitPrice,
    required this.netPrice,
    required this.customerPrice,
    required this.itemNumber,
    required this.desc1,
    required this.desc2,
    required this.brand,
    required this.itemType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.takeAway,
    required this.discounts,
  });

  /// Helper method to parse take_away field from various formats
  static bool? _parseTakeAway(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      if (lowerValue == 'true' ||
          lowerValue == 'take away' ||
          lowerValue == '1') {
        return true;
      } else if (lowerValue == 'false' || lowerValue == '0') {
        return false;
      }
    }
    return null;
  }

  factory OrderLetterDetailModel.fromJson(Map<String, dynamic> json) {
    // Handle unit_price field that can be string or number
    double unitPriceValue = 0.0;
    final unitPriceData = json['unit_price'];
    if (unitPriceData != null) {
      if (unitPriceData is String) {
        unitPriceValue = double.tryParse(unitPriceData) ?? 0.0;
      } else if (unitPriceData is num) {
        unitPriceValue = unitPriceData.toDouble();
      }
    }

    // Handle qty field that can be string or number
    int qtyValue = 0;
    final qtyData = json['qty'];
    if (qtyData != null) {
      if (qtyData is String) {
        qtyValue = int.tryParse(qtyData) ?? 0;
      } else if (qtyData is num) {
        qtyValue = qtyData.toInt();
      }
    }

    // Extract discounts from the nested order_letter_discount array
    final List<OrderLetterDiscountModel> discounts = [];
    final discountData = json['order_letter_discount'] as List<dynamic>?;
    if (discountData != null) {
      for (final discountJson in discountData) {
        // Add the order_letter_detail_id to the discount for proper mapping
        final discountWithDetailId = Map<String, dynamic>.from(discountJson);
        discountWithDetailId['order_letter_detail_id'] =
            json['order_letter_detail_id'] ?? json['id'] ?? 0;
        discounts.add(OrderLetterDiscountModel.fromJson(discountWithDetailId));
      }
    }

    // Handle net_price field that can be string or number
    double? netPriceValue;
    final netPriceData = json['net_price'];
    if (netPriceData != null) {
      if (netPriceData is String) {
        netPriceValue = double.tryParse(netPriceData);
      } else if (netPriceData is num) {
        netPriceValue = netPriceData.toDouble();
      }
    }

    double? customerPriceValue;
    final customerPriceData = json['customer_price'];
    if (customerPriceData != null) {
      if (customerPriceData is String) {
        customerPriceValue = double.tryParse(customerPriceData);
      } else if (customerPriceData is num) {
        customerPriceValue = customerPriceData.toDouble();
      }
    }

    return OrderLetterDetailModel(
      id: json['order_letter_detail_id'] ?? json['id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      noSp: OrderLetterDocumentModel._toString(json['no_sp']),
      qty: qtyValue,
      unitPrice: unitPriceValue,
      netPrice: netPriceValue,
      customerPrice: customerPriceValue,
      itemNumber: OrderLetterDocumentModel._toString(json['item_number']),
      desc1: OrderLetterDocumentModel._toString(json['desc_1']),
      desc2: OrderLetterDocumentModel._toString(json['desc_2']),
      brand: OrderLetterDocumentModel._toString(json['brand']),
      itemType: OrderLetterDocumentModel._toString(json['item_type']),
      status: OrderLetterDocumentModel._toString(json['status']),
      createdAt: OrderLetterDocumentModel._toString(json['created_at']),
      updatedAt: OrderLetterDocumentModel._toString(json['updated_at']),
      takeAway: _parseTakeAway(json['take_away']),
      discounts: discounts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_letter_id': orderLetterId,
      'no_sp': noSp,
      'qty': qty,
      'unit_price': unitPrice,
      'net_price': netPrice,
      'customer_price': customerPrice,
      'item_number': itemNumber,
      'desc_1': desc1,
      'desc_2': desc2,
      'brand': brand,
      'item_type': itemType,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'take_away': takeAway,
      'order_letter_discount':
          discounts.map((discount) => discount.toJson()).toList(),
    };
  }
}

class OrderLetterDiscountModel {
  final int id;
  final int orderLetterDetailId;
  final int orderLetterId;
  final double discount;
  final int? approver;
  final String? approverName;
  final int? approverLevelId;
  final String? approverLevel;
  final String? approverWorkTitle;
  final bool? approved;
  final String? approvedAt;
  final String createdAt;
  final String updatedAt;

  OrderLetterDiscountModel({
    required this.id,
    required this.orderLetterDetailId,
    required this.orderLetterId,
    required this.discount,
    this.approver,
    this.approverName,
    this.approverLevelId,
    this.approverLevel,
    this.approverWorkTitle,
    this.approved,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderLetterDiscountModel.fromJson(Map<String, dynamic> json) {
    // Handle discount field that can be string or number
    double discountValue = 0.0;
    final discountData = json['discount'];
    if (discountData != null) {
      if (discountData is String) {
        discountValue = double.tryParse(discountData) ?? 0.0;
      } else if (discountData is num) {
        discountValue = discountData.toDouble();
      }
    }
    // Handle approved field that can be string, boolean, or null
    bool? approved;
    String? approvedAt;

    final approvedValue = json['approved'];
    if (approvedValue == null) {
      approved = null;
      approvedAt = null;
    } else if (approvedValue == 'true' ||
        approvedValue == true ||
        approvedValue == 'Approved') {
      approved = true;
      approvedAt =
          OrderLetterDocumentModel._toNullableString(json['approved_at']);
    } else if (approvedValue == 'false' ||
        approvedValue == false ||
        approvedValue == 'Rejected') {
      approved = false;
      approvedAt =
          OrderLetterDocumentModel._toNullableString(json['approved_at']);
    } else if (approvedValue == 'Pending') {
      approved = null;
      approvedAt = null;
    } else {
      approved = null;
      approvedAt = null;
    }

    return OrderLetterDiscountModel(
      id: json['order_letter_discount_id'] ?? json['id'] ?? 0,
      orderLetterDetailId: json['order_letter_detail_id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      discount: discountValue,
      approver: json['approver'],
      approverName:
          OrderLetterDocumentModel._toNullableString(json['approver_name']),
      approverLevelId: json['approver_level_id'],
      approverLevel:
          OrderLetterDocumentModel._toNullableString(json['approver_level']),
      approverWorkTitle: OrderLetterDocumentModel._toNullableString(
          json['approver_work_title']),
      approved: approved,
      approvedAt: OrderLetterDocumentModel._toNullableString(approvedAt),
      createdAt: OrderLetterDocumentModel._toString(json['created_at']),
      updatedAt: OrderLetterDocumentModel._toString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_letter_detail_id': orderLetterDetailId,
      'order_letter_id': orderLetterId,
      'discount': discount,
      'approver': approver,
      'approver_name': approverName,
      'approver_level_id': approverLevelId,
      'approver_level': approverLevel,
      'approver_work_title': approverWorkTitle,
      'approved': approved,
      'approved_at': approvedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class OrderLetterApproveModel {
  final int id;
  final int orderLetterDiscountId;
  final int leader;
  final int jobLevelId;
  final String createdAt;
  final String updatedAt;

  OrderLetterApproveModel({
    required this.id,
    required this.orderLetterDiscountId,
    required this.leader,
    required this.jobLevelId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderLetterApproveModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterApproveModel(
      id: json['id'] ?? 0,
      orderLetterDiscountId: json['order_letter_discount_id'] ?? 0,
      leader: json['leader'] ?? 0,
      jobLevelId: json['job_level_id'] ?? 0,
      createdAt: OrderLetterDocumentModel._toString(json['created_at']),
      updatedAt: OrderLetterDocumentModel._toString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_letter_discount_id': orderLetterDiscountId,
      'leader': leader,
      'job_level_id': jobLevelId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class OrderLetterContactModel {
  final int orderLetterContactId;
  final String phone;

  OrderLetterContactModel({
    required this.orderLetterContactId,
    required this.phone,
  });

  factory OrderLetterContactModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterContactModel(
      orderLetterContactId: json['order_letter_contact_id'] ?? 0,
      phone: OrderLetterDocumentModel._toString(json['phone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_letter_contact_id': orderLetterContactId,
      'phone': phone,
    };
  }
}

class OrderLetterPaymentModel {
  final int orderLetterPaymentId;
  final String paymentMethod;
  final String? paymentBank;
  final String? paymentNumber;
  final double paymentAmount;
  final String? paymentDate;
  final String? verified;
  final String? verifiedAt;
  final int? verifiedBy;
  final String? verifiedNote;
  final String? note;
  final String? image;
  final String createdAt;
  final int createdBy;
  final String updatedAt;
  final int? updatedBy;

  OrderLetterPaymentModel({
    required this.orderLetterPaymentId,
    required this.paymentMethod,
    this.paymentBank,
    this.paymentNumber,
    required this.paymentAmount,
    this.paymentDate,
    this.verified,
    this.verifiedAt,
    this.verifiedBy,
    this.verifiedNote,
    this.note,
    this.image,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    this.updatedBy,
  });

  factory OrderLetterPaymentModel.fromJson(Map<String, dynamic> json) {
    // Handle payment_amount field that can be string or number
    double paymentAmountValue = 0.0;
    final paymentAmountData = json['payment_amount'];
    if (paymentAmountData != null) {
      if (paymentAmountData is String) {
        paymentAmountValue = double.tryParse(paymentAmountData) ?? 0.0;
      } else if (paymentAmountData is num) {
        paymentAmountValue = paymentAmountData.toDouble();
      }
    }

    return OrderLetterPaymentModel(
      orderLetterPaymentId: json['order_letter_payment_id'] ?? 0,
      paymentMethod: OrderLetterDocumentModel._toString(json['payment_method']),
      paymentBank:
          OrderLetterDocumentModel._toNullableString(json['payment_bank']),
      paymentNumber:
          OrderLetterDocumentModel._toNullableString(json['payment_number']),
      paymentAmount: paymentAmountValue,
      paymentDate:
          OrderLetterDocumentModel._toNullableString(json['payment_date']),
      verified: OrderLetterDocumentModel._toNullableString(json['verified']),
      verifiedAt:
          OrderLetterDocumentModel._toNullableString(json['verified_at']),
      verifiedBy: json['verified_by'],
      verifiedNote:
          OrderLetterDocumentModel._toNullableString(json['verified_note']),
      note: OrderLetterDocumentModel._toNullableString(json['note']),
      image: OrderLetterDocumentModel._toNullableString(json['image']),
      createdAt: OrderLetterDocumentModel._toString(json['created_at']),
      createdBy: json['created_by'] ?? 0,
      updatedAt: OrderLetterDocumentModel._toString(json['updated_at']),
      updatedBy: json['updated_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_letter_payment_id': orderLetterPaymentId,
      'payment_method': paymentMethod,
      'payment_bank': paymentBank,
      'payment_number': paymentNumber,
      'payment_amount': paymentAmount.toString(),
      'payment_date': paymentDate,
      'verified': verified,
      'verified_at': verifiedAt,
      'verified_by': verifiedBy,
      'verified_note': verifiedNote,
      'note': note,
      'image': image,
      'created_at': createdAt,
      'created_by': createdBy,
      'updated_at': updatedAt,
      'updated_by': updatedBy,
    };
  }
}
