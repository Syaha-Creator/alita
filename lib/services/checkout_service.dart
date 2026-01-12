import '../config/dependency_injection.dart';
import '../core/utils/error_logger.dart';
import '../core/error/exceptions.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import '../features/cart/domain/usecases/calculate_cart_totals_usecase.dart';
import '../features/cart/domain/usecases/prepare_order_letter_data_usecase.dart';
import '../features/cart/domain/usecases/prepare_order_letter_details_usecase.dart';
import '../features/cart/domain/usecases/get_leader_ids_from_cart_usecase.dart';
import '../features/order_letter/domain/usecases/create_order_letter_with_details_usecase.dart';
import '../features/approval/data/repositories/approval_repository.dart';
import '../services/auth_service.dart';
import '../services/order_letter_service.dart';
import '../services/notification_service.dart';

class CheckoutService {
  final CalculateCartTotalsUseCase _calculateCartTotalsUseCase;
  final PrepareOrderLetterDataUseCase _prepareOrderLetterDataUseCase;
  final PrepareOrderLetterDetailsUseCase _prepareOrderLetterDetailsUseCase;
  final GetLeaderIdsFromCartUseCase _getLeaderIdsFromCartUseCase;

  CheckoutService({
    CalculateCartTotalsUseCase? calculateCartTotalsUseCase,
    PrepareOrderLetterDataUseCase? prepareOrderLetterDataUseCase,
    PrepareOrderLetterDetailsUseCase? prepareOrderLetterDetailsUseCase,
    GetLeaderIdsFromCartUseCase? getLeaderIdsFromCartUseCase,
  })  : _calculateCartTotalsUseCase =
            calculateCartTotalsUseCase ?? CalculateCartTotalsUseCase(),
        _prepareOrderLetterDataUseCase =
            prepareOrderLetterDataUseCase ?? PrepareOrderLetterDataUseCase(),
        _prepareOrderLetterDetailsUseCase = prepareOrderLetterDetailsUseCase ??
            PrepareOrderLetterDetailsUseCase(),
        _getLeaderIdsFromCartUseCase =
            getLeaderIdsFromCartUseCase ?? GetLeaderIdsFromCartUseCase();

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
    double? postage,
  }) async {
    try {
      // Get current user ID for creator field
      final userId = await AuthService.getCurrentUserId();
      final creatorId = userId?.toString() ?? '0';

      final now = DateTime.now();
      final orderDateStr = now.toIso8601String().split('T')[0];
      
      // Normalize requestDate: handle empty, different formats, or extract date part
      String requestDateStr = orderDateStr; // Default to today
      if (requestDate.trim().isNotEmpty) {
        final trimmedDate = requestDate.trim();
        
        // Check if already in YYYY-MM-DD format
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmedDate)) {
          requestDateStr = trimmedDate;
        } else if (trimmedDate.contains('T')) {
          // ISO format with time, extract date part
          requestDateStr = trimmedDate.split('T')[0];
        } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(trimmedDate)) {
          // Format dd/MM/yyyy (from FormatHelper.formatSimpleDate)
          try {
            final parts = trimmedDate.split('/');
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            final parsedDate = DateTime(year, month, day);
            requestDateStr = parsedDate.toIso8601String().split('T')[0];
          } catch (e) {
            // If parsing fails, use order date as fallback
            requestDateStr = orderDateStr;
          }
        } else {
          // Try to parse with DateTime.parse (handles various formats)
          try {
            final parsedDate = DateTime.parse(trimmedDate);
            requestDateStr = parsedDate.toIso8601String().split('T')[0];
          } catch (e) {
            // If parsing fails, use order date as fallback
            requestDateStr = orderDateStr;
          }
        }
      }

      // Calculate totals using use case
      final totalsResult = _calculateCartTotalsUseCase(cartItems);
      final totalExtendedAmount = totalsResult.totalExtendedAmount;
      final totalHargaAwal = totalsResult.totalHargaAwal;
      final itemDiscounts = totalsResult.itemDiscounts;
      final totalDiscountPercentage = totalsResult.totalDiscountPercentage;

      // Flatten all discounts for status determination
      final allDiscounts = totalsResult.getAllDiscounts();

      // Prepare Order Letter Data using use case
      final orderLetterData = await _prepareOrderLetterDataUseCase(
        creatorId: creatorId,
        orderDateStr: orderDateStr,
        requestDateStr: requestDateStr,
        customerName: customerName,
        customerPhone: customerPhone,
        email: email,
        customerAddress: customerAddress,
        shipToName: shipToName,
        addressShipTo: addressShipTo,
        note: note,
        spgCode: spgCode,
        isTakeAway: isTakeAway,
        postage: postage,
        totalExtendedAmount: totalExtendedAmount,
        totalHargaAwal: totalHargaAwal,
        totalDiscountPercentage: totalDiscountPercentage,
        allDiscounts: allDiscounts,
      );

      // Prepare Details Data using use case
      final detailsData = await _prepareOrderLetterDetailsUseCase(
        cartItems: cartItems,
        isTakeAway: isTakeAway,
      );

      // Get leader IDs from cart using use case
      final leaderIdsResult = _getLeaderIdsFromCartUseCase(cartItems);
      final leaderIds = leaderIdsResult['leaderIds'] as List<int?>;

      // Create Order Letter with Details and Discounts
      final createOrderLetterUseCase = CreateOrderLetterWithDetailsUseCase(
        locator<OrderLetterService>(),
      );
      final result = await createOrderLetterUseCase(
        orderLetterData: orderLetterData,
        detailsData: detailsData,
        discountsData:
            itemDiscounts, // Pass structured discount data (List<OrderLetterDiscountDataEntity>)
        leaderIds: leaderIds,
      );

      // Send notification if order letter created successfully
      if (result.success) {
        // Invalidate approval cache so new order appears immediately
        try {
          final approvalRepository = locator<ApprovalRepository>();
          approvalRepository.clearCache();
        } catch (e) {
          // Don't fail if cache clear fails
        }

        // Send notification to leaders about new order letter
        try {
          final notificationService = NotificationService();
          final orderLetterId = result.orderLetterId?.toString() ?? 'Unknown';
          final noSp = result.noSp ?? 'Unknown';
          final customerName = orderLetterData.customerName;
          final totalAmount = orderLetterData.extendedAmount;

          // Get leader IDs from the result or use the ones we passed
          List<int>? leaderIdsForNotification;
          if (leaderIds.isNotEmpty) {
            leaderIdsForNotification = leaderIds.whereType<int>().toList();
          }

          await notificationService.notifyLeadersOnOrderLetterCreated(
            orderId: orderLetterId,
            noSp: noSp,
            customerName: customerName,
            totalAmount: totalAmount,
            leaderIds: leaderIdsForNotification,
          );
        } catch (e, stackTrace) {
          // Don't fail checkout if notification fails
          await ErrorLogger.logError(
            e,
            stackTrace: stackTrace,
            context: 'Failed to send notification after order creation',
            extra: {
              'orderLetterId': result.orderLetterId?.toString(),
              'noSp': result.noSp?.toString(),
            },
            fatal: false,
          );
        }
      }

      return result.toMap();
    } on ValidationException catch (e, stackTrace) {
      // Handle validation errors with clear messages
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Validation error creating order letter from cart',
        extra: {
          'cartItemsCount': cartItems.length,
          'customerName': customerName,
          'validationError': e.message,
        },
        fatal: false,
      );
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e, stackTrace) {
      await ErrorLogger.logError(
        e,
        stackTrace: stackTrace,
        context: 'Failed to create order letter from cart',
        extra: {
          'cartItemsCount': cartItems.length,
          'customerName': customerName,
        },
        fatal: true,
      );
      // Provide more user-friendly error message
      final errorMessage = e is ValidationException
          ? e.message
          : 'Gagal membuat surat pesanan. Silakan coba lagi atau hubungi support jika masalah berlanjut.';
      return {'success': false, 'message': errorMessage};
    }
  }
}
