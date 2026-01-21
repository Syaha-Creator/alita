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
      // Add main product (kasur) - only if valid
      if (_shouldUploadItemUseCase(item.product.kasur) &&
          item.product.plKasur > 0) {
        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'kasur',
          itemName: item.product.kasur,
          unitPrice: item.product.plKasur,
          customerPrice: item.product.eupKasur,
          takeAwayString: takeAwayString,
        );
      }

      // Add divan
      if (_shouldUploadItemUseCase(item.product.divan) &&
          item.product.plDivan > 0) {
        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'divan',
          itemName: item.product.divan,
          unitPrice: item.product.plDivan,
          customerPrice: item.product.eupDivan,
          takeAwayString: takeAwayString,
        );
      }

      // Add headboard
      if (_shouldUploadItemUseCase(item.product.headboard) &&
          item.product.plHeadboard > 0) {
        await _addItemDetails(
          detailsData: detailsData,
          item: item,
          itemType: 'headboard',
          itemName: item.product.headboard,
          unitPrice: item.product.plHeadboard,
          customerPrice: item.product.eupHeadboard,
          takeAwayString: takeAwayString,
        );
      }

      // Add sorong - uses resolveItemInfoUseCase (not per unit)
      if (_shouldUploadItemUseCase(item.product.sorong) &&
          item.product.plSorong > 0) {
        final sorongInfo = await _resolveItemInfoUseCase(
          item: item,
          itemType: 'sorong',
        );
        detailsData.add(
          OrderLetterDetailDataEntity(
            itemNumber: sorongInfo['item_number'],
            itemDescription: sorongInfo['item_description'],
            desc1: item.product.sorong,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            unitPrice: item.product.plSorong,
            customerPrice: item.product.eupSorong,
            netPrice: _applyDiscountsUsecase.applySequentially(
                item.product.eupSorong, item.discountPercentages),
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
  }) async {
    final itemInfoList = await _resolveItemInfoPerUnitUseCase(
      item: item,
      itemType: itemType,
    );
    // If numbers vary per unit, split lines per unit with qty 1
    final nums = itemInfoList.map((e) => e['item_number'] ?? '').toList();
    final bool hasVariety = nums.toSet().length > 1;
    final double netPrice = _applyDiscountsUsecase.applySequentially(
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
