import 'package:alitapricelist/core/enums/order_status.dart';
import 'package:alitapricelist/core/utils/take_away_parse.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_history.freezed.dart';
part 'order_history.g.dart';

/// Safe String/num -> double converter for API fields that may arrive as
/// String ("14000000.0"), int, double, or null.
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

List<Map<String, dynamic>> _orderLetterContactsFromJson(dynamic json) {
  if (json is! List) return [];
  return json
      .map((e) => e is Map<String, dynamic>
          ? e
          : Map<String, dynamic>.from(e as Map))
      .toList();
}

dynamic _orderLetterContactsToJson(List<Map<String, dynamic>> v) => v;

/// Salin map dan satukan `take_away` / `isTakeAway` ke [isTakeAway] (bool) agar
/// [json_serializable] (kunci camel) tetap bekerja dengan payload API.
Map<String, dynamic> _orderHistoryJsonWithResolvedTakeAway(
  Map<String, dynamic> json,
) {
  final m = Map<String, dynamic>.from(json);
  m['isTakeAway'] = parseTakeAway(m['take_away'] ?? m['isTakeAway']);
  m.remove('take_away');
  return m;
}

Map<String, dynamic> _orderDetailJsonWithResolvedTakeAway(
  Map<String, dynamic> json,
) {
  final m = Map<String, dynamic>.from(json);
  m['isTakeAway'] = parseTakeAway(m['take_away'] ?? m['isTakeAway']);
  m.remove('take_away');
  return m;
}

@freezed
class OrderHistory with _$OrderHistory {
  const factory OrderHistory({
    required int id,
    required String noSp,
    required String orderDate,
    required String requestDate,
    required String note,
    required String customerName,
    required String phone,
    required String address,
    required String email,
    @Default('') String shipToName,
    @Default('') String addressShipTo,
    String? noPo,

    /// Channel order letter (mis. SO, S1, MM) — untuk PDF/layout khusus indirect.
    String? channel,
    required bool isTakeAway,
    required String workPlaceName,
    required String companyName,
    @JsonKey(fromJson: _parseDouble) required double totalAmount,
    @JsonKey(fromJson: _parseDouble) @Default(0) double postage,
    required String status,
    @Default('') String creator,
    @Default('') String creatorName,
    @Default('') String salesCode,
    @Default('') String salesName,
    @Default(<OrderDetail>[]) List<OrderDetail> details,
    @Default(<OrderPayment>[]) List<OrderPayment> payments,
    DateTime? createdAt,

    /// `order_letter_contacts` dari API: tiap item `phone`, `ship` (bool).
    @JsonKey(
      name: 'order_letter_contacts',
      fromJson: _orderLetterContactsFromJson,
      toJson: _orderLetterContactsToJson,
    )
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> orderLetterContacts,
  }) = _OrderHistory;

  factory OrderHistory.fromJson(Map<String, dynamic> json) =>
      _$OrderHistoryFromJson(_orderHistoryJsonWithResolvedTakeAway(json));

  factory OrderHistory.fromApiJson(Map<String, dynamic> json) {
    final letter = json['order_letter'] as Map<String, dynamic>? ?? json;
    final rawDetails = json['order_letter_details'] as List? ?? const [];
    final rawPayments = json['order_letter_payments'] as List? ?? const [];

    final parentNoSp = letter['no_sp']?.toString() ?? '-';

    // Inject parent no_sp into every raw detail map BEFORE parsing,
    // because the API returns null for no_sp at the detail level.
    for (final item in rawDetails) {
      if (item is Map<String, dynamic>) {
        item['no_sp'] = parentNoSp;
      }
    }

    final detailsList = rawDetails.cast<Map<String, dynamic>>();
    final paymentsList = rawPayments.cast<Map<String, dynamic>>();

    return OrderHistory(
      id: (letter['id'] as num?)?.toInt() ?? 0,
      noSp: parentNoSp,
      orderDate: letter['order_date']?.toString() ?? '-',
      requestDate: letter['request_date']?.toString() ?? '-',
      note: letter['note']?.toString() ?? '-',
      customerName: letter['customer_name']?.toString() ?? 'No Name',
      phone: letter['phone']?.toString() ?? '-',
      address: letter['address']?.toString() ?? '-',
      email: letter['email']?.toString() ?? '',
      shipToName: letter['ship_to_name']?.toString() ?? '',
      addressShipTo: letter['address_ship_to']?.toString() ?? '',
      noPo: letter['no_po']?.toString(),
      channel: letter['channel']?.toString(),
      isTakeAway: parseTakeAway(letter['take_away']),
      workPlaceName: json['work_place_name']?.toString() ??
          letter['work_place_name']?.toString() ??
          '-',
      companyName: json['company_name']?.toString() ?? '-',
      totalAmount: _parseDouble(letter['extended_amount']),
      postage: _parseDouble(letter['postage']),
      status: letter['status']?.toString() ?? OrderStatus.pending.apiValue,
      creator: letter['creator']?.toString() ?? '',
      creatorName: letter['creator_name']?.toString() ?? '',
      salesCode: letter['sales_code']?.toString() ?? '',
      salesName: letter['sales_name']?.toString() ?? '',
      details: detailsList
          .map((d) => OrderDetail.fromApiJson(d, parentNoSp: parentNoSp))
          .toList(),
      payments: paymentsList.map(OrderPayment.fromApiJson).toList(),
      createdAt: DateTime.tryParse(letter['created_at']?.toString() ?? ''),
      orderLetterContacts:
          _orderLetterContactsFromJson(json['order_letter_contacts']),
    );
  }
}

