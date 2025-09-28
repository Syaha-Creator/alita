class OrderLetterDocumentModel {
  final int id;
  final String noSp;
  final String status;
  final String creator;
  final String createdAt;
  final String updatedAt;
  final String customerName;
  final String phone;
  final String address;
  final String addressShipTo;
  final String shipToName;
  final double extendedAmount;
  final double hargaAwal;
  final String email;
  final String note;
  final List<OrderLetterDetailModel> details;
  final List<OrderLetterDiscountModel> discounts;
  final List<OrderLetterApproveModel> approvals;
  final List<OrderLetterContactModel> contacts;

  OrderLetterDocumentModel({
    required this.id,
    required this.noSp,
    required this.status,
    required this.creator,
    required this.createdAt,
    required this.updatedAt,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.addressShipTo,
    required this.shipToName,
    required this.email,
    required this.note,
    required this.extendedAmount,
    required this.hargaAwal,
    required this.details,
    required this.discounts,
    required this.approvals,
    required this.contacts,
  });

  factory OrderLetterDocumentModel.fromJson(Map<String, dynamic> json) {
    return OrderLetterDocumentModel(
      id: json['id'] ?? 0,
      noSp: json['no_sp'] ?? '',
      status: json['status'] ?? '',
      creator: json['creator'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      customerName: json['customer_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      addressShipTo: json['address_ship_to'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      email: json['email'] ?? '',
      note: json['note'] ?? '',
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
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'address_ship_to': addressShipTo,
      'ship_to_name': shipToName,
      'email': email,
      'note': note,
      'extended_amount': extendedAmount,
      'harga_awal': hargaAwal,
      'details': details.map((detail) => detail.toJson()).toList(),
      'discounts': discounts.map((discount) => discount.toJson()).toList(),
      'approvals': approvals.map((approval) => approval.toJson()).toList(),
      'contacts': contacts.map((contact) => contact.toJson()).toList(),
    };
  }
}

class OrderLetterDetailModel {
  final int id;
  final int orderLetterId;
  final String noSp;
  final int qty;
  final double unitPrice;
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

    return OrderLetterDetailModel(
      id: json['order_letter_detail_id'] ?? json['id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      noSp: json['no_sp'] ?? '',
      qty: qtyValue,
      unitPrice: unitPriceValue,
      itemNumber: json['item_number'] ?? '',
      desc1: json['desc_1'] ?? '',
      desc2: json['desc_2'] ?? '',
      brand: json['brand'] ?? '',
      itemType: json['item_type'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      takeAway: json['take_away'] == null ? null : json['take_away'] as bool?,
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
      approvedAt = json['approved_at'];
    } else if (approvedValue == 'false' ||
        approvedValue == false ||
        approvedValue == 'Rejected') {
      approved = false;
      approvedAt = json['approved_at'];
    } else if (approvedValue == 'Pending') {
      approved = null;
      approvedAt = null;
    } else {
      approved = null;
      approvedAt = null;
    }

    return OrderLetterDiscountModel(
      id: json['order_letter_discount_id'] ?? 0,
      orderLetterDetailId: json['order_letter_detail_id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      discount: discountValue,
      approver: json['approver'],
      approverName: json['approver_name'],
      approverLevelId: json['approver_level_id'],
      approverLevel: json['approver_level'],
      approverWorkTitle: json['approver_work_title'],
      approved: approved,
      approvedAt: approvedAt,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_letter_contact_id': orderLetterContactId,
      'phone': phone,
    };
  }
}
