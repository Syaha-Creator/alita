import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/order_letter_contact_repository.dart';
import '../datasources/order_letter_contact_remote_data_source.dart';

/// Repository implementation untuk order letter contact
class OrderLetterContactRepositoryImpl implements OrderLetterContactRepository {
  final OrderLetterContactRemoteDataSource remoteDataSource;

  OrderLetterContactRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> createPhoneContact({
    required int orderLetterId,
    required String phoneNumber,
  }) async {
    try {
      return await remoteDataSource.createPhoneContact(
        orderLetterId: orderLetterId,
        phoneNumber: phoneNumber,
      );
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('An unknown error occurred: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> uploadPhoneNumbers({
    required int orderLetterId,
    required String primaryPhone,
    String? secondaryPhone,
  }) async {
    try {
      return await remoteDataSource.uploadPhoneNumbers(
        orderLetterId: orderLetterId,
        primaryPhone: primaryPhone,
        secondaryPhone: secondaryPhone,
      );
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('An unknown error occurred: ${e.toString()}');
    }
  }
}
