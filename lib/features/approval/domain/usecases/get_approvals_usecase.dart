import '../../data/repositories/approval_repository.dart';

class GetApprovalsUseCase {
  final ApprovalRepository repository;

  GetApprovalsUseCase({required this.repository});

  Future<Map<String, dynamic>> call({String? creator}) async {
    return await repository.getApprovals(creator: creator);
  }
}
 