import 'dart:convert';

import 'package:alitapricelist/core/utils/log.dart';

import '../../cart/data/cart_item.dart';

/// Status lifecycle for a quotation draft.
enum QuotationStatus {
  draft,
  sent,
  converted;

  String get label => switch (this) {
        draft => 'Draft',
        sent => 'Terkirim',
        converted => 'Jadi SP',
      };
}

/// A locally-persisted draft quotation (penawaran harga).
///
/// Stores the snapshot of cart items + customer info at the time the
/// quotation was created. Serialisable to/from JSON for SharedPreferences.
class QuotationModel {
  final String id;

  // ── Customer ──
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String customerPhone2;
  final String customerAddress;

  // ── Region ──
  final String regionProvinsi;
  final String regionKota;
  final String regionKecamatan;
  final String regionText;

  // ── Shipping ──
  final bool isShippingSameAsCustomer;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String shippingRegionProvinsi;
  final String shippingRegionKota;
  final String shippingRegionKecamatan;
  final String shippingRegionText;

  // ── Delivery ──
  final String? requestDate;
  final bool isTakeAway;
  final String postage;
  final String scCode;

  // ── Workplace & Sales ──
  final String workPlaceName;
  final String salesName;

  // ── Cart snapshot ──
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double totalPrice;
  final String notes;
  final DateTime createdAt;

  // ── Status & Expiry ──
  final QuotationStatus status;
  final DateTime? validUntil;

  const QuotationModel({
    required this.id,
    required this.customerName,
    this.customerEmail = '',
    this.customerPhone = '',
    this.customerPhone2 = '',
    this.customerAddress = '',
    this.regionProvinsi = '',
    this.regionKota = '',
    this.regionKecamatan = '',
    this.regionText = '',
    this.isShippingSameAsCustomer = true,
    this.shippingName = '',
    this.shippingPhone = '',
    this.shippingAddress = '',
    this.shippingRegionProvinsi = '',
    this.shippingRegionKota = '',
    this.shippingRegionKecamatan = '',
    this.shippingRegionText = '',
    this.requestDate,
    this.isTakeAway = false,
    this.postage = '',
    this.scCode = '',
    this.workPlaceName = '',
    this.salesName = '',
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.totalPrice,
    this.notes = '',
    required this.createdAt,
    this.status = QuotationStatus.draft,
    this.validUntil,
  });

  /// Whether this quotation has passed its validity date.
  bool get isExpired {
    final vu = validUntil;
    return vu != null && DateTime.now().isAfter(vu);
  }

  /// Days remaining until expiry. Negative if already expired.
  int get daysRemaining {
    final vu = validUntil;
    return vu != null ? vu.difference(DateTime.now()).inDays : -1;
  }

