import '../repositories/order_letter_payment_repository.dart';

/// Use case untuk create single payment
class CreatePaymentUseCase {
  final OrderLetterPaymentRepository repository;

  CreatePaymentUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required int orderLetterId,
    required String paymentMethod,
    required String paymentBank,
    required String paymentNumber,
    required double paymentAmount,
    required int creator,
    String? note,
    String? receiptImagePath,
    String? paymentDate,
  }) async {
    return await repository.createPayment(
      orderLetterId: orderLetterId,
      paymentMethod: paymentMethod,
      paymentBank: paymentBank,
      paymentNumber: paymentNumber,
      paymentAmount: paymentAmount,
      creator: creator,
      note: note,
      receiptImagePath: receiptImagePath,
      paymentDate: paymentDate,
    );
  }
}

