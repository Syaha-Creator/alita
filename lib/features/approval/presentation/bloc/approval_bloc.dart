import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/core_notification_service.dart';
import '../../domain/entities/approval_entity.dart';
import '../../domain/usecases/get_approvals_usecase.dart';
import '../../domain/usecases/create_approval_usecase.dart';
import '../../data/repositories/approval_repository.dart';
import 'approval_event.dart';
import 'approval_state.dart';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final GetApprovalsUseCase _getApprovalsUseCase;
  final GetApprovalByIdUseCase _getApprovalByIdUseCase;
  final GetPendingApprovalsUseCase _getPendingApprovalsUseCase;
  final GetApprovedApprovalsUseCase _getApprovedApprovalsUseCase;
  final GetRejectedApprovalsUseCase _getRejectedApprovalsUseCase;
  final CreateApprovalUseCase _createApprovalUseCase;
  // Using consolidated CoreNotificationService
  final CoreNotificationService _coreNotificationService;

  ApprovalBloc()
      : _getApprovalsUseCase = locator<GetApprovalsUseCase>(),
        _getApprovalByIdUseCase = locator<GetApprovalByIdUseCase>(),
        _getPendingApprovalsUseCase = locator<GetPendingApprovalsUseCase>(),
        _getApprovedApprovalsUseCase = locator<GetApprovedApprovalsUseCase>(),
        _getRejectedApprovalsUseCase = locator<GetRejectedApprovalsUseCase>(),
        _createApprovalUseCase = locator<CreateApprovalUseCase>(),
        // Using consolidated CoreNotificationService
        _coreNotificationService = locator<CoreNotificationService>(),
        super(ApprovalInitial()) {
    on<LoadApprovals>(_onLoadApprovals);
    on<LoadPendingApprovals>(_onLoadPendingApprovals);
    on<LoadApprovedApprovals>(_onLoadApprovedApprovals);
    on<LoadRejectedApprovals>(_onLoadRejectedApprovals);
    on<LoadApprovalById>(_onLoadApprovalById);
    on<CreateApproval>(_onCreateApproval);
    on<RefreshApprovals>(_onRefreshApprovals);
    on<FilterApprovals>(_onFilterApprovals);
    on<UpdateSingleApproval>(_onUpdateSingleApproval);
    on<LoadNewApprovalsIncremental>(_onLoadNewApprovalsIncremental);
    on<UpdateApprovalStatusesOnly>(_onUpdateApprovalStatusesOnly);
  }

  Future<void> _onLoadApprovals(
      LoadApprovals event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      final approvals = await _getApprovalsUseCase(creator: event.creator);

      if (approvals.isEmpty) {
        emit(const ApprovalEmpty('Tidak ada data approval'));
      } else {
        emit(ApprovalLoaded(approvals: approvals));
      }
    } catch (e) {
      emit(ApprovalError('Gagal memuat data approval: $e'));
    }
  }

  Future<void> _onLoadPendingApprovals(
      LoadPendingApprovals event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      final approvals = await _getPendingApprovalsUseCase();

      if (approvals.isEmpty) {
        emit(const ApprovalEmpty('Tidak ada approval yang pending'));
      } else {
        emit(ApprovalLoaded(approvals: approvals, filterStatus: 'Pending'));
      }
    } catch (e) {
      emit(ApprovalError('Gagal memuat approval pending: $e'));
    }
  }

  Future<void> _onLoadApprovedApprovals(
      LoadApprovedApprovals event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      final approvals = await _getApprovedApprovalsUseCase();

      if (approvals.isEmpty) {
        emit(const ApprovalEmpty('Tidak ada approval yang disetujui'));
      } else {
        emit(ApprovalLoaded(approvals: approvals, filterStatus: 'Approved'));
      }
    } catch (e) {
      emit(ApprovalError('Gagal memuat approval disetujui: $e'));
    }
  }

  Future<void> _onLoadRejectedApprovals(
      LoadRejectedApprovals event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      final approvals = await _getRejectedApprovalsUseCase();

      if (approvals.isEmpty) {
        emit(const ApprovalEmpty('Tidak ada approval yang ditolak'));
      } else {
        emit(ApprovalLoaded(approvals: approvals, filterStatus: 'Rejected'));
      }
    } catch (e) {
      emit(ApprovalError('Gagal memuat approval ditolak: $e'));
    }
  }

  Future<void> _onLoadApprovalById(
      LoadApprovalById event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      final approval = await _getApprovalByIdUseCase(event.orderLetterId);

      if (approval == null) {
        emit(const ApprovalError('Approval tidak ditemukan'));
      } else {
        emit(ApprovalDetailLoaded(approval));
      }
    } catch (e) {
      emit(ApprovalError('Gagal memuat detail approval: $e'));
    }
  }

  Future<void> _onCreateApproval(
      CreateApproval event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalActionLoading(event.orderLetterId));

      final result = await _createApprovalUseCase(
        orderLetterId: event.orderLetterId,
        action: event.action,
        approverName: event.approverName,
        approverEmail: event.approverEmail,
        comment: event.comment,
      );

      if (result['success']) {
        emit(ApprovalActionSuccess(
          message: result['message'] ?? 'Approval berhasil dibuat',
          orderLetterId: event.orderLetterId,
        ));

        // Send notification to next level leader
        try {
          // Use new approval flow notification service
          await _coreNotificationService.handleApprovalFlowNotification(
            orderLetterId: event.orderLetterId.toString(),
            approverUserId: result['approver_user_id'] ?? '',
            approverName: event.approverName,
            approvalAction: event.action,
            approvalLevel: result['approval_level'] ?? 'Current Level',
            comment: event.comment,
            customerName: result['customer_name'] ?? '',
            totalAmount: result['total_amount'] != null
                ? double.tryParse(result['total_amount'].toString())
                : null,
          );
        } catch (e) {
          // Log error but don't fail the approval
          print('Error sending approval flow notification: $e');

          // Fallback to unified notification service
          try {
            await _coreNotificationService.handleApprovalFlowNotification(
              orderLetterId: event.orderLetterId.toString(),
              approverUserId: result['approver_user_id'] ?? '',
              approverName: event.approverName,
              approvalAction: event.action,
              approvalLevel: result['approval_level'] ?? 'Current Level',
              comment: event.comment,
              customerName: result['customer_name'] ?? '',
              totalAmount: result['total_amount'] != null
                  ? double.tryParse(result['total_amount'].toString())
                  : null,
            );
          } catch (fallbackError) {
            // Silent error handling for fallback notification
          }
        }

        // Update only this specific approval instead of full refresh
        add(UpdateSingleApproval(event.orderLetterId));
      } else {
        emit(ApprovalActionError(
          message: result['message'] ?? 'Gagal membuat approval',
          orderLetterId: event.orderLetterId,
        ));
      }
    } catch (e) {
      emit(ApprovalActionError(
        message: 'Error: $e',
        orderLetterId: event.orderLetterId,
      ));
    }
  }

  Future<void> _onRefreshApprovals(
      RefreshApprovals event, Emitter<ApprovalState> emit) async {
    try {
      final approvals = await _getApprovalsUseCase(creator: event.creator);

      if (approvals.isEmpty) {
        emit(const ApprovalEmpty('Tidak ada data approval'));
      } else {
        emit(ApprovalLoaded(approvals: approvals));
      }
    } catch (e) {
      emit(ApprovalError('Gagal refresh data approval: $e'));
    }
  }

  Future<void> _onFilterApprovals(
      FilterApprovals event, Emitter<ApprovalState> emit) async {
    try {
      emit(ApprovalLoading());

      List<ApprovalEntity> approvals;

      switch (event.status.toLowerCase()) {
        case 'pending':
          approvals = await _getPendingApprovalsUseCase();
          break;
        case 'approved':
          approvals = await _getApprovedApprovalsUseCase();
          break;
        case 'rejected':
          approvals = await _getRejectedApprovalsUseCase();
          break;
        default:
          approvals = await _getApprovalsUseCase();
          break;
      }

      if (approvals.isEmpty) {
        emit(ApprovalEmpty('Tidak ada approval dengan status ${event.status}'));
      } else {
        emit(ApprovalLoaded(approvals: approvals, filterStatus: event.status));
      }
    } catch (e) {
      emit(ApprovalError('Gagal filter approval: $e'));
    }
  }

  Future<void> _onUpdateSingleApproval(
      UpdateSingleApproval event, Emitter<ApprovalState> emit) async {
    try {
      // Get current state
      final currentState = state;
      if (currentState is! ApprovalLoaded) {
        // If not loaded, do full load instead
        add(LoadApprovals());
        return;
      }

      // Update specific approval
      final repository = locator<ApprovalRepository>();
      final updatedApproval =
          await repository.updateSingleApproval(event.orderLetterId);

      if (updatedApproval != null) {
        // Update the specific item in current state
        final updatedApprovals = currentState.approvals.map((approval) {
          if (approval.id == event.orderLetterId) {
            return updatedApproval;
          }
          return approval;
        }).toList();

        // Emit updated state without full loading
        emit(ApprovalLoaded(
          approvals: updatedApprovals,
          filterStatus: currentState.filterStatus,
        ));
      }
    } catch (e) {
      // If selective update fails, don't emit error - just skip
      // User can still pull-to-refresh for full update
    }
  }

  Future<void> _onLoadNewApprovalsIncremental(
      LoadNewApprovalsIncremental event, Emitter<ApprovalState> emit) async {
    try {
      // Get current state
      final currentState = state;
      if (currentState is! ApprovalLoaded) {
        // If not loaded, do full load instead
        add(LoadApprovals());
        return;
      }

      // Load new approvals incrementally
      final repository = locator<ApprovalRepository>();
      final updatedApprovals = await repository.loadNewApprovalsIncremental();

      // Emit updated state with new approvals at top
      emit(ApprovalLoaded(
        approvals: updatedApprovals,
        filterStatus: currentState.filterStatus,
      ));
    } catch (e) {
      // If incremental load fails, don't emit error - just skip
      // User can still pull-to-refresh for full update
    }
  }

  Future<void> _onUpdateApprovalStatusesOnly(
      UpdateApprovalStatusesOnly event, Emitter<ApprovalState> emit) async {
    try {
      // Get current state
      final currentState = state;
      if (currentState is! ApprovalLoaded) {
        // If not loaded, skip update
        return;
      }

      // Update only approval statuses (lightweight operation)
      final repository = locator<ApprovalRepository>();
      final updatedApprovals = await repository.updateApprovalStatusesOnly();

      // Emit updated state with same data but updated statuses
      emit(ApprovalLoaded(
        approvals: updatedApprovals,
        filterStatus: currentState.filterStatus,
      ));
    } catch (e) {
      // If status update fails, don't emit error - just skip
      // User can still pull-to-refresh for full update
    }
  }
}