  QuotationModel copyWith({
    String? id,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerPhone2,
    String? customerAddress,
    String? regionProvinsi,
    String? regionKota,
    String? regionKecamatan,
    String? regionText,
    bool? isShippingSameAsCustomer,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
    String? shippingRegionProvinsi,
    String? shippingRegionKota,
    String? shippingRegionKecamatan,
    String? shippingRegionText,
    String? requestDate,
    bool? isTakeAway,
    String? postage,
    String? scCode,
    String? workPlaceName,
    String? salesName,
    List<CartItem>? items,
    double? subtotal,
    double? discount,
    double? totalPrice,
    String? notes,
    DateTime? createdAt,
    QuotationStatus? status,
    DateTime? validUntil,
  }) {
    return QuotationModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      customerPhone2: customerPhone2 ?? this.customerPhone2,
      customerAddress: customerAddress ?? this.customerAddress,
      regionProvinsi: regionProvinsi ?? this.regionProvinsi,
      regionKota: regionKota ?? this.regionKota,
      regionKecamatan: regionKecamatan ?? this.regionKecamatan,
      regionText: regionText ?? this.regionText,
      isShippingSameAsCustomer:
          isShippingSameAsCustomer ?? this.isShippingSameAsCustomer,
      shippingName: shippingName ?? this.shippingName,
      shippingPhone: shippingPhone ?? this.shippingPhone,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingRegionProvinsi:
          shippingRegionProvinsi ?? this.shippingRegionProvinsi,
      shippingRegionKota: shippingRegionKota ?? this.shippingRegionKota,
      shippingRegionKecamatan:
          shippingRegionKecamatan ?? this.shippingRegionKecamatan,
      shippingRegionText: shippingRegionText ?? this.shippingRegionText,
      requestDate: requestDate ?? this.requestDate,
      isTakeAway: isTakeAway ?? this.isTakeAway,
      postage: postage ?? this.postage,
      scCode: scCode ?? this.scCode,
      workPlaceName: workPlaceName ?? this.workPlaceName,
      salesName: salesName ?? this.salesName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'customerPhone2': customerPhone2,
        'customerAddress': customerAddress,
        'regionProvinsi': regionProvinsi,
        'regionKota': regionKota,
        'regionKecamatan': regionKecamatan,
        'regionText': regionText,
        'isShippingSameAsCustomer': isShippingSameAsCustomer,
        'shippingName': shippingName,
        'shippingPhone': shippingPhone,
        'shippingAddress': shippingAddress,
        'shippingRegionProvinsi': shippingRegionProvinsi,
        'shippingRegionKota': shippingRegionKota,
        'shippingRegionKecamatan': shippingRegionKecamatan,
        'shippingRegionText': shippingRegionText,
        'requestDate': requestDate,
        'isTakeAway': isTakeAway,
        'postage': postage,
        'scCode': scCode,
        'workPlaceName': workPlaceName,
        'salesName': salesName,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'totalPrice': totalPrice,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'validUntil': validUntil?.toIso8601String(),
      };

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['id'] as String,
      customerName: json['customerName'] as String? ?? '',
      customerEmail: json['customerEmail'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      customerPhone2: json['customerPhone2'] as String? ?? '',
      customerAddress: json['customerAddress'] as String? ?? '',
      regionProvinsi: json['regionProvinsi'] as String? ?? '',
      regionKota: json['regionKota'] as String? ?? '',
      regionKecamatan: json['regionKecamatan'] as String? ?? '',
      regionText: json['regionText'] as String? ?? '',
      isShippingSameAsCustomer:
          json['isShippingSameAsCustomer'] as bool? ?? true,
      shippingName: json['shippingName'] as String? ?? '',
      shippingPhone: json['shippingPhone'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      shippingRegionProvinsi:
          json['shippingRegionProvinsi'] as String? ?? '',
      shippingRegionKota: json['shippingRegionKota'] as String? ?? '',
      shippingRegionKecamatan:
          json['shippingRegionKecamatan'] as String? ?? '',
      shippingRegionText: json['shippingRegionText'] as String? ?? '',
      requestDate: json['requestDate'] as String?,
      isTakeAway: json['isTakeAway'] as bool? ?? false,
      postage: json['postage'] as String? ?? '',
      scCode: json['scCode'] as String? ?? '',
      workPlaceName: json['workPlaceName'] as String? ?? '',
      salesName: json['salesName'] as String? ?? '',
      items: (json['items'] as List<dynamic>)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: _parseStatus(json['status'] as String?),
      validUntil: json['validUntil'] != null
          ? DateTime.tryParse(json['validUntil'] as String)
          : null,
    );
  }

  static QuotationStatus _parseStatus(String? raw) {
    if (raw == null) return QuotationStatus.draft;
    return QuotationStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => QuotationStatus.draft,
    );
  }

  /// Convenience: encode list → JSON string for SharedPreferences.
  static String encodeList(List<QuotationModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  /// Convenience: decode JSON string → list of QuotationModel.
  ///
  /// Uses per-item error handling so one corrupt entry does not
  /// wipe the entire list.
  static List<QuotationModel> decodeList(String jsonString) {
    if (jsonString.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      final results = <QuotationModel>[];
      for (int i = 0; i < decoded.length; i++) {
        try {
          final map = Map<String, dynamic>.from(decoded[i] as Map);
          results.add(QuotationModel.fromJson(map));
        } catch (e, st) {
          Log.error(e, st, reason: 'QuotationModel.decodeList item[$i]');
        }
      }
      return results;
    } catch (e, st) {
      Log.error(e, st, reason: 'QuotationModel.decodeList JSON parse');
      return [];
    }
  }
}
