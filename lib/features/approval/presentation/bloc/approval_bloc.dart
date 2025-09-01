import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/dependency_injection.dart';
import '../../../../services/unified_notification_service.dart';
import '../../domain/entities/approval_entity.dart';
import '../../domain/usecases/get_approvals_usecase.dart';
import '../../domain/usecases/create_approval_usecase.dart';
import 'approval_event.dart';
import 'approval_state.dart';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final GetApprovalsUseCase _getApprovalsUseCase;
  final GetApprovalByIdUseCase _getApprovalByIdUseCase;
  final GetPendingApprovalsUseCase _getPendingApprovalsUseCase;
  final GetApprovedApprovalsUseCase _getApprovedApprovalsUseCase;
  final GetRejectedApprovalsUseCase _getRejectedApprovalsUseCase;
  final CreateApprovalUseCase _createApprovalUseCase;
  // Removed ApprovalNotificationService - using UnifiedNotificationService instead
  final UnifiedNotificationService _unifiedNotificationService;

  ApprovalBloc()
      : _getApprovalsUseCase = locator<GetApprovalsUseCase>(),
        _getApprovalByIdUseCase = locator<GetApprovalByIdUseCase>(),
        _getPendingApprovalsUseCase = locator<GetPendingApprovalsUseCase>(),
        _getApprovedApprovalsUseCase = locator<GetApprovedApprovalsUseCase>(),
        _getRejectedApprovalsUseCase = locator<GetRejectedApprovalsUseCase>(),
        _createApprovalUseCase = locator<CreateApprovalUseCase>(),
        // Removed ApprovalNotificationService initialization
        _unifiedNotificationService = locator<UnifiedNotificationService>(),
        super(ApprovalInitial()) {
    on<LoadApprovals>(_onLoadApprovals);
    on<LoadPendingApprovals>(_onLoadPendingApprovals);
    on<LoadApprovedApprovals>(_onLoadApprovedApprovals);
    on<LoadRejectedApprovals>(_onLoadRejectedApprovals);
    on<LoadApprovalById>(_onLoadApprovalById);
    on<CreateApproval>(_onCreateApproval);
    on<RefreshApprovals>(_onRefreshApprovals);
    on<FilterApprovals>(_onFilterApprovals);
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
          await _unifiedNotificationService.handleApprovalFlow(
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
            await _unifiedNotificationService.handleApprovalFlow(
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
            print('Error sending fallback notification: $fallbackError');
          }
        }

        // Refresh the approvals list
        add(const RefreshApprovals());
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
}
