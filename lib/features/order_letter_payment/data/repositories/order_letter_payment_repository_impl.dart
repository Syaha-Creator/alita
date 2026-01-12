import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/order_letter_payment_repository.dart';
import '../datasources/order_letter_payment_remote_data_source.dart';

/// Repository implementation untuk order letter payment
class OrderLetterPaymentRepositoryImpl
    implements OrderLetterPaymentRepository {
  final OrderLetterPaymentRemoteDataSource remoteDataSource;

  OrderLetterPaymentRepositoryImpl({required this.remoteDataSource});

  @override
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
  }) async {
    try {
      return await remoteDataSource.createPayment(
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
    } on ServerException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw ServerException('An unknown error occurred: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> uploadPaymentMethods({
    required int orderLetterId,
    required List<Map<String, dynamic>> paymentMethods,
    required int creator,
    String? note,
  }) async {
    try {
      return await remoteDataSource.uploadPaymentMethods(
        orderLetterId: orderLetterId,
        paymentMethods: paymentMethods,
        creator: creator,
        note: note,
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
  }) async {
    return await createPayment(
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

