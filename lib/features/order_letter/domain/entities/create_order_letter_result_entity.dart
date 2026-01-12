/// Entity untuk result dari create order letter operation
/// 
/// Represents result dari create order letter dengan details dan discounts
class CreateOrderLetterResultEntity {
  final bool success;
  final String message;
  final int? orderLetterId;
  final String? noSp;
  final String? finalStatus;
  final List<Map<String, dynamic>>? detailResults;
  final List<Map<String, dynamic>>? discountResults;

  const CreateOrderLetterResultEntity({
    required this.success,
    required this.message,
    this.orderLetterId,
    this.noSp,
    this.finalStatus,
    this.detailResults,
    this.discountResults,
  });

  /// Convert to Map untuk backward compatibility
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'success': success,
      'message': message,
    };

    if (orderLetterId != null) {
      map['orderLetterId'] = orderLetterId;
    }
    if (noSp != null) {
      map['noSp'] = noSp;
    }
    if (finalStatus != null) {
      map['finalStatus'] = finalStatus;
    }
    if (detailResults != null) {
      map['detailResults'] = detailResults;
    }
    if (discountResults != null) {
      map['discountResults'] = discountResults;
    }

    return map;
  }

  /// Create from Map (untuk backward compatibility)
  factory CreateOrderLetterResultEntity.fromMap(Map<String, dynamic> map) {
    return CreateOrderLetterResultEntity(
      success: map['success'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      orderLetterId: (map['orderLetterId'] as num?)?.toInt() ??
          (map['id'] as num?)?.toInt(),
      noSp: map['noSp'] as String? ?? map['no_sp'] as String?,
      finalStatus: map['finalStatus'] as String?,
      detailResults: map['detailResults'] as List<Map<String, dynamic>>?,
      discountResults: map['discountResults'] as List<Map<String, dynamic>>?,
    );
  }

  /// Create success result
  factory CreateOrderLetterResultEntity.success({
    required int orderLetterId,
    String? noSp,
    String? finalStatus,
    List<Map<String, dynamic>>? detailResults,
    List<Map<String, dynamic>>? discountResults,
  }) {
    return CreateOrderLetterResultEntity(
      success: true,
      message: 'Order letter created successfully with all details and discounts',
      orderLetterId: orderLetterId,
      noSp: noSp,
      finalStatus: finalStatus,
      detailResults: detailResults,
      discountResults: discountResults,
    );
  }

  /// Create failure result
  factory CreateOrderLetterResultEntity.failure(String message) {
    return CreateOrderLetterResultEntity(
      success: false,
      message: message,
    );
  }
}

