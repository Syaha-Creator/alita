/// Repository interface untuk order letter payment operations
abstract class OrderLetterPaymentRepository {
  /// Create single payment dengan image upload (multipart/form-data)
  Future<Map<String, dynamic>> createPayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
    String? receiptImagePath,
    String? paymentDate,
  });

  /// Upload all payment methods for an order letter
  Future<List<Map<String, dynamic>>> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  });

  /// Upload single payment method (wrapper untuk createPayment)
  Future<Map<String, dynamic>> uploadSinglePayment({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
    String? receiptImagePath,
    String? paymentDate,
  });
}

