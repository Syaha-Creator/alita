import '../repositories/checkout_repository.dart';

/// Use case untuk save draft checkout
class SaveDraftUseCase {
  final CheckoutRepository repository;

  SaveDraftUseCase({required this.repository});

  /// Save draft dengan error handling
  Future<SaveDraftResult> call(SaveDraftParams params) async {
    try {
      await repository.saveDraft(
        draftData: params.draftData,
        userId: params.userId,
      );

      return SaveDraftResult.success();
    } catch (e) {
      return SaveDraftResult.failure(
        'Gagal menyimpan draft: ${e.toString()}',
      );
    }
  }
}

/// Parameters untuk save draft
class SaveDraftParams {
  final Map<String, dynamic> draftData;
  final int userId;

  SaveDraftParams({
    required this.draftData,
    required this.userId,
  });
}

/// Result dari save draft operation
class SaveDraftResult {
  final bool isSuccess;
  final String? errorMessage;

  SaveDraftResult._({
    required this.isSuccess,
    this.errorMessage,
  });

  factory SaveDraftResult.success() {
    return SaveDraftResult._(isSuccess: true);
  }

  factory SaveDraftResult.failure(String message) {
    return SaveDraftResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

