import '../entities/cart_entity.dart';
import '../../../../core/utils/validators.dart';
import '../../../order_letter/domain/entities/order_letter_detail_data_entity.dart';
import 'apply_discounts_usecase.dart';
import 'should_upload_item_usecase.dart';
import 'should_upload_bonus_usecase.dart';
import 'resolve_item_info_usecase.dart';
import 'resolve_item_info_per_unit_usecase.dart';
import 'resolve_bonus_item_info_usecase.dart';

/// Use case untuk prepare order letter details data
///
/// Prepares details data list dengan semua items (kasur, divan, headboard, sorong, bonus)
class PrepareOrderLetterDetailsUseCase {
  final ShouldUploadItemUseCase _shouldUploadItemUseCase;
  final ShouldUploadBonusUseCase _shouldUploadBonusUseCase;
  final ResolveItemInfoUseCase _resolveItemInfoUseCase;
  final ResolveItemInfoPerUnitUseCase _resolveItemInfoPerUnitUseCase;
  final ResolveBonusItemInfoUseCase _resolveBonusItemInfoUseCase;
  final ApplyDiscountsUsecase _applyDiscountsUsecase;

  PrepareOrderLetterDetailsUseCase({
    ShouldUploadItemUseCase? shouldUploadItemUseCase,
    ShouldUploadBonusUseCase? shouldUploadBonusUseCase,
    ResolveItemInfoUseCase? resolveItemInfoUseCase,
    ResolveItemInfoPerUnitUseCase? resolveItemInfoPerUnitUseCase,
    ResolveBonusItemInfoUseCase? resolveBonusItemInfoUseCase,
    ApplyDiscountsUsecase? applyDiscountsUsecase,
  })  : _shouldUploadItemUseCase =
            shouldUploadItemUseCase ?? ShouldUploadItemUseCase(),
        _shouldUploadBonusUseCase =
            shouldUploadBonusUseCase ?? ShouldUploadBonusUseCase(),
        _resolveItemInfoUseCase =
            resolveItemInfoUseCase ?? ResolveItemInfoUseCase(),
        _resolveItemInfoPerUnitUseCase = resolveItemInfoPerUnitUseCase ??
            ResolveItemInfoPerUnitUseCase(
              resolveItemInfoUseCase ?? ResolveItemInfoUseCase(),
            ),
        _resolveBonusItemInfoUseCase =
            resolveBonusItemInfoUseCase ?? ResolveBonusItemInfoUseCase(),
        _applyDiscountsUsecase =
            applyDiscountsUsecase ?? const ApplyDiscountsUsecase();

  /// Helper to check if item is from indirect channel
  bool _isIndirectItem(CartEntity item) {
    return item.isIndirect ||
        item.product.channel.toLowerCase().contains('toko');
  }

  /// Calculate customer price for indirect checkout (pricelist with cascading discounts)
  double _calculateIndirectCustomerPrice(
      double pricelist, List<double> discounts) {
    if (discounts.isEmpty) return pricelist;
    double result = pricelist;
    for (final discount in discounts) {
      result = result * (1 - discount / 100);
    }
    return result;
  }

