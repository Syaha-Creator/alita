import '../config/dependency_injection.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/product/presentation/bloc/product_bloc.dart';
import '../services/auth_service.dart';
import '../services/order_letter_service.dart';
import '../services/unified_notification_service.dart';

class CheckoutService {
  late final OrderLetterService _orderLetterService;
  late final UnifiedNotificationService _notificationService;

  CheckoutService() {
    // Initialize services without circular dependency
    _orderLetterService = locator<OrderLetterService>();
    _notificationService = UnifiedNotificationService();
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
  }) async {
    try {
      print('CheckoutService: Starting order letter creation from cart');

      final userName = await AuthService.getCurrentUserName() ?? 'Unknown User';
      final now = DateTime.now();
      final orderDateStr = now.toIso8601String().split('T')[0];
      final requestDateStr =
          requestDate.isNotEmpty ? requestDate.split('T')[0] : orderDateStr;

      // Calculate totals
      double totalExtendedAmount = 0;
      int totalHargaAwal = 0;
      final List<double> allDiscounts = [];
      double totalDiscountPercentage = 0;

      for (final item in cartItems) {
        totalExtendedAmount += item.netPrice * item.quantity;
        totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

        // Collect all discounts from each item
        if (item.discountPercentages.isNotEmpty) {
          allDiscounts.addAll(item.discountPercentages.where((d) => d > 0.0));
          totalDiscountPercentage += item.discountPercentages.fold(
            0.0,
            (sum, d) => sum + d,
          );
        }
      }

      // Prepare Order Letter Data
      final orderLetterData = {
        'order_date': orderDateStr,
        'request_date': requestDateStr,
        'creator': userName,
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
        'status': 'Pending',
      };

      print('CheckoutService: Order letter data prepared: $orderLetterData');
      print(
        'CheckoutService: Shipping data - shipToName: "$shipToName", addressShipTo: "$addressShipTo"',
      );

      // Prepare Details Data
      final List<Map<String, dynamic>> detailsData = [];

      for (final item in cartItems) {
        // Add main product (kasur)
        if (item.product.kasur.isNotEmpty &&
            item.product.kasur != 'Tidak ada kasur') {
          detailsData.add({
            'item_number': item.product.itemNumberKasur ??
                item.product.itemNumber ??
                item.product.id.toString(),
            'desc_1': item.product.kasur,
            'desc_2': item.product.ukuran,
            'brand': item.product.brand,
            'unit_price': item.product.pricelist,
            'qty': item.quantity,
            'item_type': 'kasur',
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

            detailsData.add({
              'item_number': bonusItemNumber ?? item.product.id.toString(),
              'desc_1': bonus.name,
              'desc_2': 'Bonus',
              'brand': item.product.brand,
              'unit_price': 0,
              'qty': bonus.quantity * item.quantity,
              'item_type': 'Bonus',
            });
          }
        }
      }

      print(
        'CheckoutService: Details data prepared: ${detailsData.length} items',
      );

      // Get leader IDs from product state
      final List<int?> leaderIds = [];
      for (final item in cartItems) {
        final state = locator<ProductBloc>().state;
        final productLeaderIds = state.productLeaderIds[item.product.id] ?? [];
        leaderIds.addAll(productLeaderIds);
      }

      print('CheckoutService: Leader IDs prepared: $leaderIds');

      // Create Order Letter with Details and Discounts
      final result = await _orderLetterService.createOrderLetterWithDetails(
        orderLetterData: orderLetterData,
        detailsData: detailsData,
        discountsData: allDiscounts,
        leaderIds: leaderIds,
      );

      print('CheckoutService: Order letter creation result: $result');

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
            // Fallback to unified notification service
            final approvalNotificationService =
                locator<UnifiedNotificationService>();
            await approvalNotificationService.handleOrderLetterCreation(
              creatorUserId: 'unknown',
              orderId: result['orderLetterId']?.toString() ?? 'Unknown',
              customerName: customerName,
              totalAmount: totalExtendedAmount,
            );
          }
        } catch (e) {
          print('CheckoutService: Error sending notification: $e');
          // Don't fail the checkout process if notification fails
        }
      }

      return result;
    } catch (e) {
      print('CheckoutService: Error creating order letter from cart: $e');
      return {'success': false, 'message': 'Error creating order letter: $e'};
    }
  }
}
