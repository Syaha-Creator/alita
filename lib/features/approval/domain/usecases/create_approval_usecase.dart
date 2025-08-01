import '../../data/repositories/approval_repository.dart';

class CreateApprovalUseCase {
  final ApprovalRepository repository;

  CreateApprovalUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required int orderLetterId,
    required String action, // approve/reject
    required String approverName,
    required String approverEmail,
    String? comment,
  }) async {
    return await repository.createApproval(
      orderLetterId: orderLetterId,
      action: action,
      approverName: approverName,
      approverEmail: approverEmail,
      comment: comment,
    );
  }
}
