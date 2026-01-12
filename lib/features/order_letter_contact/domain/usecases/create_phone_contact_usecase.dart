import '../repositories/order_letter_contact_repository.dart';

/// Use case untuk create single phone contact
class CreatePhoneContactUseCase {
  final OrderLetterContactRepository repository;

  CreatePhoneContactUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required int orderLetterId,
    required String phoneNumber,
  }) async {
    return await repository.createPhoneContact(
      orderLetterId: orderLetterId,
      phoneNumber: phoneNumber,
    );
  }
}
