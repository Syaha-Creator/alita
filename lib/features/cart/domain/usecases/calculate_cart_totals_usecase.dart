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

  /// Check if item is from indirect channel (Toko or Massindo Fair - Toko)
  bool _isIndirectChannel(String channel) {
    final lowerChannel = channel.toLowerCase();
    return lowerChannel.contains('toko');
  }

  /// Calculate how many discount entries to create based on item split logic
  ///
  /// Items are split when:
  /// 1. qty > 1 AND
  /// 2. selectedItemNumbersPerUnit has different item_numbers for the primary item type (kasur)
  ///
  /// Returns the number of discount entries to create (1 if no split, or qty if split)
  int _calculateDiscountEntriesCount(CartEntity item) {
    // If qty is 1, no split possible
    if (item.quantity <= 1) return 1;

    // Check if user selected different item_numbers per unit for kasur
    final perUnitSelections = item.selectedItemNumbersPerUnit;
    if (perUnitSelections == null || perUnitSelections.isEmpty) {
      // No per-unit selections, items won't be split
      return 1;
    }

    // Check kasur item_numbers
    final kasurSelections = perUnitSelections['kasur'];
    if (kasurSelections == null || kasurSelections.isEmpty) {
      // No kasur selections, items won't be split
      return 1;
    }

    // Extract item_numbers from selections
    final itemNumbers = kasurSelections
        .map((e) => e['item_number'] ?? '')
        .where((nums) => nums.isNotEmpty)
        .toSet();

    // If there's variety in item_numbers, items will be split
    if (itemNumbers.length > 1) {
      // Return quantity - each unit will be a separate detail line
      return item.quantity;
    }

    // No variety, items stay combined
    return 1;
  }

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

    // Check if this is indirect checkout:
    // 1. Explicitly marked as indirect (item.isIndirect)
    // 2. OR channel contains "Toko" (fallback detection)
    final isIndirectCheckout = cartItems.isNotEmpty &&
        cartItems.every((item) =>
            item.isIndirect || _isIndirectChannel(item.product.channel));

    for (final item in cartItems) {
      totalExtendedAmount += item.netPrice * item.quantity;
      totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

      // Collect discounts from each item with item information
      // IMPORTANT: Always create discount entries for kasur items, even if all discounts are 0
      // This ensures approval workflow works correctly (User and Supervisor levels)
      // Get primary item name based on priority: Kasur → Divan → Headboard → Sorong
      final primaryItemName = _getPrimaryItemNameUseCase(item) ?? '';

      // Determine if this item is indirect:
      // - Either explicitly marked (item.isIndirect)
      // - Or channel contains "Toko" (fallback)
      final isItemIndirect =
          item.isIndirect || _isIndirectChannel(item.product.channel);

      // Only process if there's a valid primary item (kasur)
      if (primaryItemName.isNotEmpty) {
        // For INDIRECT checkout - use store discounts directly
        if (isItemIndirect) {
          // Get store name from storeInfo if available, otherwise use a default
          final storeName =
              item.storeInfo?.alphaName ?? 'Toko (${item.product.channel})';
          final storeDiscounts = item.discountPercentages;

          // For indirect, all discounts are store discounts (not user level discounts)
          // Calculate effective discount (cascading/berjenjang)
          double effectiveDiscount = 0;
          if (storeDiscounts.isNotEmpty) {
            // Cascading discount calculation: 1 - (1-d1)*(1-d2)*...
            double remainingPrice = 1.0;
            for (final discount in storeDiscounts) {
              remainingPrice *= (1 - discount / 100);
            }
            effectiveDiscount = (1 - remainingPrice) * 100;
          }

          // Check if items will be split due to different item_numbers per unit
          final int entriesCount = _calculateDiscountEntriesCount(item);

          // Create discount entries for each split line
          for (int entryIndex = 0; entryIndex < entriesCount; entryIndex++) {
            itemDiscounts.add(
              OrderLetterDiscountDataEntity(
                productId: item.product.id,
                kasurName: primaryItemName,
                productSize: item.product.ukuran,
                discounts: storeDiscounts, // Store discounts as-is
                isIndirect: true,
                storeName: storeName,
              ),
            );
          }

          // For indirect, use effective (cascading) discount for validation
          totalDiscountPercentage =
              effectiveDiscount; // Don't accumulate, use max
        } else {
          // For DIRECT checkout - use level-based discounts
          final allDiscounts = item.discountPercentages.isNotEmpty
              ? item.discountPercentages
              : <double>[];

          final discountsForEntry = <double>[];

          if (allDiscounts.isEmpty) {
            discountsForEntry.addAll([0.0, 0.0]);
          } else {
            for (int i = 0; i < allDiscounts.length; i++) {
              if (i < 2) {
                // Always include User and Supervisor levels
                discountsForEntry.add(allDiscounts[i]);
              } else {
                // For higher levels (RSM, Analyst, Controller), only include if > 0
                if (allDiscounts[i] > 0.0) {
                  discountsForEntry.add(allDiscounts[i]);
                }
              }
            }

            // Ensure at least 2 levels (User and Supervisor)
            while (discountsForEntry.length < 2) {
              discountsForEntry.add(0.0);
            }
          }

          // Check if items will be split due to different item_numbers per unit
          // This happens when selectedItemNumbersPerUnit has variety for kasur
          final int entriesCount = _calculateDiscountEntriesCount(item);

          // Create discount entries for each split line
          for (int entryIndex = 0; entryIndex < entriesCount; entryIndex++) {
            itemDiscounts.add(
              OrderLetterDiscountDataEntity(
                productId: item.product.id,
                kasurName: primaryItemName,
                productSize: item.product.ukuran,
                discounts: discountsForEntry,
                isIndirect: false,
              ),
            );
          }

          // Calculate effective discount using cascading formula (same as indirect)
          // This is the actual discount applied, not simple sum
          if (item.discountPercentages.isNotEmpty) {
            double remainingPrice = 1.0;
            for (final discount in item.discountPercentages) {
              if (discount > 0) {
                remainingPrice *= (1 - discount / 100);
              }
            }
            final effectiveDiscount = (1 - remainingPrice) * 100;
            // Use max effective discount across all items
            if (effectiveDiscount > totalDiscountPercentage) {
              totalDiscountPercentage = effectiveDiscount;
            }
          }
        }
      }
    }

    return CartTotalsEntity(
      totalExtendedAmount: totalExtendedAmount,
      totalHargaAwal: totalHargaAwal,
      itemDiscounts: itemDiscounts,
      totalDiscountPercentage: totalDiscountPercentage,
      isIndirectCheckout: isIndirectCheckout,
    );
  }
}
