import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/enums/order_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/contact_actions.dart';
import '../../../../core/utils/name_matcher.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_telemetry.dart';
import '../../../../core/utils/shipping_utils.dart';
import '../../../../core/utils/log.dart';
import '../../../../core/utils/platform_utils.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/detail_contact_info_card.dart';
import '../../../../core/widgets/detail_note_card.dart';
import '../../../../core/widgets/detail_shipping_info_card.dart';
import '../../logic/approval_decision_service.dart';
import '../widgets/approval_detail_bottom_bar.dart';
import '../widgets/approval_header_card.dart';
import '../widgets/approval_payments_card.dart';
import '../widgets/approval_products_card.dart';
import '../../../profile/logic/profile_provider.dart';
import '../../logic/approval_inbox_provider.dart';

class ApprovalDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> orderData;

  const ApprovalDetailPage({super.key, required this.orderData});

  @override
  ConsumerState<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends ConsumerState<ApprovalDetailPage> {
  bool _isLoading = false;
  int _userId = 0;

  /// Pesan loading (mis. "Mendeteksi lokasi..." saat ambil GPS + reverse geocode).
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await StorageService.loadUserId();
    if (mounted && id != _userId) setState(() => _userId = id);
  }

  // ── Helpers ──────────────────────────────────────────────────────

  bool _isOrderShippingDifferent(Map<String, dynamic> order) {
    return isShippingDifferent(
      shipToName: order['ship_to_name'] as String? ?? '',
      shipToAddress: order['address_ship_to'] as String? ?? '',
      customerName: order['customer_name'] as String? ?? '',
      customerAddress: order['address'] as String? ?? '',
    );
  }

  // ── Confirmation dialog ───────────────────────────────────────────

  Future<void> _confirmAction(BuildContext context, bool isApprove) async {
    final actionName = isApprove ? 'Menyetujui' : 'Menolak';
    final actionColor = isApprove ? AppColors.success : AppColors.error;

    hapticTap();
    if (!context.mounted) return;
    final confirm = await showAdaptiveConfirm(
      context: context,
      title: 'Konfirmasi',
      content:
          'Apakah Anda yakin ingin $actionName pengajuan diskon pada Surat Pesanan ini?',
      confirmLabel: 'Ya, $actionName',
      isDestructive: !isApprove,
      confirmColor: actionColor,
    );

    if (confirm == true) {
      await _processApproval(isApprove);
    }
  }

  // ── Approval logic ────────────────────────────────────────────────

  Future<void> _processApproval(bool isApproved) async {
    final action = isApproved ? 'approve' : 'reject';
    final sw = Stopwatch()..start();
    AppTelemetry.event('approval_decision_started', data: {'action': action});

    // Capture ref-dependent values before any async gap.
    final inboxNotifier = ref.read(approvalInboxProvider.notifier);
    final profileFuture = ref.read(profileProvider.future);

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Mendeteksi lokasi...';
    });

    try {
      final location = await inboxNotifier.getCurrentAddressForApproval();
      if (location == null || !mounted) {
        sw.stop();
        AppTelemetry.error('approval_location_failed', data: {
          'action': action,
          'duration_ms': sw.elapsedMilliseconds,
        });
        if (mounted) {
          AppFeedback.show(
            context,
            message:
                'Gagal memproses. Mohon aktifkan GPS/Lokasi Anda untuk melakukan persetujuan.',
            type: AppFeedbackType.warning,
            floating: true,
            duration: const Duration(seconds: 4),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _loadingMessage = null);
      }

      final token = await StorageService.loadAccessToken();
      final userId = await StorageService.loadUserId();
      final profile = await profileFuture;
      final pendingDiscs = ApprovalDecisionService.collectPendingDiscounts(
        orderData: widget.orderData,
        myName: profile?.name ?? '',
        myUserId: userId,
      );
      final orderId = ApprovalDecisionService.resolveOrderId(widget.orderData);
      if (orderId <= 0) {
        throw Exception(
            'Order letter ID tidak valid untuk sinkronisasi status.');
      }

      if (pendingDiscs.isEmpty) {
        if (mounted) {
          AppFeedback.plain(
            context,
            'Tidak ada diskon yang perlu diproses.',
            floating: true,
          );
        }
        return;
      }

      final decision = await ApprovalDecisionService.processCascade(
        pendingDiscs: pendingDiscs,
        isApproved: isApproved,
        token: token,
        userId: userId,
        orderId: orderId,
        notifier: inboxNotifier,
        latitude: location.latitude,
        longitude: location.longitude,
        lokasiApproval: location.address,
      );

      if (!mounted) return;

      if (isApproved && !decision.headerRejected) {
        final order =
            widget.orderData['order_letter'] as Map<String, dynamic>? ?? {};
        final spNumber = order['no_sp']?.toString() ??
            order['order_letter_no']?.toString() ??
            '';
        try {
          await ApprovalDecisionService.triggerNextApprovalNotification(
            orderData: widget.orderData,
            spNumber: spNumber,
            token: token,
            senderName: profile?.name ?? 'Approver',
            currentUserId: userId,
          );
        } catch (e, st) {
          Log.warning('Notifikasi next approver gagal: $e',
              tag: 'ApprovalDetail');
          Log.error(e, st, reason: 'triggerNextApprovalNotification');
        }
      }

      unawaited(inboxNotifier.fetchInbox());
      if (!mounted) return;

      sw.stop();
      AppTelemetry.event('approval_decision_success', data: {
        'action': action,
        'processed_count': decision.processedCount,
        'header_approved': decision.headerApproved,
        'header_rejected': decision.headerRejected,
        'duration_ms': sw.elapsedMilliseconds,
      });

      if (decision.headerRejected) {
        AppFeedback.show(
          context,
          message: 'Diskon ditolak, Surat Pesanan dibatalkan.',
          type: AppFeedbackType.error,
          floating: true,
        );
      } else if (decision.headerApproved) {
        AppFeedback.show(
          context,
          message: 'Semua persetujuan selesai, Surat Pesanan Disetujui!',
          type: AppFeedbackType.success,
          floating: true,
        );
      } else {
        final int count = decision.processedCount;
        final String successMsg =
            'Persetujuan berhasil diproses! ($count item)';
        AppFeedback.show(
          context,
          message: successMsg,
          type: AppFeedbackType.success,
          floating: true,
        );
      }
      if (mounted) context.pop();
    } catch (e, st) {
      sw.stop();
      Log.error(e, st, reason: 'ApprovalDetail.processDecision');
      AppTelemetry.error('approval_decision_failed', data: {
        'action': action,
        'reason': e.toString(),
        'duration_ms': sw.elapsedMilliseconds,
      });
      if (!mounted) return;
      AppFeedback.show(
        context,
        message: 'Terjadi kesalahan: $e',
        type: AppFeedbackType.error,
        floating: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
        });
      }
    }
  }

  // ── Approval state check ──────────────────────────────────────────

  /// Determines the logged-in user's approval role for this order.
  /// Uses both `approver_id` (primary) and `approver_name` (fallback).
  ///
  /// Returns [_MyApprovalState.completed] if the SP header is already
  /// Rejected/Approved OR if any discount from any approver is Rejected,
  /// regardless of whether the current user's own row is still Pending.
  _MyApprovalState _resolveMyApprovalState(
    List<dynamic> details,
    int userId,
    String myName,
  ) {
    if (userId <= 0 && myName.trim().isEmpty) return _MyApprovalState.loading;

    // Check SP header status first
    final order =
        widget.orderData['order_letter'] as Map<String, dynamic>? ?? {};
    final headerEnum = OrderStatusX.fromRaw(
      order['status']?.toString() ?? '',
    );
    final bool headerTerminal = headerEnum == OrderStatus.rejected ||
        headerEnum == OrderStatus.approved;

    bool needsMyApproval = false;
    bool alreadyHandledByMe = false;
    bool isMyApproval = false;
    bool anyDiscountRejected = false;

    for (final detail in details) {
      final discounts = detail['order_letter_discount'] as List<dynamic>? ?? [];
      final discountMaps =
          discounts.map((d) => d as Map<String, dynamic>).toList();

      for (int i = 0; i < discountMaps.length; i++) {
        final disc = discountMaps[i];
        final approverId = disc['approver_id']?.toString() ?? '';
        final approverName = disc['approver_name'] as String? ?? '';
        final discEnum = OrderStatusX.fromDynamic(disc['approved']);

        if (discEnum == OrderStatus.rejected) {
          anyDiscountRejected = true;
        }

        final isMe = (userId > 0 && approverId == userId.toString()) ||
            (myName.isNotEmpty && NameMatcher.softMatch(approverName, myName));

        if (isMe) {
          isMyApproval = true;
          if (discEnum == OrderStatus.pending) {
            if (ApprovalDecisionService.arePriorApprovedByIndex(
              discountsInDetail: discountMaps,
              myIndex: i,
            )) {
              needsMyApproval = true;
            }
          } else {
            alreadyHandledByMe = true;
          }
        }
      }
    }

    // SP already terminated → no action possible
    if (headerTerminal || anyDiscountRejected) {
      if (isMyApproval) return _MyApprovalState.completed;
      return _MyApprovalState.viewer;
    }

    if (needsMyApproval) return _MyApprovalState.pendingAction;
    if (alreadyHandledByMe) return _MyApprovalState.completed;
    if (!isMyApproval) return _MyApprovalState.viewer;
    return _MyApprovalState.viewer;
  }

  // ── WhatsApp helper ───────────────────────────────────────────────

  Future<void> _openWhatsApp(String phone) async {
    try {
      final opened = await ContactActions.openWhatsAppChat(phone);
      if (!opened && mounted) {
        AppFeedback.plain(context, 'Tidak dapat membuka WhatsApp');
      }
    } catch (e, st) {
      Log.error(e, st, reason: 'ApprovalDetail.openWhatsApp');
      if (mounted) {
        AppFeedback.plain(context, 'Terjadi kesalahan saat membuka WhatsApp');
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final order =
        widget.orderData['order_letter'] as Map<String, dynamic>? ?? {};
    final details =
        widget.orderData['order_letter_details'] as List<dynamic>? ?? [];
    final payments =
        widget.orderData['order_letter_payments'] as List<dynamic>? ?? [];
    final shippingDiffers = _isOrderShippingDifferent(order);

    final myName =
        ref.watch(profileProvider.select((v) => v.valueOrNull?.name ?? ''));
    final approvalState = _resolveMyApprovalState(details, _userId, myName);
    final barState = switch (approvalState) {
      _MyApprovalState.pendingAction => ApprovalBarState.pendingAction,
      _MyApprovalState.completed => ApprovalBarState.completed,
      _MyApprovalState.viewer => ApprovalBarState.viewer,
      _MyApprovalState.loading => ApprovalBarState.loading,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Persetujuan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ApprovalHeaderCard(
                  order: order,
                  orderData: widget.orderData,
                ),
                const SizedBox(height: 12),
                _buildCustomerCard(
                  context,
                  order,
                  isShippingDifferent: shippingDiffers,
                ),
                if (shippingDiffers) ...[
                  const SizedBox(height: 12),
                  _buildShippingCard(order),
                ],
                const SizedBox(height: 12),
                if (_buildNoteCard(order) case final note?) ...[
                  note,
                  const SizedBox(height: 12),
                ],
                ApprovalProductsCard(details: details, order: order),
                const SizedBox(height: 12),
                ApprovalPaymentsCard(payments: payments),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_isLoading,
              child: LoadingOverlay(
                title: _loadingMessage ?? 'Memproses Persetujuan...',
                subtitle: _loadingMessage != null
                    ? 'Mengambil koordinat dan alamat'
                    : 'Harap tunggu sebentar',
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ApprovalDetailBottomBar(
        state: barState,
        isLoading: _isLoading,
        onReject: () => _confirmAction(context, false),
        onApprove: () => _confirmAction(context, true),
      ),
    );
  }

  // ── Kartu 2: Informasi Pelanggan ──────────────────────────────────

  Widget _buildCustomerCard(
    BuildContext context,
    Map<String, dynamic> order, {
    bool isShippingDifferent = false,
  }) {
    final name = order['customer_name'] as String? ?? 'Pelanggan';
    final address = order['address'] as String? ?? '';
    final phone =
        order['phone'] as String? ?? order['customer_phone'] as String? ?? '';
    final email =
        order['email'] as String? ?? order['customer_email'] as String? ?? '';
    final cardTitle = isShippingDifferent
        ? 'Informasi Pelanggan'
        : 'Informasi Pelanggan & Pengiriman';
    return DetailContactInfoCard(
      title: cardTitle,
      name: name,
      phone: phone,
      email: email,
      address: address,
      onCopyPhone: () => ContactActions.copyText(
        context,
        text: phone,
        successMessage: 'Nomor HP disalin',
        duration: const Duration(seconds: 1),
      ),
      onOpenWhatsApp: () => _openWhatsApp(phone),
    );
  }

  // ── Kartu 2b: Informasi Pengiriman ───────────────────────────────

  Widget _buildShippingCard(Map<String, dynamic> order) {
    final name = (order['ship_to_name'] as String? ?? '').trim();
    final addr = (order['address_ship_to'] as String? ?? '').trim();
    return DetailShippingInfoCard(name: name, address: addr);
  }

  // ── Kartu 2c: Catatan Pesanan ─────────────────────────────────────

  Widget? _buildNoteCard(Map<String, dynamic> order) {
    final note = order['note'] as String? ??
        order['catatan'] as String? ??
        order['notes'] as String? ??
        '';
    if (note.trim().isEmpty) return null;

    return DetailNoteCard(
      note: note.trim(),
      borderRadius: 12,
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      iconColor: AppColors.warning,
      titleColor: AppColors.warning,
    );
  }
}

/// Three possible states for the logged-in user on this approval:
/// - [pendingAction]: user is an approver with "Pending" status → show action buttons
/// - [completed]: user already approved/rejected → show green completed banner
/// - [viewer]: user is not an approver for this order → show waiting banner or hide
/// - [loading]: data not ready yet → show nothing
enum _MyApprovalState { pendingAction, completed, viewer, loading }
