import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';
import '../../data/repositories/approval_repository.dart';

class CreateApprovalUseCase {
  final ApprovalRepository repository;

  CreateApprovalUseCase({required this.repository});

  Future<Map<String, dynamic>> execute({
    required OrderLetterModel orderLetter,
    required List<OrderLetterDetailModel> details,
  }) async {
    try {
      // 1. Create Order Letter (header)
      final orderLetterResult = await repository.createOrderLetter(orderLetter);

      if (!orderLetterResult['success']) {
        return orderLetterResult;
      }

      final orderLetterId = orderLetterResult['orderLetterId'];
      final noSp = orderLetterResult['noSp'];

      // 2. Create Order Letter Details (loop per item)
      final List<Map<String, dynamic>> detailResults = [];

      for (final detail in details) {
        // Update detail with order letter id and no_sp
        final updatedDetail = OrderLetterDetailModel(
          orderLetterId: orderLetterId,
          noSp: noSp,
          qty: detail.qty,
          unitPrice: detail.unitPrice,
          itemNumber: detail.itemNumber,
          desc1: detail.desc1,
          desc2: detail.desc2,
          brand: detail.brand,
          itemType: detail.itemType,
        );

        final detailResult =
            await repository.createOrderLetterDetail(updatedDetail);
        detailResults.add(detailResult);

        // If any detail fails, return error
        if (!detailResult['success']) {
          return {
            'success': false,
            'message': 'Failed to create detail: ${detailResult['message']}',
            'orderLetterResult': orderLetterResult,
            'detailResults': detailResults,
          };
        }
      }

      return {
        'success': true,
        'message': 'Approval created successfully',
        'orderLetterResult': orderLetterResult,
        'detailResults': detailResults,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }
}