  /// Prepare order letter details data
  ///
  /// Parameters:
  /// - cartItems: List of cart items
  /// - isTakeAway: Is take away flag
  ///
  /// Returns List dengan OrderLetterDetailDataEntity
  Future<List<OrderLetterDetailDataEntity>> call({
    required List<CartEntity> cartItems,
    required bool isTakeAway,
  }) async {
    // Validate input
    Validators.validateListNotEmpty(cartItems, 'Cart items');

    final List<OrderLetterDetailDataEntity> detailsData = [];

    // Convert boolean to string format that backend expects
    String? takeAwayString;
    if (isTakeAway) {
      takeAwayString = 'TAKE AWAY';
    } else {
      takeAwayString = null;
    }

    for (final item in cartItems) {
      // Check if this is indirect checkout
      final isIndirect = _isIndirectItem(item);

      final kasurUnitPrice = item.product.plKasur > 0
          ? item.product.plKasur
          : item.product.pricelist;
      final kasurCustomerPriceBase = item.product.eupKasur > 0
          ? item.product.eupKasur
          : item.product.endUserPrice;

      // Add main product (kasur) - only if valid
      // Use kasurUnitPrice which has fallback to pricelist
      if (_shouldUploadItemUseCase(item.product.kasur) && kasurUnitPrice > 0) {
        // For indirect: customerPrice = Pricelist (sama dengan unitPrice)
        //               netPrice = Pricelist after cascading store discounts
        // For direct: customerPrice = EUP (end user price)
        //             netPrice = EUP after user discounts
        final customerPrice =
            isIndirect ? kasurUnitPrice : kasurCustomerPriceBase;

        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'kasur',
          itemName: item.product.kasur,
          unitPrice: kasurUnitPrice,
          customerPrice: customerPrice,
          takeAwayString: takeAwayString,
          isIndirect: isIndirect,
        );
      }

      // Add divan
      if (_shouldUploadItemUseCase(item.product.divan) &&
          item.product.plDivan > 0) {
        final customerPrice =
            isIndirect ? item.product.plDivan : item.product.eupDivan;

        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'divan',
          itemName: item.product.divan,
          unitPrice: item.product.plDivan,
          customerPrice: customerPrice,
          takeAwayString: takeAwayString,
          isIndirect: isIndirect,
        );
      }

