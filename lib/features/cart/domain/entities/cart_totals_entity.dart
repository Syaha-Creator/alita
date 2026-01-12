import '../../../order_letter/domain/entities/order_letter_discount_data_entity.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/validators.dart';

/// Entity untuk cart totals calculation result
/// 
/// Represents hasil dari calculate cart totals
class CartTotalsEntity {
  final double totalExtendedAmount;
  final int totalHargaAwal;
  final List<OrderLetterDiscountDataEntity> itemDiscounts;
  final double totalDiscountPercentage;

  CartTotalsEntity({
    required this.totalExtendedAmount,
    required this.totalHargaAwal,
    required this.itemDiscounts,
    required this.totalDiscountPercentage,
  }) {
    // Validate totals
    Validators.validateNonNegative(
      totalExtendedAmount,
      'Total extended amount',
    );
    Validators.validateNonNegative(totalHargaAwal, 'Total harga awal');
    Validators.validateNonNegative(
      totalDiscountPercentage,
      'Total discount percentage',
    );
    if (totalDiscountPercentage > 100) {
      throw ValidationException(
        'Total discount percentage tidak boleh lebih dari 100%',
      );
    }
  }

  /// Convert to Map untuk backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'totalExtendedAmount': totalExtendedAmount,
      'totalHargaAwal': totalHargaAwal,
      'itemDiscounts': itemDiscounts.map((e) => e.toMap()).toList(),
      'totalDiscountPercentage': totalDiscountPercentage,
    };
  }

  /// Create from Map (untuk backward compatibility)
  factory CartTotalsEntity.fromMap(Map<String, dynamic> map) {
    final itemDiscountsList = map['itemDiscounts'] as List<dynamic>? ?? [];
    return CartTotalsEntity(
      totalExtendedAmount: (map['totalExtendedAmount'] as num?)?.toDouble() ?? 0.0,
      totalHargaAwal: (map['totalHargaAwal'] as num?)?.toInt() ?? 0,
      itemDiscounts: itemDiscountsList
          .map((e) => OrderLetterDiscountDataEntity.fromMap(
                e as Map<String, dynamic>,
              ))
          .toList(),
      totalDiscountPercentage:
          (map['totalDiscountPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get all discounts flattened untuk status determination
  List<double> getAllDiscounts() {
    final List<double> allDiscounts = [];
    for (final itemDiscount in itemDiscounts) {
      allDiscounts.addAll(itemDiscount.discounts);
    }
    return allDiscounts;
  }
}

