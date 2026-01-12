import '../../../../services/order_letter_service.dart';

/// Remote data source untuk approval API calls
/// Menggunakan OrderLetterService untuk backward compatibility
abstract class ApprovalRemoteDataSource {
  Future<List<Map<String, dynamic>>> getOrderLetters({
    String? dateFrom,
    String? dateTo,
  });
  Future<List<Map<String, dynamic>>> getOrderLetterDetails({
    required int orderLetterId,
  });
  Future<List<Map<String, dynamic>>> getOrderLetterDiscounts({
    required int orderLetterId,
  });
  Future<List<Map<String, dynamic>>> getOrderLetterApproves({
    required int orderLetterId,
  });
  Future<Map<String, dynamic>> createOrderLetterApprove(
    Map<String, dynamic> approvalData,
  );
}

class ApprovalRemoteDataSourceImpl implements ApprovalRemoteDataSource {
  final OrderLetterService orderLetterService;

  ApprovalRemoteDataSourceImpl({required this.orderLetterService});

  @override
  Future<List<Map<String, dynamic>>> getOrderLetters({
    String? dateFrom,
    String? dateTo,
  }) async {
    return await orderLetterService.getOrderLetters(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderLetterDetails({
    required int orderLetterId,
  }) async {
    return await orderLetterService.getOrderLetterDetails(
      orderLetterId: orderLetterId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderLetterDiscounts({
    required int orderLetterId,
  }) async {
    return await orderLetterService.getOrderLetterDiscounts(
      orderLetterId: orderLetterId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderLetterApproves({
    required int orderLetterId,
  }) async {
    return await orderLetterService.getOrderLetterApproves(
      orderLetterId: orderLetterId,
    );
  }

  @override
  Future<Map<String, dynamic>> createOrderLetterApprove(
    Map<String, dynamic> approvalData,
  ) async {
    return await orderLetterService.createOrderLetterApprove(approvalData);
  }
}

