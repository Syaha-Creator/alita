import '../entities/cart_entity.dart';

/// Repository interface untuk checkout operations
/// Mengikuti Clean Architecture - domain layer tidak bergantung pada data layer
abstract class CheckoutRepository {
  /// Create order letter dengan item mapping
  /// Returns Map dengan keys: success, orderLetterId, noSp, message
  Future<Map<String, dynamic>> createOrderLetter({
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
    // Manually selected approvers
    int? selectedSpvId,
    String? selectedSpvName,
    int? selectedRsmId,
    String? selectedRsmName,
  });

  /// Upload phone numbers untuk order letter
  Future<void> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  });

  /// Upload payment methods untuk order letter
  Future<void> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  });

  /// Save draft checkout ke local storage
  Future<void> saveDraft({
    required Map<String, dynamic> draftData,
    required int userId,
  });

  /// Load draft checkout dari local storage
  Future<Map<String, dynamic>?> loadDraft({required int userId});

  /// Delete draft checkout
  Future<void> deleteDraft({required int userId});
}

