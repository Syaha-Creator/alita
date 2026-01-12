import '../../../../core/error/exceptions.dart';
import '../datasources/order_letter_document_remote_data_source.dart';
import '../models/order_letter_document_model.dart';

/// Repository implementation untuk order letter document
/// Menggunakan remote datasource sesuai Clean Architecture
class OrderLetterDocumentRepository {
  final OrderLetterDocumentRemoteDataSource remoteDataSource;

  OrderLetterDocumentRepository({required this.remoteDataSource});

  /// Get complete order letter document data including details, discounts, and approvals
  Future<OrderLetterDocumentModel?> getOrderLetterDocument(
    int orderLetterId,
  ) async {
    try {
      return await remoteDataSource.getOrderLetterDocument(orderLetterId);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Gagal memuat dokumen: ${e.toString()}');
    }
  }

  /// Get all order letters for current user
  Future<List<OrderLetterDocumentModel>> getOrderLetters() async {
    try {
      return await remoteDataSource.getOrderLetters();
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      // Return empty list on error (backward compatible)
      return [];
    }
  }
}
