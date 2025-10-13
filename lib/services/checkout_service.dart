import '../config/dependency_injection.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../services/auth_service.dart';
import '../services/order_letter_service.dart';
import '../services/core_notification_service.dart';

class CheckoutService {
  late final OrderLetterService _orderLetterService;
  late final CoreNotificationService _notificationService;

  CheckoutService() {
    // Initialize services without circular dependency
    _orderLetterService = locator<OrderLetterService>();
    _notificationService = locator<CoreNotificationService>();
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
        'spg_code': spgCode ?? '',
      };

      // Prepare Details Data
      final List<Map<String, dynamic>> detailsData = [];

      for (final item in cartItems) {
        // Add main product (kasur)
        if (item.product.kasur.isNotEmpty &&
            item.product.kasur != 'Tidak ada kasur') {
          print(
              'CheckoutService: Adding kasur ${item.product.kasur} - Pricelist: ${item.product.pricelist}, NetPrice: ${item.netPrice}');
          detailsData.add({
            'item_number': item.product.itemNumberKasur ??
                item.product.itemNumber ??
                item.product.id.toString(),
            'desc_1': item.product.kasur,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.netPrice,
            'qty': item.quantity,
            'item_type': 'kasur',
            'take_away': isTakeAway ? true : null,
          });
        }

        // Add divan
        if (item.product.divan.isNotEmpty &&
            item.product.divan != 'Tidak ada divan' &&
            item.product.plDivan > 0) {
          detailsData.add({
            'item_number':
                item.product.itemNumberDivan ?? item.product.id.toString(),
            'desc_1': item.product.divan,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.plDivan,
            'qty': item.quantity,
            'item_type': 'divan',
            'take_away': isTakeAway ? true : null,
          });
        }

        // Add headboard
        if (item.product.headboard.isNotEmpty &&
            item.product.headboard != 'Tidak ada headboard' &&
            item.product.plHeadboard > 0) {
          detailsData.add({
            'item_number':
                item.product.itemNumberHeadboard ?? item.product.id.toString(),
            'desc_1': item.product.headboard,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.plHeadboard,
            'qty': item.quantity,
            'item_type': 'headboard',
            'take_away': isTakeAway ? true : null,
          });
        }

        // Add sorong
        if (item.product.sorong.isNotEmpty &&
            item.product.sorong != 'Tidak ada sorong' &&
            item.product.plSorong > 0) {
          detailsData.add({
            'item_number':
                item.product.itemNumberSorong ?? item.product.id.toString(),
            'desc_1': item.product.sorong,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.plSorong,
            'qty': item.quantity,
            'item_type': 'sorong',
            'take_away': isTakeAway ? true : null,
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

            detailsData.add({
              'item_number': bonusItemNumber ?? item.product.id.toString(),
              'desc_1': bonus.name,
              'desc_2': 'Bonus',
              'brand': item.product.brand,
              'unit_price': 0,
              'qty': bonus.quantity * item.quantity,
              'item_type': 'Bonus',
              'take_away': bonusTakeAway,
            });
          }
        }
      }

      print(
        'CheckoutService: Details data prepared: ${detailsData.length} items',
      );

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
        try {
          // Get current user ID for notification
          final currentUserId = await AuthService.getCurrentUserId();

          if (currentUserId != null) {
            // Send both local and FCM notifications using new service
            await _notificationService.handleOrderLetterCreation(
              creatorUserId: currentUserId.toString(),
              orderId: result['orderLetterId']?.toString() ?? 'Unknown',
              customerName: customerName,
              totalAmount: totalExtendedAmount,
            );
          } else {
            // Use core notification service
            final coreNotificationService = locator<CoreNotificationService>();
            await coreNotificationService.handleOrderLetterCreation(
              creatorUserId: 'unknown',
              orderId: result['orderLetterId']?.toString() ?? 'Unknown',
              customerName: customerName,
              totalAmount: totalExtendedAmount,
            );
          }
        } catch (e) {
          // Don't fail the checkout process if notification fails
        }

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
      // No discounts → Still need Direct Leader approval
      return 'Pending';
    }

    // Check if only user-level discounts (level 1 auto-approved)
    // For now, assume any discount > 0 needs approval beyond user level
    // This logic can be enhanced based on business rules

    if (significantDiscounts.every((d) => d <= 5.0)) {
      // Small discounts (≤5%) → Still need Direct Leader approval
      return 'Pending';
    }

    // Has significant discounts that need higher-level approval
    return 'Pending';
  }
}
