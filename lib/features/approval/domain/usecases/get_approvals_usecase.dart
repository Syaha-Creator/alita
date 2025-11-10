import '../entities/approval_entity.dart';
import '../../data/repositories/approval_repository.dart';

class GetApprovalsUseCase {
  final ApprovalRepository repository;

  GetApprovalsUseCase(this.repository);

  Future<List<ApprovalEntity>> call({
    String? creator,
    bool forceRefresh = false,
  }) async {
    return await repository.getApprovals(
      creator: creator,
      forceRefresh: forceRefresh,
    );
  }
}

class GetApprovalByIdUseCase {
  final ApprovalRepository repository;

  GetApprovalByIdUseCase(this.repository);

  Future<ApprovalEntity?> call(int orderLetterId) async {
    return await repository.getApprovalById(orderLetterId);
  }
}

class GetPendingApprovalsUseCase {
  final ApprovalRepository repository;

  GetPendingApprovalsUseCase(this.repository);

  Future<List<ApprovalEntity>> call() async {
    return await repository.getPendingApprovals();
  }
}

class GetApprovedApprovalsUseCase {
  final ApprovalRepository repository;

  GetApprovedApprovalsUseCase(this.repository);

  Future<List<ApprovalEntity>> call() async {
    return await repository.getApprovedApprovals();
  }
}

class GetRejectedApprovalsUseCase {
  final ApprovalRepository repository;

  GetRejectedApprovalsUseCase(this.repository);

  Future<List<ApprovalEntity>> call() async {
    return await repository.getRejectedApprovals();
  }
}
