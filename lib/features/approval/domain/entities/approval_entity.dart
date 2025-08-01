class ApprovalEntity {
  final int id;
  final String noSp;
  final String orderDate;
  final String requestDate;
  final String creator;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String? shipToName;
  final String? addressShipTo;
  final double extendedAmount;
  final int hargaAwal;
  final double? discount;
  final String note;
  final String status;
  final String? keterangan;
  final List<ApprovalDetailEntity> details;
  final List<ApprovalDiscountEntity> discounts;
  final List<ApprovalHistoryEntity> approvalHistory;

  ApprovalEntity({
    required this.id,
    required this.noSp,
    required this.orderDate,
    required this.requestDate,
    required this.creator,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    this.shipToName,
    this.addressShipTo,
    required this.extendedAmount,
    required this.hargaAwal,
    this.discount,
    required this.note,
    required this.status,
    this.keterangan,
    required this.details,
    required this.discounts,
    required this.approvalHistory,
  });
}

class ApprovalDetailEntity {
  final int id;
  final String noSp;
  final String itemNumber;
  final String desc1;
  final String desc2;
  final String brand;
  final double unitPrice;
  final int qty;
  final String itemType;
  final int orderLetterId;

  ApprovalDetailEntity({
    required this.id,
    required this.noSp,
    required this.itemNumber,
    required this.desc1,
    required this.desc2,
    required this.brand,
    required this.unitPrice,
    required this.qty,
    required this.itemType,
    required this.orderLetterId,
  });
}

class ApprovalDiscountEntity {
  final int id;
  final int orderLetterId;
  final int? orderLetterDetailId;
  final double discount;

  ApprovalDiscountEntity({
    required this.id,
    required this.orderLetterId,
    this.orderLetterDetailId,
    required this.discount,
  });
}

class ApprovalHistoryEntity {
  final int id;
  final int orderLetterId;
  final String approverName;
  final String approverEmail;
  final String action; // approve/reject
  final String? comment;
  final String createdAt;

  ApprovalHistoryEntity({
    required this.id,
    required this.orderLetterId,
    required this.approverName,
    required this.approverEmail,
    required this.action,
    this.comment,
    required this.createdAt,
  });
}
