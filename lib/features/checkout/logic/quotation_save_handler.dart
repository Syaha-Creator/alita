import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_feedback.dart';
import '../../cart/data/cart_item.dart';
import '../../cart/logic/cart_provider.dart';
import '../../profile/logic/profile_provider.dart';
import '../../quotation/data/quotation_model.dart';
import '../../quotation/logic/quotation_list_provider.dart';

/// Encapsulates the "Simpan Penawaran" logic from the checkout page.
///
/// Extracted to keep [CheckoutPage] focused on order submission UI.
abstract final class QuotationSaveHandler {
  /// Validates input, builds a [QuotationModel], persists it locally,
  /// clears the cart, and navigates to the quotation history.
  ///
  /// Returns `true` if the save was successful.
  static Future<bool> save({
    required BuildContext context,
    required List<CartItem> cartItems,
    required List<CartItem>? selectedCartItems,
    required QuotationModel? existingDraft,
    /// When `true`, the caller was pushed on top of quotation_history, so
    /// we only need to pop back instead of pushing a replacement route
    /// (which would create a duplicate quotation_history in the stack).
    bool popBackToHistory = false,
    // Customer
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerPhone2,
    required String customerAddress,
    // Region
    required String? regionProvinsi,
    required String? regionKota,
    required String? regionKecamatan,
    required String regionText,
    // Shipping
    required bool isShippingSameAsCustomer,
    required String shippingName,
    required String shippingPhone,
    required String shippingPhone2,
    required String shippingAddress,
    required String? shippingRegionProvinsi,
    required String? shippingRegionKota,
    required String? shippingRegionKecamatan,
    required String shippingRegionText,
    // Delivery
    required DateTime orderDate,
    required DateTime? requestDate,
    required bool isTakeAway,
    required String postage,
    required String scCode,
    // Totals
    required double grandTotal,
    required double totalAkhir,
    // Notes
    required String notes,
  }) async {
    if (cartItems.isEmpty) return false;

    if (customerName.isEmpty) {
      AppFeedback.show(context,
          message: 'Nama pelanggan wajib diisi untuk penawaran',
          type: AppFeedbackType.warning);
      return false;
    }

    if (!context.mounted) return false;
    // Jangan pakai [WidgetRef] setelah await: jika user keluar dari checkout
    // saat penyimpanan berjalan, ref.read melempar. Container dari scope tetap valid.
    final container = ProviderScope.containerOf(context, listen: false);

    final profile = container.read(profileProvider).valueOrNull;
    final isUpdate = existingDraft != null;

    final quotation = QuotationModel(
      id: isUpdate
          ? existingDraft.id
          : DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
              cartItems.length.toRadixString(36),
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      customerPhone2: customerPhone2,
      customerAddress: customerAddress,
      regionProvinsi: regionProvinsi ?? '',
      regionKota: regionKota ?? '',
      regionKecamatan: regionKecamatan ?? '',
      regionText: regionText,
      isShippingSameAsCustomer: isShippingSameAsCustomer,
      shippingName: shippingName,
      shippingPhone: shippingPhone,
      shippingPhone2: shippingPhone2,
      shippingAddress: shippingAddress,
      shippingRegionProvinsi: shippingRegionProvinsi ?? '',
      shippingRegionKota: shippingRegionKota ?? '',
      shippingRegionKecamatan: shippingRegionKecamatan ?? '',
      shippingRegionText: shippingRegionText,
      orderDate: orderDate.toIso8601String(),
      requestDate: requestDate?.toIso8601String(),
      isTakeAway: isTakeAway,
      postage: postage,
      scCode: scCode,
      workPlaceName: profile?.workPlaceName ?? '',
      salesName: profile?.name ?? '',
      items: List.of(cartItems),
      subtotal: grandTotal,
      discount: 0,
      totalPrice: totalAkhir,
      notes: notes,
      createdAt: isUpdate ? existingDraft.createdAt : DateTime.now(),
      validUntil: DateTime.now().add(const Duration(days: 14)),
    );

    final notifier = container.read(quotationListProvider.notifier);
    if (isUpdate) {
      await notifier.update(quotation);
    } else {
      await notifier.add(quotation);
    }

    if (selectedCartItems != null && selectedCartItems.isNotEmpty) {
      await container.read(cartProvider.notifier).removeItemsByIds(
            selectedCartItems.map(cartItemKey).toSet(),
          );
    } else {
      await container.read(cartProvider.notifier).clearCart();
    }

    container.read(activeDraftProvider.notifier).state = null;

    if (!context.mounted) return true;
    AppFeedback.show(context,
        message: isUpdate
            ? 'Penawaran berhasil diperbarui!'
            : 'Penawaran berhasil disimpan!',
        type: AppFeedbackType.success);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return true;

    if (popBackToHistory) {
      Navigator.of(context).pop();
    } else {
      context.pushReplacement('/quotation_history', extra: quotation);
    }
    return true;
  }
}
