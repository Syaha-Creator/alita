import '../config/dependency_injection.dart';
import 'api_client.dart';
import 'lookup_item_service.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../services/auth_service.dart';
import '../services/order_letter_service.dart';
import '../services/attendance_service.dart';

class CheckoutService {
  late final OrderLetterService _orderLetterService;
  late final AttendanceService _attendanceService;

  CheckoutService() {
    // Initialize services without circular dependency
    _orderLetterService = locator<OrderLetterService>();
    _attendanceService = locator<AttendanceService>();
  }

  // Resolve item number using product's prefilled number or lookup service (legacy per-component)
  Future<String> _resolveItemNumberFor(CartEntity item, String itemType) async {
    String? prefilled;
    // Prefer user selection stored in cart
    final selected = item.selectedItemNumbers?[itemType];
    if (selected != null) {
      final selNum = selected['item_number'];
      if (selNum != null && selNum.isNotEmpty) return selNum;
    }
    switch (itemType) {
      case 'kasur':
        prefilled = item.product.itemNumberKasur ?? item.product.itemNumber;
        break;
      case 'divan':
        prefilled = item.product.itemNumberDivan;
        break;
      case 'headboard':
        prefilled = item.product.itemNumberHeadboard;
        break;
      case 'sorong':
        prefilled = item.product.itemNumberSorong;
        break;
    }
    if (prefilled != null && prefilled.isNotEmpty) return prefilled;
    try {
      final lookup = LookupItemService(client: locator<ApiClient>());
      final list = await lookup.fetchLookupItems(
        brand: item.product.brand,
        kasur: item.product.kasur,
        divan: item.product.divan.isNotEmpty ? item.product.divan : null,
        headboard:
            item.product.headboard.isNotEmpty ? item.product.headboard : null,
        sorong: item.product.sorong.isNotEmpty ? item.product.sorong : null,
        ukuran: item.product.ukuran,
        contextItemType: itemType,
      );
      if (list.isNotEmpty && list.first.itemNumber.isNotEmpty) {
        return list.first.itemNumber;
      }
    } catch (_) {}
    return item.product.id.toString();
  }

  // Resolve per-unit item numbers if available; otherwise fallback to single number repeated
  Future<List<String>> _resolveItemNumbersPerUnit(
      CartEntity item, String itemType) async {
    final qty = item.quantity;
    // If per-unit selections exist, use them (fill gaps via legacy or lookup)
    final perUnit = item.selectedItemNumbersPerUnit?[itemType];
    if (perUnit != null && perUnit.isNotEmpty) {
      final List<String> results = [];
      for (int i = 0; i < qty; i++) {
        final sel = i < perUnit.length ? perUnit[i] : null;
        final numSel = sel != null ? (sel['item_number'] ?? '') : '';
        if (numSel.isNotEmpty) {
          results.add(numSel);
        } else {
          // fallback per-unit to legacy/component resolution
          results.add(await _resolveItemNumberFor(item, itemType));
        }
      }
      return results;
    }
    // No per-unit selections; reuse single resolution for all units
    final one = await _resolveItemNumberFor(item, itemType);
    return List<String>.filled(qty, one);
  }

