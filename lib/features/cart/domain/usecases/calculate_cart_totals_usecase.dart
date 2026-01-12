import 'package:flutter/foundation.dart';
import '../entities/cart_entity.dart';
import '../entities/cart_totals_entity.dart';
import '../../../../core/utils/validators.dart';
import '../../../order_letter/domain/entities/order_letter_discount_data_entity.dart';
import 'get_primary_item_name_usecase.dart';
import 'should_upload_item_usecase.dart';

/// Use case untuk calculate totals dari cart items
///
/// Calculates:
/// - totalExtendedAmount: total net price dari semua items
/// - totalHargaAwal: total pricelist dari semua items
/// - itemDiscounts: list of discounts dengan item information
/// - totalDiscountPercentage: total discount percentage
class CalculateCartTotalsUseCase {
  final GetPrimaryItemNameUseCase _getPrimaryItemNameUseCase;

  CalculateCartTotalsUseCase({
    GetPrimaryItemNameUseCase? getPrimaryItemNameUseCase,
  }) : _getPrimaryItemNameUseCase = getPrimaryItemNameUseCase ??
            GetPrimaryItemNameUseCase(ShouldUploadItemUseCase());

  /// Calculate totals dari cart items
  ///
  /// Returns CartTotalsEntity dengan semua calculated values
  CartTotalsEntity call(List<CartEntity> cartItems) {
    // Validate input
    Validators.validateListNotEmpty(cartItems, 'Cart items');

    double totalExtendedAmount = 0;
    int totalHargaAwal = 0;
    final List<OrderLetterDiscountDataEntity> itemDiscounts = [];
    double totalDiscountPercentage = 0;

    for (final item in cartItems) {
      totalExtendedAmount += item.netPrice * item.quantity;
      totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

      // Collect discounts from each item with item information
      // IMPORTANT: Always create discount entries for kasur items, even if all discounts are 0
      // This ensures approval workflow works correctly (User and Direct Leader levels)
      // Get primary item name based on priority: Kasur → Divan → Headboard → Sorong
      final primaryItemName = _getPrimaryItemNameUseCase(item) ?? '';

      // Only process if there's a valid primary item (kasur)
      if (primaryItemName.isNotEmpty) {
        if (kDebugMode) {
          print(
              '[DEBUG] CalculateCartTotalsUseCase: Processing item ${item.product.id} ($primaryItemName)');
          print('  - Original Discounts: ${item.discountPercentages}');
        }

        // Get all discounts (including zeros) - we need at least 2 levels (User and Direct Leader)
        // Filter to keep only non-zero discounts for levels 2+ (Indirect Leader, Analyst, Controller)
        final allDiscounts = item.discountPercentages.isNotEmpty
            ? item.discountPercentages
            : <double>[];

        // Always create discount entries for kasur items, even if all discounts are 0
        // This ensures approval workflow: User (level 0) and Direct Leader (level 1) always exist
        // For levels 2+, only include if discount > 0
        final discountsForEntry = <double>[];

        // Always include at least 2 levels (User and Direct Leader) with discount 0 if needed
        if (allDiscounts.isEmpty) {
          // No discounts provided - create entries with 0 for User and Direct Leader
          discountsForEntry.addAll([0.0, 0.0]);
          if (kDebugMode) {
            print('  - No discounts provided, creating default [0.0, 0.0]');
          }
        } else {
          // Use provided discounts, but ensure at least 2 levels exist
          for (int i = 0; i < allDiscounts.length; i++) {
            if (i < 2) {
              // Level 0 (User) and Level 1 (Direct Leader) - always include, even if 0
              discountsForEntry.add(allDiscounts[i]);
              if (kDebugMode) {
                print(
                    '  - Level $i (${i == 0 ? "User" : "Direct Leader"}): ${allDiscounts[i]}% - Always included');
              }
            } else {
              // Level 2+ (Indirect Leader, Analyst, Controller) - only include if > 0
              if (allDiscounts[i] > 0.0) {
                discountsForEntry.add(allDiscounts[i]);
                if (kDebugMode) {
                  print('  - Level $i: ${allDiscounts[i]}% - Included (> 0)');
                }
              } else {
                if (kDebugMode) {
                  print('  - Level $i: ${allDiscounts[i]}% - Skipped (<= 0)');
                }
              }
            }
          }

          // Ensure at least 2 levels exist (User and Direct Leader)
          while (discountsForEntry.length < 2) {
            discountsForEntry.add(0.0);
            if (kDebugMode) {
              print('  - Added default 0.0 to ensure 2 levels');
            }
          }
        }

        if (kDebugMode) {
          print('  - Final Discounts for Entry: $discountsForEntry');
          print(
              '  - Primary Item: $primaryItemName, Size: ${item.product.ukuran}');
        }

        itemDiscounts.add(
          OrderLetterDiscountDataEntity(
            productId: item.product.id,
            kasurName: primaryItemName,
            productSize: item.product.ukuran,
            discounts: discountsForEntry,
          ),
        );

        totalDiscountPercentage += item.discountPercentages.fold(
          0.0,
          (sum, d) => sum + d,
        );
      }
    }

    return CartTotalsEntity(
      totalExtendedAmount: totalExtendedAmount,
      totalHargaAwal: totalHargaAwal,
      itemDiscounts: itemDiscounts,
      totalDiscountPercentage: totalDiscountPercentage,
    );
  }
}