      // Add headboard
      if (_shouldUploadItemUseCase(item.product.headboard) &&
          item.product.plHeadboard > 0) {
        final customerPrice =
            isIndirect ? item.product.plHeadboard : item.product.eupHeadboard;

        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'headboard',
          itemName: item.product.headboard,
          unitPrice: item.product.plHeadboard,
          customerPrice: customerPrice,
          takeAwayString: takeAwayString,
          isIndirect: isIndirect,
        );
      }

      // Add sorong - uses resolveItemInfoUseCase (not per unit)
      if (_shouldUploadItemUseCase(item.product.sorong) &&
          item.product.plSorong > 0) {
        final sorongInfo = await _resolveItemInfoUseCase(
          item: item,
          itemType: 'sorong',
        );

        // For indirect: customerPrice = Pricelist
        final customerPrice = isIndirect
            ? item.product.plSorong // Pricelist for indirect
            : item.product.eupSorong;

        // For indirect: netPrice = Pricelist after cascading store discounts
        // For direct: netPrice = EUP after user discounts
        final netPrice = isIndirect
            ? _calculateIndirectCustomerPrice(
                item.product.plSorong, item.discountPercentages)
            : _applyDiscountsUsecase.applySequentially(
                item.product.eupSorong, item.discountPercentages);

        detailsData.add(
          OrderLetterDetailDataEntity(
            itemNumber: sorongInfo['item_number'],
            itemDescription: sorongInfo['item_description'],
            desc1: item.product.sorong,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            unitPrice: item.product.plSorong,
            customerPrice: customerPrice,
            netPrice: netPrice,
            qty: item.quantity,
            itemType: 'sorong',
            takeAway: takeAwayString,
          ),
        );
      }

      // Add bonus items - handle bonus array
      if (item.product.bonus.isNotEmpty) {
        for (int i = 0; i < item.product.bonus.length; i++) {
          final bonus = item.product.bonus[i];
          if (_shouldUploadBonusUseCase(bonus.name, bonus.quantity)) {
            String? bonusItemNumber;
            switch (i) {
              case 0:
                bonusItemNumber = item.product.itemNumberBonus1;
                break;
              case 1:
                bonusItemNumber = item.product.itemNumberBonus2;
                break;
              case 2:
                bonusItemNumber = item.product.itemNumberBonus3;
                break;
              case 3:
                bonusItemNumber = item.product.itemNumberBonus4;
                break;
              case 4:
                bonusItemNumber = item.product.itemNumberBonus5;
                break;
            }

            // Determine take away status for bonus
            bool? bonusTakeAway;
            if (isTakeAway) {
              // If full take away, all bonus items are take away
              bonusTakeAway = true;
            } else {
              // Check individual bonus take away status from cart item
              bonusTakeAway = item.bonusTakeAway?[bonus.name];
            }

            // Convert boolean to string format that backend expects
            String? bonusTakeAwayString;
            if (bonusTakeAway == true) {
              bonusTakeAwayString = 'TAKE AWAY';
            } else {
              bonusTakeAwayString = null;
            }

            // Resolve bonus item info
            final bonusInfo = await _resolveBonusItemInfoUseCase(
              item: item,
              bonusName: bonus.name,
              bonusItemNumber: bonusItemNumber,
            );
            final resolvedBonusNumber = bonusInfo['item_number'] ?? '';
            final resolvedBonusDescription = bonusInfo['item_description'];

            // Pastikan kuantitas bonus yang dikirim mengikuti kuantitas cart dan batas maksimal
            final maxBonusQty = bonus.calculateMaxQuantity(item.quantity);
            final resolvedBonusQty = bonus.quantity.clamp(1, maxBonusQty);

            final double bonusPricelist = bonus.pricelist;

            detailsData.add(
              OrderLetterDetailDataEntity(
                itemNumber:
                    resolvedBonusNumber.isNotEmpty ? resolvedBonusNumber : null,
                itemDescription: resolvedBonusDescription,
                desc1: bonus.name,
                desc2: 'Bonus',
                brand: item.product.brand,
                unitPrice: bonusPricelist,
                customerPrice: bonusPricelist,
                netPrice: 0,
                qty: resolvedBonusQty,
                itemType: 'Bonus',
                takeAway: bonusTakeAwayString,
              ),
            );
          }
        }
      }
    }

    return detailsData;
  }

  Future<void> _addItemDetails({
    required List<OrderLetterDetailDataEntity> detailsData,
    required CartEntity item,
    required String itemType,
    required String itemName,
    required double unitPrice,
    required double customerPrice,
    String? takeAwayString,
    bool isIndirect = false,
  }) async {
    final itemInfoList = await _resolveItemInfoPerUnitUseCase(
      item: item,
      itemType: itemType,
    );
    // If numbers vary per unit, split lines per unit with qty 1
    final nums = itemInfoList.map((e) => e['item_number'] ?? '').toList();
    final bool hasVariety = nums.toSet().length > 1;

    // For indirect:
    //   - customerPrice = Pricelist (unitPrice)
    //   - netPrice = Pricelist after cascading store discounts
    // For direct:
    //   - customerPrice = EUP
    //   - netPrice = EUP after user discounts
    final double netPrice = isIndirect
        ? _calculateIndirectCustomerPrice(unitPrice, item.discountPercentages)
        : _applyDiscountsUsecase.applySequentially(
            customerPrice, item.discountPercentages);

    if (hasVariety) {
      for (final info in itemInfoList) {
        detailsData.add(
          OrderLetterDetailDataEntity(
            itemNumber: info['item_number'],
            itemDescription: info['item_description'],
            desc1: itemName,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            unitPrice: unitPrice,
            customerPrice: customerPrice,
            netPrice: netPrice,
            qty: 1,
            itemType: itemType,
            takeAway: takeAwayString,
          ),
        );
      }
    } else {
      detailsData.add(
        OrderLetterDetailDataEntity(
          itemNumber: itemInfoList.first['item_number'],
          itemDescription: itemInfoList.first['item_description'],
          desc1: itemName,
          desc2: item.product.ukuran,
          brand: item.product.brand,
          unitPrice: unitPrice,
          customerPrice: customerPrice,
          netPrice: netPrice,
          qty: item.quantity,
          itemType: itemType,
          takeAway: takeAwayString,
        ),
      );
    }
  }
}
