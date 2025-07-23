import '../config/dependency_injection.dart';
import '../features/approval/data/models/order_letter_model.dart';
import '../features/approval/data/models/order_letter_detail_model.dart';
import '../features/approval/presentation/bloc/approval_bloc.dart';
import '../features/approval/presentation/bloc/approval_event.dart';
import '../features/product/domain/entities/product_entity.dart';
import '../features/cart/domain/entities/cart_entity.dart';
import 'auth_service.dart';

/// Service untuk proses approval order letter dari cart dan produk.
class ApprovalService {
  /// Membuat approval dari cart (beberapa item sekaligus).
  static Future<Map<String, dynamic>> createApprovalFromCart({
    required List<CartEntity> cartItems,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      final userName = await AuthService.getCurrentUserName() ?? 'Unknown User';
      final currentDate = DateTime.now().toString().split(' ')[0];

      // Calculate total extended amount and discount
      double totalExtendedAmount = 0;
      double totalDiscountPercentage = 0.0;
      int totalHargaAwal = 0;
      final List<double> tieredDiscounts = [];

      for (final item in cartItems) {
        totalExtendedAmount += item.netPrice * item.quantity;
        totalHargaAwal += (item.product.pricelist * item.quantity).toInt();

        // Kumpulkan semua diskon berjenjang dari setiap item
        if (item.discountPercentages.isNotEmpty) {
          tieredDiscounts
              .addAll(item.discountPercentages.where((d) => d > 0.0));
          totalDiscountPercentage += item.discountPercentages
              .where((d) => d > 0.0)
              .fold(0.0, (sum, d) => sum + d);
        }
      }

      // Convert to string (total percentage)
      final totalDiscountText = totalDiscountPercentage > 0.0
          ? totalDiscountPercentage.toStringAsFixed(2)
          : '0';

      // Debug logging
      print(
          'ApprovalService: Total discount percentage (cart): $totalDiscountPercentage');
      print(
          'ApprovalService: Discount text (cart accumulated): $totalDiscountText');
      print('ApprovalService: Tiered discounts: $tieredDiscounts');

      // Create Order Letter (header)
      final orderLetter = OrderLetterModel(
        orderDate: currentDate,
        creator: userName,
        customerName: customerName,
        phone: customerPhone,
        discount: totalDiscountText,
        discountDetail: totalDiscountText.isEmpty
            ? '0'
            : totalDiscountText, // Store detailed breakdown
        hargaAwal: totalHargaAwal,
        keterangan:
            cartItems.any((item) => item.product.isSet) ? 'Set' : 'Tidak Set',
        extendedAmount: totalExtendedAmount,
        status: 'Pending',
      );

      // Create Order Letter Details (loop per item)
      final List<OrderLetterDetailModel> details = [];

      for (final item in cartItems) {
        // Add main product (kasur) - only if exists
        if (item.product.kasur.isNotEmpty &&
            item.product.kasur != 'Tidak ada kasur') {
          details.add(OrderLetterDetailModel(
            qty: item.quantity,
            unitPrice: item.netPrice.toInt(),
            itemNumber: item.product.itemNumberKasur ??
                item.product.itemNumber ??
                item.product.id.toString(),
            desc1: item.product.kasur,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            itemType: item.netPrice.toString(),
          ));
        }

        // Add divan if exists and not empty
        if (item.product.divan.isNotEmpty &&
            item.product.divan != 'Tidak ada divan' &&
            item.product.plDivan > 0) {
          details.add(OrderLetterDetailModel(
            qty: item.quantity,
            unitPrice: item.product.plDivan.toInt(),
            itemNumber:
                item.product.itemNumberDivan ?? item.product.id.toString(),
            desc1: item.product.divan,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            itemType: item.product.plDivan.toString(),
          ));
        }

        // Add headboard if exists and not empty
        if (item.product.headboard.isNotEmpty &&
            item.product.headboard != 'Tidak ada headboard' &&
            item.product.plHeadboard > 0) {
          details.add(OrderLetterDetailModel(
            qty: item.quantity,
            unitPrice: item.product.plHeadboard.toInt(),
            itemNumber:
                item.product.itemNumberHeadboard ?? item.product.id.toString(),
            desc1: item.product.headboard,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            itemType: item.product.plHeadboard.toString(),
          ));
        }

        // Add sorong if exists and not empty
        if (item.product.sorong.isNotEmpty &&
            item.product.sorong != 'Tidak ada sorong' &&
            item.product.plSorong > 0) {
          details.add(OrderLetterDetailModel(
            qty: item.quantity,
            unitPrice: item.product.plSorong.toInt(),
            itemNumber:
                item.product.itemNumberSorong ?? item.product.id.toString(),
            desc1: item.product.sorong,
            desc2: item.product.ukuran,
            brand: item.product.brand,
            itemType: item.product.plSorong.toString(),
          ));
        }

        // Add bonuses if exists and have item numbers
        for (int i = 0; i < item.product.bonus.length; i++) {
          final bonus = item.product.bonus[i];
          if (bonus.name.isNotEmpty && bonus.quantity > 0) {
            // Get corresponding item number for bonus
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

            if (bonusItemNumber != null && bonusItemNumber.isNotEmpty) {
              details.add(OrderLetterDetailModel(
                qty: bonus.quantity,
                unitPrice: 0, // Bonus items are free
                itemNumber: bonusItemNumber,
                desc1: bonus.name,
                desc2: 'Bonus',
                brand: item.product.brand,
                itemType: 'Bonus',
              ));
            }
          }
        }
      }

      // Call approval bloc to create approval
      final approvalBloc = locator<ApprovalBloc>();
      approvalBloc.add(CreateApproval(
        orderLetter: orderLetter,
        details: details,
        discounts: tieredDiscounts,
      ));

      return {
        'success': true,
        'message': 'Approval request sent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }

  /// Membuat approval dari satu produk (single item).
  static Future<Map<String, dynamic>> createApprovalFromProduct({
    required ProductEntity product,
    required int quantity,
    required double netPrice,
    required String customerName,
    required String customerPhone,
    required List<double> discountPercentages,
    required double editPopupDiscount,
  }) async {
    try {
      final userName = await AuthService.getCurrentUserName() ?? 'Unknown User';
      final currentDate = DateTime.now().toString().split(' ')[0];

      print(
          'ApprovalService: discountPercentages from UI: $discountPercentages');
      print(
          'ApprovalService: editPopupDiscount dari UI (diabaikan): $editPopupDiscount');

      // Compound discount calculation hanya dari discountPercentages
      final List<double> allDiscounts =
          discountPercentages.where((d) => d > 0.0).toList();
      double compound = 1.0;
      for (final d in allDiscounts) {
        compound *= (1 - d / 100);
      }
      double totalCompoundDiscount = 1 - compound;
      final discountText = (totalCompoundDiscount * 100).toStringAsFixed(2);

      print('ApprovalService: Final allDiscounts to compound: $allDiscounts');
      print(
          'ApprovalService: Compound discount calculation: diskon = $allDiscounts, hasil = $discountText%');

      // Create Order Letter (header)
      final orderLetter = OrderLetterModel(
        orderDate: currentDate,
        creator: userName,
        customerName: customerName,
        phone: customerPhone,
        discount: discountText,
        discountDetail: discountText.isEmpty ? '0' : discountText,
        hargaAwal: product.pricelist.toInt(),
        keterangan: product.isSet ? 'Set' : 'Tidak Set',
        extendedAmount: netPrice * quantity,
        status: 'Pending',
      );

      // Debug logging
      print('ApprovalService: Order letter discount: ${orderLetter.discount}');
      print('ApprovalService: Order letter toJson: ${orderLetter.toJson()}');

      // Create Order Letter Details
      final List<OrderLetterDetailModel> details = [];

      // Add main product (kasur) - only if exists
      if (product.kasur.isNotEmpty && product.kasur != 'Tidak ada kasur') {
        details.add(OrderLetterDetailModel(
          qty: quantity,
          unitPrice: netPrice.toInt(),
          itemNumber: product.itemNumberKasur ??
              product.itemNumber ??
              product.id.toString(),
          desc1: product.kasur,
          desc2: product.ukuran,
          brand: product.brand,
          itemType: netPrice.toString(),
        ));
      }

      // Add divan if exists and not empty
      if (product.divan.isNotEmpty &&
          product.divan != 'Tidak ada divan' &&
          product.plDivan > 0) {
        details.add(OrderLetterDetailModel(
          qty: quantity,
          unitPrice: product.plDivan.toInt(),
          itemNumber: product.itemNumberDivan ?? product.id.toString(),
          desc1: product.divan,
          desc2: product.ukuran,
          brand: product.brand,
          itemType: product.plDivan.toString(),
        ));
      }

      // Add headboard if exists and not empty
      if (product.headboard.isNotEmpty &&
          product.headboard != 'Tidak ada headboard' &&
          product.plHeadboard > 0) {
        details.add(OrderLetterDetailModel(
          qty: quantity,
          unitPrice: product.plHeadboard.toInt(),
          itemNumber: product.itemNumberHeadboard ?? product.id.toString(),
          desc1: product.headboard,
          desc2: product.ukuran,
          brand: product.brand,
          itemType: product.plHeadboard.toString(),
        ));
      }

      // Add sorong if exists and not empty
      if (product.sorong.isNotEmpty &&
          product.sorong != 'Tidak ada sorong' &&
          product.plSorong > 0) {
        details.add(OrderLetterDetailModel(
          qty: quantity,
          unitPrice: product.plSorong.toInt(),
          itemNumber: product.itemNumberSorong ?? product.id.toString(),
          desc1: product.sorong,
          desc2: product.ukuran,
          brand: product.brand,
          itemType: product.plSorong.toString(),
        ));
      }

      // Add bonuses if exists and have item numbers
      for (int i = 0; i < product.bonus.length; i++) {
        final bonus = product.bonus[i];
        if (bonus.name.isNotEmpty && bonus.quantity > 0) {
          // Get corresponding item number for bonus
          String? bonusItemNumber;
          switch (i) {
            case 0:
              bonusItemNumber = product.itemNumberBonus1;
              break;
            case 1:
              bonusItemNumber = product.itemNumberBonus2;
              break;
            case 2:
              bonusItemNumber = product.itemNumberBonus3;
              break;
            case 3:
              bonusItemNumber = product.itemNumberBonus4;
              break;
            case 4:
              bonusItemNumber = product.itemNumberBonus5;
              break;
          }

          if (bonusItemNumber != null && bonusItemNumber.isNotEmpty) {
            details.add(OrderLetterDetailModel(
              qty: bonus.quantity,
              unitPrice: 0, // Bonus items are free
              itemNumber: bonusItemNumber,
              desc1: bonus.name,
              desc2: 'Bonus',
              brand: product.brand,
              itemType: 'Bonus',
            ));
          }
        }
      }

      // Call approval bloc to create approval
      final approvalBloc = locator<ApprovalBloc>();
      approvalBloc.add(CreateApproval(
        orderLetter: orderLetter,
        details: details,
        discounts: allDiscounts,
      ));

      return {
        'success': true,
        'message': 'Approval request sent successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }
}