  /// Create Order Letter from Cart Items
  Future<Map<String, dynamic>> createOrderLetterFromCart({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerPhone,
    required String email,
    required String customerAddress,
    required String shipToName,
    required String addressShipTo,
    required String requestDate,
    required String note,
    String? spgCode,
    bool isTakeAway = false,
  }) async {
    try {
      // Get current user ID for creator field
      final userId = await AuthService.getCurrentUserId();
      final creatorId = userId?.toString() ?? '0';

      final now = DateTime.now();
      final orderDateStr = now.toIso8601String().split('T')[0];
      final requestDateStr =
          requestDate.isNotEmpty ? requestDate.split('T')[0] : orderDateStr;

      // Calculate totals
      double totalExtendedAmount = 0;
      int totalHargaAwal = 0;
      final List<Map<String, dynamic>> itemDiscounts =
          []; // Store discounts with item info
      double totalDiscountPercentage = 0;

      for (final item in cartItems) {
        totalExtendedAmount += item.netPrice * item.quantity;
        totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

        // Collect discounts from each item with item information
        if (item.discountPercentages.isNotEmpty) {
          final validDiscounts =
              item.discountPercentages.where((d) => d > 0.0).toList();
          if (validDiscounts.isNotEmpty) {
            itemDiscounts.add({
              'productId': item.product.id,
              'kasurName': item.product.kasur,
              'productSize': item.product.ukuran,
              'discounts': validDiscounts,
            });
            totalDiscountPercentage += item.discountPercentages.fold(
              0.0,
              (sum, d) => sum + d,
            );
          }
        }
      }

      // Flatten all discounts for status determination
      final List<double> allDiscounts = [];
      for (final itemDiscount in itemDiscounts) {
        allDiscounts.addAll(itemDiscount['discounts']);
      }

      // Determine smart status based on discount approval requirements
      String orderStatus = _determineOrderStatus(allDiscounts);

      // Get work_place_id from attendance API
      final workPlaceId = await _attendanceService.getWorkPlaceId();

      // Prepare Order Letter Data
      final orderLetterData = {
        'order_date': orderDateStr,
        'request_date': requestDateStr,
        'creator': creatorId,
        'customer_name': customerName,
        'phone': customerPhone,
        'email': email,
        'address': customerAddress,
        'ship_to_name': shipToName,
        'address_ship_to': addressShipTo,
        'extended_amount': totalExtendedAmount,
        'harga_awal': totalHargaAwal,
        'discount': totalDiscountPercentage,
        'note': note,
        'status': orderStatus,
        'sales_code': spgCode ?? '',
        'work_place_id': workPlaceId,
        'take_away': isTakeAway
            ? 'TAKE AWAY'
            : null, // Global take away status as string
      };

      // Prepare Details Data
      final List<Map<String, dynamic>> detailsData = [];

      for (final item in cartItems) {
        // Add main product (kasur)
        if (item.product.kasur.isNotEmpty &&
            item.product.kasur != 'Tidak ada kasur') {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final nums = await _resolveItemNumbersPerUnit(item, 'kasur');
          // If numbers vary per unit, split lines per unit with qty 1
          final bool hasVariety = nums.toSet().length > 1;
          if (hasVariety) {
            for (final n in nums) {
              detailsData.add({
                'item_number': n,
                'desc_1': item.product.kasur,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': item.product.pricelist,
                'net_price': item.netPrice,
                'qty': 1,
                'item_type': 'kasur',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': nums.first,
              'desc_1': item.product.kasur,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': item.product.pricelist,
              'net_price': item.netPrice,
              'qty': item.quantity,
              'item_type': 'kasur',
              'take_away': takeAwayString,
            });
          }
        }

        // Add divan
        if (item.product.divan.isNotEmpty &&
            item.product.divan != 'Tidak ada divan' &&
            item.product.plDivan > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final nums = await _resolveItemNumbersPerUnit(item, 'divan');
          final bool hasVariety = nums.toSet().length > 1;
          if (hasVariety) {
            for (final n in nums) {
              detailsData.add({
                'item_number': n,
                'desc_1': item.product.divan,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': item.product.plDivan,
                'net_price': item.product.plDivan,
                'qty': 1,
                'item_type': 'divan',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': nums.first,
              'desc_1': item.product.divan,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': item.product.plDivan,
              'net_price': item.product.plDivan,
              'qty': item.quantity,
              'item_type': 'divan',
              'take_away': takeAwayString,
            });
          }
        }

        // Add headboard
        if (item.product.headboard.isNotEmpty &&
            item.product.headboard != 'Tidak ada headboard' &&
            item.product.plHeadboard > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          final nums = await _resolveItemNumbersPerUnit(item, 'headboard');
          final bool hasVariety = nums.toSet().length > 1;
          if (hasVariety) {
            for (final n in nums) {
              detailsData.add({
                'item_number': n,
                'desc_1': item.product.headboard,
                'desc_2': item.product.ukuran,
                'brand': item.product.brand,
                'unit_price': item.product.plHeadboard,
                'net_price': item.product.plHeadboard,
                'qty': 1,
                'item_type': 'headboard',
                'take_away': takeAwayString,
              });
            }
          } else {
            detailsData.add({
              'item_number': nums.first,
              'desc_1': item.product.headboard,
              'desc_2': item.product.ukuran,
              'brand': item.product.brand,
              'unit_price': item.product.plHeadboard,
              'net_price': item.product.plHeadboard,
              'qty': item.quantity,
              'item_type': 'headboard',
              'take_away': takeAwayString,
            });
          }
        }

        // Add sorong
        if (item.product.sorong.isNotEmpty &&
            item.product.sorong != 'Tidak ada sorong' &&
            item.product.plSorong > 0) {
          // Convert boolean to string format that backend expects
          String? takeAwayString;
          if (isTakeAway) {
            takeAwayString = 'TAKE AWAY';
          } else {
            takeAwayString = null;
          }

          detailsData.add({
            'item_number': await _resolveItemNumberFor(item, 'sorong'),
            'desc_1': item.product.sorong,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.plSorong, // Pricelist (harga asli)
            'net_price': item.product
                .plSorong, // Untuk aksesoris, net_price = unit_price (tidak ada discount)
            'qty': item.quantity,
            'item_type': 'sorong',
            'take_away': takeAwayString,
          });
        }

        // Add bonuses
        for (int i = 0; i < item.product.bonus.length; i++) {
          final bonus = item.product.bonus[i];
          if (bonus.name.isNotEmpty && bonus.quantity > 0) {
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
            String? takeAwayString;
            if (bonusTakeAway == true) {
              takeAwayString = 'TAKE AWAY';
            } else if (bonusTakeAway == false) {
              takeAwayString = null;
            } else {
              takeAwayString = null;
            }

            detailsData.add({
              'item_number': bonusItemNumber ?? item.product.id.toString(),
              'desc_1': bonus.name,
              'desc_2': 'Bonus',
              'brand': item.product.brand,
              'unit_price': 0,
              'net_price': 0,
              'qty': bonus.quantity * item.quantity,
              'item_type': 'Bonus',
              'take_away': takeAwayString,
            });
          }
        }
      }

      // Get leader IDs from product state with item mapping
      final Map<String, List<int?>> itemLeaderIds = {};
      for (final item in cartItems) {
        final state = locator<ProductBloc>().state;
        final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
        if (productLeaderIds.isNotEmpty) {
          itemLeaderIds[item.product.kasur] = productLeaderIds;
        }
      }

      // For backward compatibility, flatten all leader IDs
      final List<int?> leaderIds = [];
      for (final item in cartItems) {
        final state = locator<ProductBloc>().state;
        final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
        leaderIds.addAll(productLeaderIds);
      }

      // Create Order Letter with Details and Discounts
      final result = await _orderLetterService.createOrderLetterWithDetails(
        orderLetterData: orderLetterData,
        detailsData: detailsData,
        discountsData: itemDiscounts, // Pass structured discount data
        leaderIds: leaderIds,
      );

      // Send notification if order letter created successfully
      if (result['success'] == true) {
        // Invalidate approval cache so new order appears immediately
        try {
          final approvalRepository = locator<ApprovalRepository>();
          approvalRepository.clearCache();
        } catch (e) {
          // Don't fail if cache clear fails
        }
      }

      return result;
    } catch (e) {
      return {'success': false, 'message': 'Error creating order letter: $e'};
    }
  }

  /// Determine order status based on discount approval requirements
  String _determineOrderStatus(List<double> discounts) {
    // Filter out zero discounts (no approval needed)
    final significantDiscounts = discounts.where((d) => d > 0.0).toList();

    if (significantDiscounts.isEmpty) {
      return 'Pending';
    }

    if (significantDiscounts.every((d) => d <= 5.0)) {
      return 'Pending';
    }

    return 'Pending';
  }
}
