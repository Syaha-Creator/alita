import '../repositories/order_letter_payment_repository.dart';

/// Use case untuk upload multiple payment methods
class UploadPaymentMethodsUseCase {
  final OrderLetterPaymentRepository repository;

  UploadPaymentMethodsUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  }) async {
    return await repository.uploadPaymentMethods(
      orderLetterId: orderLetterId,
      paymentMethods: paymentMethods,
      creator: creator,
      note: note,
    );
  }
}

