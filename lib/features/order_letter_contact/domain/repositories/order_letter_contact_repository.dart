/// Repository interface untuk order letter contact operations
abstract class OrderLetterContactRepository {
  /// Create single phone contact
  Future<Map<String, dynamic>> createPhoneContact({
    required int orderLetterId,
    required String phoneNumber,
  });

  /// Upload all phone numbers for an order letter
  Future<List<Map<String, dynamic>>> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  });
}
