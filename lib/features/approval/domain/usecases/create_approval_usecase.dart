import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';
import '../../data/repositories/approval_repository.dart';

class CreateApprovalUseCase {
  final ApprovalRepository repository;

  CreateApprovalUseCase({required this.repository});

  Future<Map<String, dynamic>> execute({
    required OrderLetterModel orderLetter,
    required List<OrderLetterDetailModel> details,
    required List<double> discounts,
  }) async {
    try {
      // Use the new createApproval method that handles everything
      return await repository.createApproval(
        orderLetter: orderLetter,
        details: details,
        discounts: discounts,
      );
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating approval: $e',
      };
    }
  }
}
 