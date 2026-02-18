import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/validators.dart';

/// Entity untuk order letter discount data
/// 
/// Represents structured discount data dengan item information
class OrderLetterDiscountDataEntity {
  final int productId;
  final String kasurName;
  final String productSize;
  final List<double> discounts;
  final bool isIndirect;
  final String? storeName; // Nama toko untuk indirect checkout

  OrderLetterDiscountDataEntity({
    required this.productId,
    required this.kasurName,
    required this.productSize,
    required this.discounts,
    this.isIndirect = false,
    this.storeName,
  }) {
    // Validate required fields
    Validators.validatePositive(productId, 'Product ID');
    Validators.validateRequired(kasurName, 'Kasur name');
    Validators.validateRequired(productSize, 'Product size');
    Validators.validateListNotEmpty(discounts, 'Discounts');
    for (final discount in discounts) {
      Validators.validateNonNegative(discount, 'Discount value');
      if (discount > 100) {
        throw ValidationException(
          'Discount tidak boleh lebih dari 100%',
        );
      }
    }
  }

  /// Convert to Map untuk API request
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'kasurName': kasurName,
      'productSize': productSize,
      'discounts': discounts,
      'isIndirect': isIndirect,
      'storeName': storeName,
    };
  }

  /// Create from Map (untuk backward compatibility)
  factory OrderLetterDiscountDataEntity.fromMap(Map<String, dynamic> map) {
    return OrderLetterDiscountDataEntity(
      productId: (map['productId'] as num?)?.toInt() ?? 0,
      kasurName: map['kasurName'] as String? ?? '',
      productSize: map['productSize'] as String? ?? '',
      discounts: (map['discounts'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      isIndirect: map['isIndirect'] as bool? ?? false,
      storeName: map['storeName'] as String?,
    );
  }
}

