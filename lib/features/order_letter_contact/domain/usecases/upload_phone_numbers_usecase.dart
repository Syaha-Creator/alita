import '../repositories/order_letter_contact_repository.dart';

/// Use case untuk upload multiple phone numbers
class UploadPhoneNumbersUseCase {
  final OrderLetterContactRepository repository;

  UploadPhoneNumbersUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  }) async {
    return await repository.uploadPhoneNumbers(
      orderLetterId: orderLetterId,
      primaryPhone: primaryPhone,
      secondaryPhone: secondaryPhone,
    );
  }
}
