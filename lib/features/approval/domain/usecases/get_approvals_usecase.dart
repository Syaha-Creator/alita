import '../../data/repositories/approval_repository.dart';
import '../../data/models/order_letter_model.dart';
import '../../data/models/order_letter_detail_model.dart';

class GetApprovalsUseCase {
  final ApprovalRepository repository;

  GetApprovalsUseCase({required this.repository});

  Future<Map<String, List>> call({String? creator}) async {
    try {
      final orderLetters = await repository.getOrderLetters(creator: creator);
      final orderLetterDetails = await repository.getOrderLetterDetails();

      return {
        'orderLetters': orderLetters,
        'orderLetterDetails': orderLetterDetails,
      };
    } catch (e) {
      return {
        'orderLetters': <OrderLetterModel>[],
        'orderLetterDetails': <OrderLetterDetailModel>[],
      };
    }
  }
}