extension OrderHistoryX on OrderHistory {
  int get mainItemsCount =>
      details.where((d) => d.itemType.toLowerCase() != 'bonus').length;

  int get bonusItemsCount =>
      details.where((d) => d.itemType.toLowerCase() == 'bonus').length;

  String get firstItemName => mainItemsCount > 0
      ? details.firstWhere((d) => d.itemType.toLowerCase() != 'bonus').desc1
      : 'Pesanan';

  List<OrderDetail> get mainItems =>
      (details.where((d) => d.itemType.toLowerCase() != 'bonus').toList()
        ..sort((a, b) => a.id.compareTo(b.id)));

  List<OrderDetail> get bonusItems =>
      (details.where((d) => d.itemType.toLowerCase() == 'bonus').toList()
        ..sort((a, b) => a.id.compareTo(b.id)));

  /// Bentuk map seperti response API untuk [ApprovalDetailPage] (dari data ter-parse).
  Map<String, dynamic> toApprovalOrderDataMap() {
    return {
      'order_letter': {
        'id': id,
        'no_sp': noSp,
        'order_date': orderDate,
        'request_date': requestDate,
        'note': note,
        'customer_name': customerName,
        'phone': phone,
        'address': address,
        'email': email,
        'ship_to_name': shipToName,
        'address_ship_to': addressShipTo,
        'no_po': noPo,
        if ((channel ?? '').isNotEmpty) 'channel': channel,
        'take_away': isTakeAway,
        'work_place_name': workPlaceName,
        'company_name': companyName,
        'extended_amount': totalAmount,
        'postage': postage,
        'status': status,
        'creator': creator,
        'creator_name': creatorName,
        'sales_code': salesCode,
        'sales_name': salesName,
        'created_at': createdAt?.toIso8601String(),
      },
      'order_letter_details': details
          .map(
            (d) => {
              'order_letter_detail_id': d.id,
              'no_sp': d.noSp,
              'desc_1': d.desc1,
              'desc_2': d.desc2,
              'item_description': d.itemDescription,
              'item_type': d.itemType,
              'qty': d.qty,
              'customer_price': d.customerPrice,
              'net_price': d.netPrice,
              'brand': d.brand,
              'unit_price': d.unitPrice,
              'extended_price': d.extendedPrice,
              'take_away': d.isTakeAway,
              'order_letter_discount': d.discounts
                  .map(
                    (x) => {
                      'order_letter_discount_id': x.id,
                      'discount': x.discountVal,
                      'approver_name': x.approverName,
                      'approver_level': x.approverLevel,
                      'approver_id': x.approverId,
                      'approved': x.approvedStatus,
                      'approved_at': x.approvedAt,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'order_letter_payments': payments
          .map(
            (p) => {
              'payment_method': p.method,
              'payment_bank': p.bank,
              'payment_amount': p.amount,
              'image': p.image,
              'payment_date': p.paymentDate,
              'created_at': p.createdAt,
            },
          )
          .toList(),
      if (orderLetterContacts.isNotEmpty)
        'order_letter_contacts': orderLetterContacts,
    };
  }
}

/// Stub agar [OrderDetailPage] bisa refresh penuh dari API (mis. tap notifikasi).
OrderHistory orderHistoryStubFromNotification({
  required int id,
  String orderLetterNo = '-',
}) {
  return OrderHistory.fromApiJson({
    'order_letter': {
      'id': id,
      'no_sp': orderLetterNo.isEmpty ? '-' : orderLetterNo,
      'order_date': '',
      'request_date': '',
      'note': '',
      'customer_name': '',
      'phone': '',
      'address': '',
      'email': '',
      'status': '',
      'extended_amount': 0,
      'postage': 0,
    },
    'order_letter_details': <dynamic>[],
    'order_letter_payments': <dynamic>[],
  });
}

@freezed
class OrderDetail with _$OrderDetail {
  const factory OrderDetail({
    required int id,
    @Default('-') String noSp,
    required String itemDescription,
    required String desc1,
    @Default('') String desc2,
    required String itemType,
    required int qty,
    @JsonKey(fromJson: _parseDouble) required double customerPrice,
    @JsonKey(fromJson: _parseDouble) required double netPrice,
    required String brand,
    @JsonKey(fromJson: _parseDouble) required double unitPrice,
    @JsonKey(fromJson: _parseDouble) @Default(0) double extendedPrice,
    @Default(<OrderDiscount>[]) List<OrderDiscount> discounts,
    @Default(false) bool isTakeAway,
  }) = _OrderDetail;

  factory OrderDetail.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailFromJson(_orderDetailJsonWithResolvedTakeAway(json));

  /// Parse from API JSON. [parentNoSp] propagates the parent order's SP number
  /// because the API returns null for no_sp at the detail level.
  factory OrderDetail.fromApiJson(
    Map<String, dynamic> json, {
    String parentNoSp = '-',
  }) {
    final discList = (json['order_letter_discount'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final parsedDiscounts = discList.map(OrderDiscount.fromApiJson).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final up = _parseDouble(json['unit_price']);
    final q = (json['qty'] as num?)?.toInt() ?? 1;
    final ep = _parseDouble(json['extended_price']);

    return OrderDetail(
      id: (json['order_letter_detail_id'] as num?)?.toInt() ??
          (json['id'] as num?)?.toInt() ??
          0,
      noSp: json['no_sp']?.toString() ?? parentNoSp,
      itemDescription: json['item_description']?.toString() ?? '',
      desc1: json['desc_1']?.toString() ?? '',
      desc2: json['desc_2']?.toString() ?? '',
      itemType: json['item_type']?.toString() ?? '',
      qty: q,
      customerPrice: _parseDouble(json['customer_price']),
      netPrice: _parseDouble(json['net_price']),
      brand: json['brand']?.toString() ?? '',
      unitPrice: up,
      extendedPrice: ep > 0 ? ep : up * q,
      discounts: parsedDiscounts,
      isTakeAway: parseTakeAway(json['take_away']),
    );
  }
}

@freezed
class OrderDiscount with _$OrderDiscount {
  const factory OrderDiscount({
    required int id,
    required String discountVal,
    required String approverName,
    required String approverLevel,

    /// From API `approver_id`; used to detect "giliran Anda" on order detail.
    String? approverId,
    required String approvedStatus,
    String? approvedAt,
  }) = _OrderDiscount;

  factory OrderDiscount.fromJson(Map<String, dynamic> json) =>
      _$OrderDiscountFromJson(json);

  factory OrderDiscount.fromApiJson(Map<String, dynamic> json) {
    return OrderDiscount(
      id: (json['order_letter_discount_id'] as num?)?.toInt() ?? 0,
      discountVal: json['discount']?.toString() ?? '0',
      approverName: json['approver_name']?.toString() ?? '-',
      approverLevel: json['approver_level']?.toString() ?? '-',
      approverId: json['approver_id']?.toString(),
      approvedStatus:
          json['approved']?.toString() ?? OrderStatus.pending.apiValue,
      approvedAt: json['approved_at']?.toString(),
    );
  }
}

@freezed
class OrderPayment with _$OrderPayment {
  const factory OrderPayment({
    required String method,
    required String bank,
    @JsonKey(fromJson: _parseDouble) required double amount,
    required String image,
    @Default('') String paymentDate,
    @Default('') String createdAt,
  }) = _OrderPayment;

  factory OrderPayment.fromJson(Map<String, dynamic> json) =>
      _$OrderPaymentFromJson(json);

  factory OrderPayment.fromApiJson(Map<String, dynamic> json) {
    return OrderPayment(
      method: json['payment_method']?.toString() ?? '-',
      bank: json['payment_bank']?.toString() ?? '-',
      amount: _parseDouble(json['payment_amount']),
      image: json['image']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
