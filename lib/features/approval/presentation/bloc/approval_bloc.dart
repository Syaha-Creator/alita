import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_approval_usecase.dart';
import '../../domain/usecases/get_approvals_usecase.dart';
import 'approval_event.dart';
import 'approval_state.dart';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final CreateApprovalUseCase createApprovalUseCase;
  final GetApprovalsUseCase getApprovalsUseCase;

  ApprovalBloc({
    required this.createApprovalUseCase,
    required this.getApprovalsUseCase,
  }) : super(ApprovalInitial()) {
    on<CreateApproval>(_onCreateApproval);
    on<GetApprovals>(_onGetApprovals);
    on<ClearApprovalState>(_onClearApprovalState);
  }

  Future<void> _onCreateApproval(
      CreateApproval event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final result = await createApprovalUseCase.execute(
        orderLetter: event.orderLetter,
        details: event.details,
        discounts: event.discounts,
      );

      if (result['success'] == true) {
        emit(ApprovalSuccess(
          message: 'Approval created successfully',
          result: result,
        ));
      } else {
        emit(ApprovalError(
            message: result['message'] ?? 'Failed to create approval'));
      }
    } catch (e) {
      emit(ApprovalError(message: 'Error creating approval: $e'));
    }
  }

  Future<void> _onGetApprovals(
      GetApprovals event, Emitter<ApprovalState> emit) async {
    emit(ApprovalLoading());
    try {
      final result = await getApprovalsUseCase(creator: event.creator);

      final orderLetters = result['orderLetters'] as List;
      final orderLetterDetails = result['orderLetterDetails'] as List;

      emit(ApprovalsLoaded(
        orderLetters: orderLetters.cast(),
        orderLetterDetails: orderLetterDetails.cast(),
      ));
    } catch (e) {
      emit(ApprovalError(message: 'Error fetching approvals: $e'));
    }
  }

  void _onClearApprovalState(
      ClearApprovalState event, Emitter<ApprovalState> emit) {
    emit(ApprovalInitial());
  }
}
