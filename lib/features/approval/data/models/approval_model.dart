import '../../domain/entities/approval_entity.dart';

class ApprovalModel extends ApprovalEntity {
  ApprovalModel({
    required super.id,
    required super.noSp,
    required super.orderDate,
    required super.requestDate,
    required super.creator,
    required super.customerName,
    required super.phone,
    required super.email,
    required super.address,
    super.shipToName,
    super.addressShipTo,
    required super.extendedAmount,
    required super.hargaAwal,
    super.discount,
    required super.note,
    required super.status,
    super.keterangan,
    super.createdAt,
    required super.details,
    required super.discounts,
    required super.approvalHistory,
    super.takeAway,
    super.postage,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id'] ?? 0,
      noSp: json['no_sp'] ?? '',
      orderDate: json['order_date'] ?? '',
      requestDate: json['request_date'] ?? '',
      creator: json['creator'] ?? '',
      customerName: json['customer_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      shipToName: json['ship_to_name'],
      addressShipTo: json['address_ship_to'],
      extendedAmount:
          double.tryParse(json['extended_amount'].toString()) ?? 0.0,
      hargaAwal: json['harga_awal'] ?? 0,
      discount: json['discount'] != null
          ? double.tryParse(json['discount'].toString())
          : null,
      note: json['note'] ?? '',
      status: json['status'] ?? '',
      keterangan: json['keterangan'],
      createdAt: json['created_at'],
      details: json['details'] != null
          ? (json['details'] as List)
              .map((detail) => ApprovalDetailModel.fromJson(detail))
              .toList()
          : [],
      discounts: json['discounts'] != null
          ? (json['discounts'] as List)
              .map((discount) => ApprovalDiscountModel.fromJson(discount))
              .toList()
          : [],
      approvalHistory: json['approval_history'] != null
          ? (json['approval_history'] as List)
              .map((history) => ApprovalHistoryModel.fromJson(history))
              .toList()
          : [],
      takeAway: json['take_away'] is bool
          ? json['take_away'] as bool
          : (json['take_away'] == 'true' || json['take_away'] == true),
      postage: json['postage'] != null
          ? double.tryParse(json['postage'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_sp': noSp,
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
      'keterangan': keterangan,
      'created_at': createdAt,
      'details': details
          .map((detail) => (detail as ApprovalDetailModel).toJson())
          .toList(),
      'discounts': discounts
          .map((discount) => (discount as ApprovalDiscountModel).toJson())
          .toList(),
      'approval_history': approvalHistory
          .map((history) => (history as ApprovalHistoryModel).toJson())
          .toList(),
    };
  }
}

class ApprovalDetailModel extends ApprovalDetailEntity {
  ApprovalDetailModel({
    required super.id,
    required super.noSp,
    required super.itemNumber,
    required super.desc1,
    required super.desc2,
    required super.brand,
    required super.unitPrice,
    required super.qty,
    required super.itemType,
    required super.orderLetterId,
  });

  factory ApprovalDetailModel.fromJson(Map<String, dynamic> json) {
    return ApprovalDetailModel(
      id: json['id'] ?? 0,
      noSp: json['no_sp'] ?? '',
      itemNumber: json['item_number'] ?? '',
      desc1: json['desc_1'] ?? '',
      desc2: json['desc_2'] ?? '',
      brand: json['brand'] ?? '',
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      qty: json['qty'] ?? 0,
      itemType: json['item_type'] ?? '',
      orderLetterId: json['order_letter_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'no_sp': noSp,
      'item_number': itemNumber,
      'desc_1': desc1,
      'desc_2': desc2,
      'brand': brand,
      'unit_price': unitPrice,
      'qty': qty,
      'item_type': itemType,
      'order_letter_id': orderLetterId,
    };
  }
}

class ApprovalDiscountModel extends ApprovalDiscountEntity {
  ApprovalDiscountModel({
    required super.id,
    required super.orderLetterId,
    super.orderLetterDetailId,
    required super.discount,
  });

  factory ApprovalDiscountModel.fromJson(Map<String, dynamic> json) {
    return ApprovalDiscountModel(
      id: json['id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      orderLetterDetailId: json['order_letter_detail_id'],
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_letter_id': orderLetterId,
      'order_letter_detail_id': orderLetterDetailId,
      'discount': discount,
    };
  }
}

class ApprovalHistoryModel extends ApprovalHistoryEntity {
  ApprovalHistoryModel({
    required super.id,
    required super.orderLetterId,
    required super.approverName,
    required super.approverEmail,
    required super.action,
    super.comment,
    required super.createdAt,
  });

  factory ApprovalHistoryModel.fromJson(Map<String, dynamic> json) {
    return ApprovalHistoryModel(
      id: json['id'] ?? 0,
      orderLetterId: json['order_letter_id'] ?? 0,
      approverName: json['approver_name'] ?? '',
      approverEmail: json['approver_email'] ?? '',
      action: json['action'] ?? '',
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_letter_id': orderLetterId,
      'approver_name': approverName,
      'approver_email': approverEmail,
      'action': action,
      'comment': comment,
      'created_at': createdAt,
    };
  }
}

class LeaderModel {
  final int id;
  final String fullName;
  final String workTitle;
  final int? jobLevel;
  final String? jobLevelName;

  LeaderModel({
    required this.id,
    required this.fullName,
    required this.workTitle,
    this.jobLevel,
    this.jobLevelName,
  });

  factory LeaderModel.fromJson(Map<String, dynamic> json) {
    return LeaderModel(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      workTitle: json['work_title'] ?? '',
      jobLevel: json['job_level'],
      jobLevelName: json['job_level_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'work_title': workTitle,
      'job_level': jobLevel,
      'job_level_name': jobLevelName,
    };
  }

  @override
  String toString() {
    return 'LeaderModel{id: $id, fullName: "$fullName", workTitle: "$workTitle", jobLevel: $jobLevel, jobLevelName: "$jobLevelName"}';
  }
}

class LeaderByUserModel {
  final LeaderModel user;
  final LeaderModel? directLeader;
  final LeaderModel? indirectLeader;
  final LeaderModel? controller;
  final LeaderModel? analyst;

  LeaderByUserModel({
    required this.user,
    this.directLeader,
    this.indirectLeader,
    this.controller,
    this.analyst,
  });

  factory LeaderByUserModel.fromJson(Map<String, dynamic> json) {
    return LeaderByUserModel(
      user: LeaderModel.fromJson(json['user'] ?? {}),
      directLeader: json['direct_leader'] != null
          ? LeaderModel.fromJson(json['direct_leader'])
          : null,
      indirectLeader: json['indirect_leader'] != null
          ? LeaderModel.fromJson(json['indirect_leader'])
          : null,
      controller: json['controller'] != null
          ? LeaderModel.fromJson(json['controller'])
          : null,
      analyst: json['analyst'] != null
          ? LeaderModel.fromJson(json['analyst'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'direct_leader': directLeader?.toJson(),
      'indirect_leader': indirectLeader?.toJson(),
      'controller': controller?.toJson(),
      'analyst': analyst?.toJson(),
    };
  }

  @override
  String toString() {
    return 'LeaderByUserModel{user: $user, directLeader: $directLeader, indirectLeader: $indirectLeader, controller: $controller, analyst: $analyst}';
  }
}
